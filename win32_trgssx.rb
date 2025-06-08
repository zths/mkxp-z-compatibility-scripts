# encoding:utf-8
# TRGSSX.dll 模拟实现
module Win32API_Impl
  module TRGSSX
  end
  module TRGSSX_Helper
    # 当前的插值模式和平滑模式
    @@interpolation_mode = 0  # IM_DEFAULT
    @@smoothing_mode = 0      # SM_DEFAULT

    def self.get_interpolation_mode
      @@interpolation_mode
    end

    def self.set_interpolation_mode(mode)
      @@interpolation_mode = mode
    end

    def self.get_smoothing_mode
      @@smoothing_mode
    end

    def self.set_smoothing_mode(mode)
      @@smoothing_mode = mode
    end

    # 从bitmap info中提取信息
    def self.unpack_bitmap_info(info_ptr)
      return nil if info_ptr.nil?
      
      # Ruby 1.8.7 兼容性处理
      begin
        info_data = info_ptr.unpack('l!3')
      rescue
        # 回退到普通 long 格式
        info_data = info_ptr.unpack('lll')
      end
      
      # Ruby 1.8.7 不支持新的 Hash 语法，统一使用老式语法
      {
        :object_id => info_data[0],
        :width => info_data[1],
        :height => info_data[2]
      }
    end

    # 获取Bitmap对象
    def self.get_bitmap_from_info(info_ptr)
      info = unpack_bitmap_info(info_ptr)
      return nil if info.nil?
      
      # 通过object_id获取Bitmap对象
      ObjectSpace._id2ref(info[:object_id]) rescue nil
    end

    # 颜色转换
    def self.argb_to_color(argb)
      alpha = (argb >> 24) & 0xFF
      red   = (argb >> 16) & 0xFF
      green = (argb >> 8) & 0xFF
      blue  = argb & 0xFF
      Color.new(red, green, blue, alpha)
    end

    # 字体样式解析
    def self.parse_font_flags(flags)
      # Ruby 1.8.7 兼容性处理，统一使用老式Hash语法
      {
        :bold => (flags & 0x0001) != 0,      # FS_BOLD
        :italic => (flags & 0x0002) != 0,    # FS_ITALIC
        :underline => (flags & 0x0004) != 0, # FS_UNDERLINE
        :strikeout => (flags & 0x0008) != 0, # FS_STRIKEOUT
        :shadow => (flags & 0x0010) != 0,    # FS_SHADOW
        :frame => (flags & 0x0020) != 0      # FS_FRAME
      }
    end

    # 模拟基本绘图操作
    def self.simple_blt(dest_bitmap, dx, dy, dw, dh, src_bitmap, sx, sy, sw = nil, sh = nil, opacity = 255)
      return -1 if dest_bitmap.nil? || src_bitmap.nil?
      return -1 if dest_bitmap.disposed? || src_bitmap.disposed?

      sw ||= dw
      sh ||= dh

      src_rect = Rect.new(sx, sy, sw, sh)
      
      if sw == dw && sh == dh
        # 直接复制
        dest_bitmap.blt(dx, dy, src_bitmap, src_rect, opacity)
      else
        # 需要缩放，使用stretch_blt
        dest_rect = Rect.new(dx, dy, dw, dh)
        dest_bitmap.stretch_blt(dest_rect, src_bitmap, src_rect, opacity)
      end
      
      return 0
    end
  end
end

# TRGSSX 具体类实现

# DllGetVersion - 获取DLL版本
class Win32API_Impl::TRGSSX::DllGetVersion
  def call(args)
    return 100  # 模拟版本1.00
  end
end

# GetInterpolationMode - 获取插值模式
class Win32API_Impl::TRGSSX::GetInterpolationMode
  def call(args)
    Win32API_Impl::TRGSSX_Helper.get_interpolation_mode
  end
end

# SetInterpolationMode - 设置插值模式
class Win32API_Impl::TRGSSX::SetInterpolationMode
  def call(args)
    mode = args[0] || 0
    Win32API_Impl::TRGSSX_Helper.set_interpolation_mode(mode)
    nil
  end
end

# GetSmoothingMode - 获取平滑模式
class Win32API_Impl::TRGSSX::GetSmoothingMode
  def call(args)
    Win32API_Impl::TRGSSX_Helper.get_smoothing_mode
  end
end

# SetSmoothingMode - 设置平滑模式
class Win32API_Impl::TRGSSX::SetSmoothingMode
  def call(args)
    mode = args[0] || 0
    Win32API_Impl::TRGSSX_Helper.set_smoothing_mode(mode)
    nil
  end
end

