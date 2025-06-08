# encoding:utf-8
# Kernel32 模块实现
module Win32API_Impl
  module Kernel32
  end
  module Kernel32_Helper
  end
end

module Win32API_Impl::Kernel32_Helper
  def self.read_ini(section, parameter, default, file_location)
    current_section = nil
    File.open(file_location, "r") do |file|
      file.each_line do |line|
        line = line.strip
        if line.length > 0 && line[0,1] == "[" && line[-1,1] == "]"
          current_section = line[1..-2]
        elsif current_section == section
          key_value = line.split("=", 2)
          key = key_value[0].strip
          value = key_value[1].strip if key_value.size > 1
          return value.to_i if key == parameter
        end
      end
    end
    default
  end

  def self.read_ini_string(section, parameter, default, file_location, buffer, buffer_size)
    current_section = nil
    result = default.to_s

    if File.exist?(file_location)
      File.open(file_location, "r") do |file|
        file.each_line do |line|
          line = line.strip
          if line.length > 0 && line[0,1] == "[" && line[-1,1] == "]"
            current_section = line[1..-2]
          elsif current_section == section
            key_value = line.split("=", 2)
            if key_value.size > 1
              key = key_value[0].strip
              value = key_value[1].strip
              if key == parameter
                result = value.to_s
                break
              end
            end
          end
        end
      end
    end

    # 写入结果到buffer
    bytes_to_copy = [result.size, buffer_size - 1].min
    bytes_to_copy.times do |i|
      char_byte = RUBY_VERSION.split('.')[0].to_i >= 2 ? result[i].ord : result[i]
      buffer.setbyte(i, char_byte)
    end
    buffer.setbyte(bytes_to_copy, 0) # 确保字符串以null结尾

    bytes_to_copy
  end

  def self.write_ini(section, parameter, value, file_location)
    data = {}
    if File.exist?(file_location)
      File.open(file_location, 'r') do |file|
        current_section = nil
        file.each_line do |line|
          line = line.strip
          if line.length > 0 && line[0,1] == "[" && line[-1,1] == "]"
            current_section = line[1..-2]
            data[current_section] = {}
          elsif current_section
            key_value = line.split('=', 2)
            if key_value.size > 1
              key = key_value[0].strip
              val = key_value[1].strip
              data[current_section][key] = val
            end
          end
        end
      end
    end

    data[section] ||= {}
    value_str = value.to_s
    data[section][parameter] = value_str unless value.nil? || value_str.strip.empty?

    File.open(file_location, 'w') do |file|
      data.each do |sect, parameters|
        file.puts "[#{sect}]"
        parameters.each do |key, val|
          val_str = val.to_s
          file.puts "#{key}=#{val}" unless val.nil? || val_str.strip.empty?
        end
        file.puts
      end
    end
  end
end

# Kernel32 具体类实现
class Win32API_Impl::Kernel32::GetPrivateProfileInt
  def call(args)
    section, parameter, default, file_location = args
    Win32API_Impl::Kernel32_Helper::read_ini(section, parameter, default, file_location)
  end
end

class Win32API_Impl::Kernel32::GetPrivateProfileStringA
  def call(args)
    section, parameter, default, buffer, buffer_size, file_location = args
    Win32API_Impl::Kernel32_Helper::read_ini_string(section, parameter, default, file_location, buffer, buffer_size)
  end
end

class Win32API_Impl::Kernel32::GetPrivateProfileStringW
  def call(args)
    section, parameter, default, buffer, buffer_size, file_location = args
    # W版本需要处理Unicode字符串，但基本操作相同
    # 这里简化处理，实际应用中可能需要更复杂的Unicode转换
    Win32API_Impl::Kernel32_Helper::read_ini_string(section, parameter, default, file_location, buffer, buffer_size)
  end
end

class Win32API_Impl::Kernel32::WritePrivateProfileStringA
  def call(args)
    section, parameter, value, file_location = args
    Win32API_Impl::Kernel32_Helper::write_ini(section, parameter, value, file_location)
  end
end

class Win32API_Impl::Kernel32::WritePrivateProfileStringW
  def call(args)
    section, parameter, value, file_location = args
    # W版本需要处理Unicode字符串，但基本操作相同
    # 这里简化处理，实际应用中可能需要更复杂的Unicode转换
    Win32API_Impl::Kernel32_Helper::write_ini(section, parameter, value, file_location)
  end
