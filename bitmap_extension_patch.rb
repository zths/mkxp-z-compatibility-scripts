# encoding:utf-8
# BitmapExtension 补丁文件
# 为 KGC_BitmapExtension 脚本提供必要的 Win32API 支持
# 该补丁文件应在 BitmapExtension 脚本之前加载
# 支持 Ruby 1.8.7、1.9.3、2.x、3.x 系列

# Ruby 版本兼容性检查
module RubyVersionCompat
  MAJOR_VERSION = RUBY_VERSION.split('.')[0].to_i
  MINOR_VERSION = RUBY_VERSION.split('.')[1].to_i
  
  def self.ruby_18?
    MAJOR_VERSION == 1 && MINOR_VERSION == 8
  end
  
  def self.ruby_19?
    MAJOR_VERSION == 1 && MINOR_VERSION == 9
  end
  
  def self.ruby_2_plus?
    MAJOR_VERSION >= 2
  end
  
  def self.ruby_3_plus?
    MAJOR_VERSION >= 3
  end
  
  puts "[BitmapExtension补丁] Ruby版本: #{RUBY_VERSION} (检测为: #{
    if ruby_18?
      "1.8系列"
    elsif ruby_19?
      "1.9系列"
    elsif ruby_3_plus?
      "3.x系列"
    elsif ruby_2_plus?
      "2.x系列"
    else
      "未知版本"
    end
  })"
end

# 确保基础模块存在
unless defined?(Win32API_Impl)
  module Win32API_Impl
  end
end

# 包含 GDI32 支持
unless defined?(Win32API_Impl::Gdi32)
  load_relative_if_exists = lambda do |filename|
    begin
      # 尝试加载相对路径的文件
      if File.exist?(filename)
        load filename
      elsif File.exist?(File.join(File.dirname(__FILE__), filename))
        load File.join(File.dirname(__FILE__), filename)
      end
    rescue => e
      puts "[BitmapExtension补丁] 警告: 无法加载 #{filename}: #{e.message}"
    end
  end

  # 加载 GDI32 实现
  load_relative_if_exists.call('win32_gdi32.rb')
  
  # 如果加载失败，内联基本实现
  unless defined?(Win32API_Impl::Gdi32)
    module Win32API_Impl
      module Gdi32
      end
    end
    
    # 简化的 GDI32 实现
    class Win32API_Impl::Gdi32::DeleteObject
      def call(args)
        1  # 总是返回成功
      end
    end

    class Win32API_Impl::Gdi32::CreateRectRgn
      def call(args)
        rand(1000) + 1  # 返回随机句柄
      end
    end

    class Win32API_Impl::Gdi32::CreateRectRgnIndirect
      def call(args)
        rand(1000) + 1
      end
    end

    class Win32API_Impl::Gdi32::CreateRoundRectRgn
      def call(args)
        rand(1000) + 1
      end
    end

    class Win32API_Impl::Gdi32::CreateEllipticRgn
      def call(args)
        rand(1000) + 1
      end
    end

    class Win32API_Impl::Gdi32::CreateEllipticRgnIndirect
      def call(args)
        rand(1000) + 1
      end
    end

    class Win32API_Impl::Gdi32::CreatePolygonRgn
      def call(args)
        rand(1000) + 1
      end
    end

    class Win32API_Impl::Gdi32::CreatePolyPolygonRgn
      def call(args)
        rand(1000) + 1
      end
    end

    class Win32API_Impl::Gdi32::CombineRgn
      def call(args)
        1  # 简单区域
      end
    end
  end
end