# RopBlt - 栅格操作位块传输
class Win32API_Impl::TRGSSX::RopBlt
  def call(args)
    dest_info, dx, dy, dw, dh, src_info, sx, sy, rop = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    src_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(src_info)
    
    return -1 if dest_bitmap.nil? || src_bitmap.nil?
    
    # 简化实现：大部分ROP操作都当作普通blt处理
    case rop
    when 0x00CC0020  # SRCCOPY
      return Win32API_Impl::TRGSSX_Helper.simple_blt(dest_bitmap, dx, dy, dw, dh, src_bitmap, sx, sy, dw, dh)
    else
      # 其他ROP操作也当作普通复制处理
      return Win32API_Impl::TRGSSX_Helper.simple_blt(dest_bitmap, dx, dy, dw, dh, src_bitmap, sx, sy, dw, dh)
    end
  end
end

# ClipBlt - 裁剪位块传输
class Win32API_Impl::TRGSSX::ClipBlt
  def call(args)
    dest_info, dx, dy, dw, dh, src_info, sx, sy, hrgn = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    src_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(src_info)
    
    return -1 if dest_bitmap.nil? || src_bitmap.nil?
    
    # 简化实现：忽略裁剪区域，直接进行blt操作
    return Win32API_Impl::TRGSSX_Helper.simple_blt(dest_bitmap, dx, dy, dw, dh, src_bitmap, sx, sy, dw, dh)
  end
end

# BlendBlt - 混合位块传输
class Win32API_Impl::TRGSSX::BlendBlt
  def call(args)
    dest_info, dx, dy, dw, dh, src_info, sx, sy, blend = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    src_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(src_info)
    
    return -1 if dest_bitmap.nil? || src_bitmap.nil?
    
    # 简化实现：所有混合模式都当作普通blt处理
    return Win32API_Impl::TRGSSX_Helper.simple_blt(dest_bitmap, dx, dy, dw, dh, src_bitmap, sx, sy, dw, dh)
  end
end

# StretchBltR - 高质量拉伸位块传输
class Win32API_Impl::TRGSSX::StretchBltR
  def call(args)
    dest_info, dx, dy, dw, dh, src_info, sx, sy, sw, sh, opacity = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    src_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(src_info)
    
    return -1 if dest_bitmap.nil? || src_bitmap.nil?
    
    return Win32API_Impl::TRGSSX_Helper.simple_blt(dest_bitmap, dx, dy, dw, dh, src_bitmap, sx, sy, sw, sh, opacity || 255)
  end
end

# SkewBltR - 高质量倾斜位块传输
class Win32API_Impl::TRGSSX::SkewBltR
  def call(args)
    dest_info, dx, dy, src_info, sx, sy, sw, sh, slope, opacity = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    src_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(src_info)
    
    return -1 if dest_bitmap.nil? || src_bitmap.nil?
    
    # 简化实现：忽略倾斜，直接进行普通blt
    return Win32API_Impl::TRGSSX_Helper.simple_blt(dest_bitmap, dx, dy, sw, sh, src_bitmap, sx, sy, sw, sh, opacity || 255)
  end
end

# DrawPolygon - 绘制多边形
class Win32API_Impl::TRGSSX::DrawPolygon
  def call(args)
    dest_info, pts, n, color, width = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    return -1 if dest_bitmap.nil?
    
    # 简化实现：绘制多边形边框
    begin
      # 解析颜色
      draw_color = Win32API_Impl::TRGSSX_Helper.argb_to_color(color)
      
      # 绘制线条（简化版本）
      if n >= 2
        points_data = pts.unpack("l#{n * 2}")
        (0...n).each do |i|
          x1 = points_data[i * 2]
          y1 = points_data[i * 2 + 1]
          x2 = points_data[((i + 1) % n) * 2]
          y2 = points_data[((i + 1) % n) * 2 + 1]
          
          # 简单的线条绘制
          dest_bitmap.fill_rect(x1, y1, [1, width || 1].max, [1, width || 1].max, draw_color)
        end
      end
      
      return 0
    rescue
      return -1
    end
  end
end

# FillPolygon - 填充多边形
class Win32API_Impl::TRGSSX::FillPolygon
  def call(args)
    dest_info, pts, n, st_color, ed_color, fm = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    return -1 if dest_bitmap.nil?
    
    # 简化实现：使用起始颜色填充一个矩形区域
    begin
      fill_color = Win32API_Impl::TRGSSX_Helper.argb_to_color(st_color)
      
      if n >= 3
        points_data = pts.unpack("l#{n * 2}")
        min_x = min_y = 9999
        max_x = max_y = -9999
        
        n.times do |i|
          x = points_data[i * 2]
          y = points_data[i * 2 + 1]
          min_x = [min_x, x].min
          min_y = [min_y, y].min
          max_x = [max_x, x].max
          max_y = [max_y, y].max
        end
        
        # 填充边界矩形
        w = max_x - min_x + 1
        h = max_y - min_y + 1
        dest_bitmap.fill_rect(min_x, min_y, w, h, fill_color) if w > 0 && h > 0
      end
      
      return 0
    rescue
      return -1
    end
  end