end

class Win32API_Impl::Kernel32::RtlZeroMemory
  def call(args)
    dest, length = args
    # 把前 length 字节全部写 0
    length.times { |i| dest.setbyte(i, 0) }
    nil
  end
end

class Win32API_Impl::Kernel32::MultiByteToWideChar
  def call(args)
    code_page, flags, mb_str, mb_len, wide_str, wide_len = args

    return 0 if mb_str.nil?

    # 确定源字符串长度
    if mb_len == -1
      mb_len = 0
      begin
        while mb_len < 65536 && mb_str.getbyte(mb_len) != 0  # 添加安全边界
          mb_len += 1
        end
        # 包含null终止符
        mb_len += 1 if mb_len < 65536
      rescue
        # 如果访问越界，使用当前长度
      end
    end

    # 获取源字符串 (不包括null终止符用于转换)
    actual_chars = mb_len > 0 ? mb_len - 1 : 0
    source_bytes = []
    actual_chars.times { |i| source_bytes << mb_str.getbyte(i) }
    source_str = source_bytes.pack('C*')

    # Ruby 1.8.7 没有编码支持，简单地把字节复制到输出缓冲区
    # 每个字符映射为一个宽字符(两个字节)，加上null终止符
    
    # 如果wide_str为nil或wide_len为0，返回所需的字符数(包括null终止符)
    if wide_str.nil? || wide_len == 0
      return source_str.size + 1  # 加上null终止符
    end

    # 写入结果到输出缓冲区
    chars_to_write = [source_str.size, wide_len - 1].min  # 为null终止符保留空间
    chars_to_write.times do |i|
      char_byte = RUBY_VERSION.split('.')[0].to_i >= 2 ? source_str[i].ord : source_str[i]
      wide_str.setbyte(i * 2, char_byte)
      wide_str.setbyte(i * 2 + 1, 0)  # 高字节为0
    end
    
    # 添加null终止符
    if chars_to_write < wide_len
      wide_str.setbyte(chars_to_write * 2, 0)
      wide_str.setbyte(chars_to_write * 2 + 1, 0)
    end

    # 返回写入的字符数(包括null终止符)
    return chars_to_write + 1
  rescue
    return 0
  end
end

class Win32API_Impl::Kernel32::WideCharToMultiByte
  def call(args)
    code_page, flags, wide_str, wide_len, mb_str, mb_len, default_char, used_default_char = args

    return 0 if wide_str.nil?

    # 确定源字符串长度（以字符为单位，每个字符2字节）
    if wide_len == -1
      wide_len = 0
      begin
        # 对于UTF-16，需要检查两个字节都为0才算结束
        while wide_len < 32768
          byte1 = wide_str.getbyte(wide_len * 2) || 0
          byte2 = wide_str.getbyte(wide_len * 2 + 1) || 0
          break if byte1 == 0 && byte2 == 0
          wide_len += 1
        end
      rescue
        # 如果访问越界，使用当前长度
      end
    end

    # Ruby 1.8.7 没有编码支持，简单地从UTF-16LE中提取第一个字节
    # 排除null终止符
    actual_chars = wide_len > 0 ? wide_len - 1 : 0
    result_bytes = []
    actual_chars.times do |i|
      result_bytes << wide_str.getbyte(i * 2)
    end
    
    result_str = result_bytes.pack('C*')

    # 如果mb_str为nil或mb_len为0，返回所需的缓冲区大小(包括null终止符)
    if mb_str.nil? || mb_len == 0
      return result_str.size + 1
    end

    # 写入结果到输出缓冲区，为null终止符保留空间
    bytes_to_copy = [result_str.size, mb_len - 1].min
    bytes_to_copy.times do |i|
      char_byte = RUBY_VERSION.split('.')[0].to_i >= 2 ? result_str[i].ord : result_str[i]
      mb_str.setbyte(i, char_byte)
    end
    
    # 添加null终止符
    if bytes_to_copy < mb_len
      mb_str.setbyte(bytes_to_copy, 0)
    end

    # 返回写入的字节数(包括null终止符)
    return bytes_to_copy + 1
  rescue
    return 0
  end
end