# 包含 TRGSSX 支持
unless defined?(Win32API_Impl::TRGSSX)
  load_relative_if_exists.call('win32_trgssx.rb')
  
  # 如果加载失败，内联基本实现
  unless defined?(Win32API_Impl::TRGSSX)
    module Win32API_Impl
      module TRGSSX
      end
    end
    
    # 简化的 TRGSSX 实现
    class Win32API_Impl::TRGSSX::DllGetVersion
      def call(args)
        100  # 版本 1.00
      end
    end

    # 模式设置 - 使用类实例变量避免 Ruby 版本问题
    class << Win32API_Impl::TRGSSX
      attr_accessor :interpolation_mode, :smoothing_mode
    end
    Win32API_Impl::TRGSSX.interpolation_mode = 0
    Win32API_Impl::TRGSSX.smoothing_mode = 0

    class Win32API_Impl::TRGSSX::GetInterpolationMode
      def call(args)
        Win32API_Impl::TRGSSX.interpolation_mode
      end
    end

    class Win32API_Impl::TRGSSX::SetInterpolationMode
      def call(args)
        Win32API_Impl::TRGSSX.interpolation_mode = args[0] || 0
        nil
      end
    end

    class Win32API_Impl::TRGSSX::GetSmoothingMode
      def call(args)
        Win32API_Impl::TRGSSX.smoothing_mode
      end
    end

    class Win32API_Impl::TRGSSX::SetSmoothingMode
      def call(args)
        Win32API_Impl::TRGSSX.smoothing_mode = args[0] || 0
        nil
      end
    end

    # 获取Bitmap对象的帮助方法
    class << Win32API_Impl::TRGSSX
      def get_bitmap_from_info(info_ptr)
        return nil if info_ptr.nil?
        begin
          info_data = info_ptr.unpack('l!3')
          object_id = info_data[0]
          ObjectSpace._id2ref(object_id)
        rescue
          nil
        end
      end
    end

    # 位图操作
    class Win32API_Impl::TRGSSX::RopBlt
      def call(args)
        dest_info, dx, dy, dw, dh, src_info, sx, sy, rop = args
        
        dest_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(dest_info)
        src_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(src_info)
        
        return -1 if dest_bitmap.nil? || src_bitmap.nil?
        return -1 if dest_bitmap.disposed? || src_bitmap.disposed?
        
        begin
          src_rect = Rect.new(sx, sy, dw, dh)
          dest_bitmap.blt(dx, dy, src_bitmap, src_rect)
          return 0
        rescue
          return -1
        end
      end
    end

    class Win32API_Impl::TRGSSX::ClipBlt
      def call(args)
        dest_info, dx, dy, dw, dh, src_info, sx, sy, hrgn = args
        
        dest_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(dest_info)
        src_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(src_info)
        
        return -1 if dest_bitmap.nil? || src_bitmap.nil?
        return -1 if dest_bitmap.disposed? || src_bitmap.disposed?
        
        begin
          src_rect = Rect.new(sx, sy, dw, dh)
          dest_bitmap.blt(dx, dy, src_bitmap, src_rect)
          return 0
        rescue
          return -1
        end
      end
    end

    class Win32API_Impl::TRGSSX::BlendBlt
      def call(args)
        dest_info, dx, dy, dw, dh, src_info, sx, sy, blend = args
        
        dest_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(dest_info)
        src_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(src_info)
        
        return -1 if dest_bitmap.nil? || src_bitmap.nil?
        return -1 if dest_bitmap.disposed? || src_bitmap.disposed?
        
        begin
          src_rect = Rect.new(sx, sy, dw, dh)
          dest_bitmap.blt(dx, dy, src_bitmap, src_rect)
          return 0
        rescue
          return -1
        end
      end
    end

    class Win32API_Impl::TRGSSX::StretchBltR
      def call(args)
        dest_info, dx, dy, dw, dh, src_info, sx, sy, sw, sh, opacity = args
        
        dest_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(dest_info)
        src_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(src_info)
        
        return -1 if dest_bitmap.nil? || src_bitmap.nil?
        return -1 if dest_bitmap.disposed? || src_bitmap.disposed?
        
        begin
          dest_rect = Rect.new(dx, dy, dw, dh)
          src_rect = Rect.new(sx, sy, sw, sh)
          if dest_bitmap.respond_to?(:stretch_blt)
            dest_bitmap.stretch_blt(dest_rect, src_bitmap, src_rect, opacity || 255)
          else
            dest_bitmap.blt(dx, dy, src_bitmap, src_rect, opacity || 255)
          end
          return 0
        rescue
          return -1
        end
      end
    end

    class Win32API_Impl::TRGSSX::SkewBltR
      def call(args)
        dest_info, dx, dy, src_info, sx, sy, sw, sh, slope, opacity = args
        
        dest_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(dest_info)
        src_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(src_info)
        
        return -1 if dest_bitmap.nil? || src_bitmap.nil?
        return -1 if dest_bitmap.disposed? || src_bitmap.disposed?
        
        begin
          src_rect = Rect.new(sx, sy, sw, sh)
          dest_bitmap.blt(dx, dy, src_bitmap, src_rect, opacity || 255)
          return 0
        rescue
          return -1
        end
      end
    end

    # 绘图功能
    class Win32API_Impl::TRGSSX::DrawPolygon
      def call(args)
        return 0  # 简化实现：不绘制
      end
    end

    class Win32API_Impl::TRGSSX::FillPolygon
      def call(args)
        return 0  # 简化实现：不绘制
      end
    end

    class Win32API_Impl::TRGSSX::DrawRegularPolygon
      def call(args)
        return 0  # 简化实现：不绘制
      end
    end

    class Win32API_Impl::TRGSSX::FillRegularPolygon
      def call(args)
        return 0  # 简化实现：不绘制
      end
    end

    class Win32API_Impl::TRGSSX::DrawSpoke
      def call(args)
        return 0  # 简化实现：不绘制
      end
    end

    # 文本绘制
    class Win32API_Impl::TRGSSX::DrawTextNAA
      def call(args)
        dest_info, dx, dy, dw, dh, text, fontname, fontsize, color, align, flags = args
        
        dest_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(dest_info)
        return -1 if dest_bitmap.nil? || dest_bitmap.disposed?
        
        begin
          rect = Rect.new(dx, dy, dw, dh)
          dest_bitmap.draw_text(rect, text.to_s, align || 0)
          return 0
        rescue
          return -1
        end
      end
    end

    class Win32API_Impl::TRGSSX::DrawTextFastA
      def call(args)
        dest_info, dx, dy, dw, dh, text, fontname, fontsize, color, align, flags = args
        
        dest_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(dest_info)
        return -1 if dest_bitmap.nil? || dest_bitmap.disposed?
        
        begin
          rect = Rect.new(dx, dy, dw, dh)
          dest_bitmap.draw_text(rect, text.to_s, align || 0)
          return 0
        rescue
          return -1
        end
      end
    end

    class Win32API_Impl::TRGSSX::GetTextSizeNAA
      def call(args)
        dest_info, text, fontname, fontsize, flags, size = args
        
        dest_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(dest_info)
        return -1 if dest_bitmap.nil? || dest_bitmap.disposed?
        
        begin
          text_size = dest_bitmap.text_size(text.to_s)
          size_data = [text_size.width, text_size.height].pack('l!2')
          size.replace(size_data)
          return 0
        rescue
          return -1
        end
      end
    end

    class Win32API_Impl::TRGSSX::GetTextSizeFastA
      def call(args)
        dest_info, text, fontname, fontsize, flags, size = args
        
        dest_bitmap = Win32API_Impl::TRGSSX.get_bitmap_from_info(dest_info)
        return -1 if dest_bitmap.nil? || dest_bitmap.disposed?
        
        begin
          text_size = dest_bitmap.text_size(text.to_s)
          size_data = [text_size.width, text_size.height].pack('l!2')
          size.replace(size_data)
          return 0
        rescue
          return -1
        end
      end
    end

    class Win32API_Impl::TRGSSX::SaveToBitmapA
      def call(args)
        filename, info = args
        puts "[TRGSSX模拟] 保存位图到: #{filename}"
        return 0
      end
    end
  end