end

# DrawRegularPolygon - 绘制正多边形
class Win32API_Impl::TRGSSX::DrawRegularPolygon
  def call(args)
    dest_info, dx, dy, r, n, color, width = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    return -1 if dest_bitmap.nil?
    
    # 简化实现：绘制圆形代替正多边形
    begin
      draw_color = Win32API_Impl::TRGSSX_Helper.argb_to_color(color)
      
      # 绘制一个圆形的边框
      (-r..r).each do |x|
        (-r..r).each do |y|
          distance = Math.sqrt(x*x + y*y)
          if distance >= r - (width || 1) && distance <= r
            px = dx + x
            py = dy + y
            dest_bitmap.set_pixel(px, py, draw_color) if px >= 0 && py >= 0 && px < dest_bitmap.width && py < dest_bitmap.height
          end
        end
      end
      
      return 0
    rescue
      return -1
    end
  end
end

# FillRegularPolygon - 填充正多边形
class Win32API_Impl::TRGSSX::FillRegularPolygon
  def call(args)
    dest_info, dx, dy, r, n, st_color, ed_color, fm = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    return -1 if dest_bitmap.nil?
    
    # 简化实现：绘制填充圆形
    begin
      fill_color = Win32API_Impl::TRGSSX_Helper.argb_to_color(st_color)
      
      # 填充圆形
      (-r..r).each do |x|
        (-r..r).each do |y|
          if x*x + y*y <= r*r
            px = dx + x
            py = dy + y
            dest_bitmap.set_pixel(px, py, fill_color) if px >= 0 && py >= 0 && px < dest_bitmap.width && py < dest_bitmap.height
          end
        end
      end
      
      return 0
    rescue
      return -1
    end
  end
end

# DrawSpoke - 绘制辐射线
class Win32API_Impl::TRGSSX::DrawSpoke
  def call(args)
    dest_info, dx, dy, r, n, color, width = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    return -1 if dest_bitmap.nil?
    
    # 简化实现：绘制十字形
    begin
      draw_color = Win32API_Impl::TRGSSX_Helper.argb_to_color(color)
      
      # 绘制水平线
      dest_bitmap.fill_rect(dx - r, dy, r * 2, width || 1, draw_color)
      # 绘制垂直线
      dest_bitmap.fill_rect(dx, dy - r, width || 1, r * 2, draw_color)
      
      return 0
    rescue
      return -1
    end
  end
end

# DrawTextNAA - 绘制文本（无抗锯齿）
class Win32API_Impl::TRGSSX::DrawTextNAA
  def call(args)
    dest_info, dx, dy, dw, dh, text, fontname, fontsize, color, align, flags = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    return -1 if dest_bitmap.nil?
    
    # 简化实现：使用普通draw_text
    begin
      # 解析颜色（简化，只取RGB部分）
      # Ruby 1.8.7 兼容性处理
      begin
        text_colors = color.unpack('l!4')
      rescue
        text_colors = color.unpack('llll')
      end
      main_color_argb = text_colors[0]
      
      r = (main_color_argb >> 16) & 0xFF
      g = (main_color_argb >> 8) & 0xFF
      b = main_color_argb & 0xFF
      
      # 备份原字体设置
      old_name = dest_bitmap.font.name
      old_size = dest_bitmap.font.size
      old_color = dest_bitmap.font.color
      
      # 设置字体
      dest_bitmap.font.name = fontname if fontname
      dest_bitmap.font.size = fontsize if fontsize
      dest_bitmap.font.color = Color.new(r, g, b)
      
      # 绘制文本
      rect = Rect.new(dx, dy, dw, dh)
      dest_bitmap.draw_text(rect, text.to_s, align || 0)
      
      # 恢复原字体设置
      dest_bitmap.font.name = old_name
      dest_bitmap.font.size = old_size
      dest_bitmap.font.color = old_color
      
      return 0
    rescue
      return -1
    end
  end
end