end

# 修复 BitmapExtension 脚本中的潜在问题
module BitmapExtensionFix
  # 确保 TRGSSX 模块不会因为找不到 DLL 而退出
  def self.patch_trgssx_module
    return unless defined?(TRGSSX)
    
    # 如果 TRGSSX 模块中的 NO_TRGSSX 被设置为 true，尝试修复
    if TRGSSX.const_defined?(:NO_TRGSSX) && TRGSSX::NO_TRGSSX
      begin
        # 重新设置为 false，让脚本使用我们的实现
        TRGSSX.send(:remove_const, :NO_TRGSSX)
        TRGSSX.const_set(:NO_TRGSSX, false)
        puts "[BitmapExtension补丁] 已启用 TRGSSX 模拟支持"
      rescue
        puts "[BitmapExtension补丁] 警告: 无法修复 TRGSSX 状态"
      end
    end
  end

  # 修复字体相关的兼容性问题
  def self.patch_font_compatibility
    # 确保 Font 类有必要的方法
    unless Font.method_defined?(:frame)
      Font.class_eval do
        attr_accessor :frame
        alias_method :original_initialize, :initialize
        
        def initialize(*args)
          original_initialize(*args)
          @frame = false
        end
      end
    end

    # 确保有 gradation_color 属性
    unless Font.method_defined?(:gradation_color)
      Font.class_eval do
        attr_accessor :gradation_color
      end
    end
  end

  # 修复 Color 类的 ARGB 支持
  def self.patch_color_argb
    unless Color.method_defined?(:argb_code)
      Color.class_eval do
        def argb_code
          n = 0
          n |= alpha.to_i << 24
          n |= red.to_i << 16
          n |= green.to_i << 8
          n |= blue.to_i
          return n
        end
      end
    end
  end

  # 修复 Bitmap 的兼容性
  def self.patch_bitmap_compatibility
    # 确保 Bitmap 有必要的方法
    unless Bitmap.method_defined?(:get_base_info)
      Bitmap.class_eval do
        def get_base_info
          [object_id, width, height].pack('l!3')
        end
      end
    end
  end

  # 应用所有补丁
  def self.apply_all_patches
    patch_font_compatibility
    patch_color_argb
    patch_bitmap_compatibility
    patch_trgssx_module
  end
end

# 在脚本加载时应用补丁
BitmapExtensionFix.apply_all_patches

# 提供 BitmapExtension 脚本的回退支持
module BitmapExtensionFallback
  # 如果 BitmapExtension 由于找不到 DLL 而失败，提供基本的回退实现
  def self.provide_fallback_methods
    # 为 Bitmap 类添加基本的扩展方法实现
    Bitmap.class_eval do
      # 如果没有定义这些方法，提供简化版本
      unless method_defined?(:rop_blt)
        def rop_blt(x, y, src_bitmap, src_rect, rop = nil)
          blt(x, y, src_bitmap, src_rect)
        end
      end

      unless method_defined?(:blend_blt)
        def blend_blt(x, y, src_bitmap, src_rect, blend = nil)
          blt(x, y, src_bitmap, src_rect)
        end
      end

      unless method_defined?(:clip_blt)
        def clip_blt(x, y, src_bitmap, src_rect, region)
          blt(x, y, src_bitmap, src_rect)
        end
      end

      unless method_defined?(:stretch_blt_r)
        def stretch_blt_r(dest_rect, src_bitmap, src_rect, opacity = 255)
          if respond_to?(:stretch_blt)
            stretch_blt(dest_rect, src_bitmap, src_rect, opacity)
          else
            blt(dest_rect.x, dest_rect.y, src_bitmap, src_rect, opacity)
          end
        end
      end

      unless method_defined?(:skew_blt)
        def skew_blt(x, y, src_bitmap, src_rect, slope, opacity = 255)
          blt(x, y, src_bitmap, src_rect, opacity)
        end
      end

      unless method_defined?(:skew_blt_r)
        def skew_blt_r(x, y, src_bitmap, src_rect, slope, opacity = 255)
          blt(x, y, src_bitmap, src_rect, opacity)
        end
      end

      # 绘图方法的简化实现
      unless method_defined?(:draw_polygon)
        def draw_polygon(points, color, width = 1)
          # 简化实现：不绘制，避免错误
        end
      end

      unless method_defined?(:fill_polygon)
        def fill_polygon(points, st_color, ed_color, fill_mode = nil)
          # 简化实现：不绘制，避免错误
        end
      end

      unless method_defined?(:draw_regular_polygon)
        def draw_regular_polygon(x, y, r, n, color, width = 1)
          # 简化实现：不绘制，避免错误
        end
      end

      unless method_defined?(:fill_regular_polygon)
        def fill_regular_polygon(x, y, r, n, st_color, ed_color, fill_mode = nil)
          # 简化实现：不绘制，避免错误
        end
      end

      unless method_defined?(:draw_spoke)
        def draw_spoke(x, y, r, n, color, width = 1)
          # 简化实现：不绘制，避免错误
        end
      end

      # 文本方法
      unless method_defined?(:draw_text_na)
        def draw_text_na(*args)
          draw_text(*args)
        end
      end

      unless method_defined?(:draw_text_fast)
        def draw_text_fast(*args)
          draw_text(*args)
        end
      end

      unless method_defined?(:text_size_na)
        def text_size_na(text)
          text_size(text)
        end
      end

      unless method_defined?(:text_size_fast)
        def text_size_fast(text)
          text_size(text)
        end
      end

      unless method_defined?(:save)
        def save(filename)
          puts "[BitmapExtension] 保存功能未实现: #{filename}"
        end
      end
    end
  end
end

# 等待一帧后应用回退方法，确保 BitmapExtension 脚本有机会先加载
if defined?(Graphics)
  # 使用全局变量避免类变量问题
  $bitmap_extension_fallback_applied = false
  
  begin
    original_update = Graphics.method(:update)
    
    # Ruby 1.8.7 兼容性：避免使用 define_singleton_method
    if Graphics.respond_to?(:define_singleton_method)
      Graphics.define_singleton_method(:update) do
        original_update.call
        unless $bitmap_extension_fallback_applied
          BitmapExtensionFallback.provide_fallback_methods
          $bitmap_extension_fallback_applied = true
        end
      end
    else
      # Ruby 1.8.7 回退方案
      class << Graphics
        alias_method :original_update_bitmap_ext, :update
        def update
          original_update_bitmap_ext
          unless $bitmap_extension_fallback_applied
            BitmapExtensionFallback.provide_fallback_methods
            $bitmap_extension_fallback_applied = true
          end
        end
      end
    end
  rescue => e
    puts "[BitmapExtension补丁] 警告：无法hook Graphics.update: #{e.message}"
  end
end

puts "[BitmapExtension补丁] 补丁文件已加载完成" 