# DrawTextFastA - 快速绘制文本
class Win32API_Impl::TRGSSX::DrawTextFastA
  def call(args)
    # 与DrawTextNAA相同的实现
    dest_info, dx, dy, dw, dh, text, fontname, fontsize, color, align, flags = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    return -1 if dest_bitmap.nil?
    
    begin
      # Ruby 1.8.7 兼容性处理
      begin
        text_colors = color.unpack('l!4')
      rescue
        text_colors = color.unpack('llll')
      end
      main_color_argb = text_colors[0]
      
      r = (main_color_argb >> 16) & 0xFF
      g = (main_color_argb >> 8) & 0xFF
      b = main_color_argb & 0xFF
      
      old_name = dest_bitmap.font.name
      old_size = dest_bitmap.font.size
      old_color = dest_bitmap.font.color
      
      dest_bitmap.font.name = fontname if fontname
      dest_bitmap.font.size = fontsize if fontsize
      dest_bitmap.font.color = Color.new(r, g, b)
      
      rect = Rect.new(dx, dy, dw, dh)
      dest_bitmap.draw_text(rect, text.to_s, align || 0)
      
      dest_bitmap.font.name = old_name
      dest_bitmap.font.size = old_size
      dest_bitmap.font.color = old_color
      
      return 0
    rescue
      return -1
    end
  end
end

# GetTextSizeNAA - 获取文本大小（无抗锯齿）
class Win32API_Impl::TRGSSX::GetTextSizeNAA
  def call(args)
    dest_info, text, fontname, fontsize, flags, size = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    return -1 if dest_bitmap.nil?
    
    begin
      old_name = dest_bitmap.font.name
      old_size = dest_bitmap.font.size
      
      dest_bitmap.font.name = fontname if fontname
      dest_bitmap.font.size = fontsize if fontsize
      
      text_size = dest_bitmap.text_size(text.to_s)
      
      dest_bitmap.font.name = old_name
      dest_bitmap.font.size = old_size
      
      # 将大小写入输出缓冲区
      # Ruby 1.8.7 兼容性处理
      begin
        size_data = [text_size.width, text_size.height].pack('l!2')
      rescue
        size_data = [text_size.width, text_size.height].pack('ll')
      end
      
      # Ruby 1.8.7 可能没有 replace 方法
      if size.respond_to?(:replace)
        size.replace(size_data)
      else
        # 手动替换字节 - Ruby 1.8.7 兼容
        if size_data.respond_to?(:each_byte)
          i = 0
          size_data.each_byte do |byte|
            size.setbyte(i, byte) if size.respond_to?(:setbyte)
            i += 1
          end
        else
          # 更老版本的 Ruby 兼容
          (0...size_data.length).each do |i|
            size.setbyte(i, size_data[i]) if size.respond_to?(:setbyte)
          end
        end
      end
      
      return 0
    rescue
      return -1
    end
  end
end

# GetTextSizeFastA - 快速获取文本大小
class Win32API_Impl::TRGSSX::GetTextSizeFastA
  def call(args)
    # 与GetTextSizeNAA相同的实现
    dest_info, text, fontname, fontsize, flags, size = args
    
    dest_bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(dest_info)
    return -1 if dest_bitmap.nil?
    
    begin
      old_name = dest_bitmap.font.name
      old_size = dest_bitmap.font.size
      
      dest_bitmap.font.name = fontname if fontname
      dest_bitmap.font.size = fontsize if fontsize
      
      text_size = dest_bitmap.text_size(text.to_s)
      
      dest_bitmap.font.name = old_name
      dest_bitmap.font.size = old_size
      
      # Ruby 1.8.7 兼容性处理
      begin
        size_data = [text_size.width, text_size.height].pack('l!2')
      rescue
        size_data = [text_size.width, text_size.height].pack('ll')
      end
      
      # Ruby 1.8.7 可能没有 replace 方法
      if size.respond_to?(:replace)
        size.replace(size_data)
      else
        # 手动替换字节 - Ruby 1.8.7 兼容
        if size_data.respond_to?(:each_byte)
          i = 0
          size_data.each_byte do |byte|
            size.setbyte(i, byte) if size.respond_to?(:setbyte)
            i += 1
          end
        else
          # 更老版本的 Ruby 兼容
          (0...size_data.length).each do |i|
            size.setbyte(i, size_data[i]) if size.respond_to?(:setbyte)
          end
        end
      end
      
      return 0
    rescue
      return -1
    end
  end
end

# SaveToBitmapA - 保存为位图文件
class Win32API_Impl::TRGSSX::SaveToBitmapA
  def call(args)
    filename, info = args
    
    bitmap = Win32API_Impl::TRGSSX_Helper.get_bitmap_from_info(info)
    return -1 if bitmap.nil?
    
    # 简化实现：输出调试信息
    begin
      puts "[TRGSSX模拟] 保存位图到: #{filename}"
      return 0
    rescue
      return -1
    end
  end
end 