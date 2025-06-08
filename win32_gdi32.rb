# encoding:utf-8
# GDI32 模块实现
module Win32API_Impl
  module Gdi32
  end
  module Gdi32_Helper
    # 区域句柄管理
    @@region_handles = {}
    @@next_handle = 1

    def self.create_handle(region_data)
      handle = @@next_handle
      @@next_handle += 1
      @@region_handles[handle] = region_data
      handle
    end

    def self.get_region_data(handle)
      @@region_handles[handle]
    end

    def self.delete_handle(handle)
      @@region_handles.delete(handle)
    end

    def self.clear_handles
      @@region_handles.clear
    end
  end
end

# GDI32 具体类实现

# DeleteObject - 删除GDI对象
class Win32API_Impl::Gdi32::DeleteObject
  def call(args)
    handle = args[0]
    return 0 if handle.nil? || handle == 0
    
    # 删除区域句柄
    Win32API_Impl::Gdi32_Helper.delete_handle(handle)
    return 1  # 成功
  end
end

# CreateRectRgn - 创建矩形区域
class Win32API_Impl::Gdi32::CreateRectRgn
  def call(args)
    left, top, right, bottom = args
    
    # 创建矩形区域数据
    region_data = {
      :type => :rect,
      :left => left,
      :top => top,
      :right => right,
      :bottom => bottom
    }
    
    return Win32API_Impl::Gdi32_Helper.create_handle(region_data)
  end
end

# CreateRectRgnIndirect - 通过RECT结构创建矩形区域
class Win32API_Impl::Gdi32::CreateRectRgnIndirect
  def call(args)
    rect_ptr = args[0]
    return 0 if rect_ptr.nil?
    
    # 解包RECT结构 (left, top, right, bottom)
    # Ruby 1.8.7 兼容性处理
    begin
      rect_data = rect_ptr.unpack('l4')
    rescue
      rect_data = rect_ptr.unpack('l*')[0, 4]
    end
    left, top, right, bottom = rect_data
    
    region_data = {
      :type => :rect,
      :left => left,
      :top => top,
      :right => right,
      :bottom => bottom
    }
    
    return Win32API_Impl::Gdi32_Helper.create_handle(region_data)
  end
end

# CreateRoundRectRgn - 创建圆角矩形区域
class Win32API_Impl::Gdi32::CreateRoundRectRgn
  def call(args)
    left, top, right, bottom, width_ellipse, height_ellipse = args
    
    region_data = {
      :type => :round_rect,
      :left => left,
      :top => top,
      :right => right,
      :bottom => bottom,
      :width_ellipse => width_ellipse || 0,
      :height_ellipse => height_ellipse || 0
    }
    
    return Win32API_Impl::Gdi32_Helper.create_handle(region_data)
  end
end

# CreateEllipticRgn - 创建椭圆区域
class Win32API_Impl::Gdi32::CreateEllipticRgn
  def call(args)
    left, top, right, bottom = args
    
    region_data = {
      :type => :elliptic,
      :left => left,
      :top => top,
      :right => right,
      :bottom => bottom
    }
    
    return Win32API_Impl::Gdi32_Helper.create_handle(region_data)
  end
end

# CreateEllipticRgnIndirect - 通过RECT结构创建椭圆区域
class Win32API_Impl::Gdi32::CreateEllipticRgnIndirect
  def call(args)
    rect_ptr = args[0]
    return 0 if rect_ptr.nil?
    
    # 解包RECT结构
    # Ruby 1.8.7 兼容性处理
    begin
      rect_data = rect_ptr.unpack('l4')
    rescue
      rect_data = rect_ptr.unpack('l*')[0, 4]
    end
    left, top, right, bottom = rect_data
    
    region_data = {
      :type => :elliptic,
      :left => left,
      :top => top,
      :right => right,
      :bottom => bottom
    }
    
    return Win32API_Impl::Gdi32_Helper.create_handle(region_data)
  end
end

# CreatePolygonRgn - 创建多边形区域
class Win32API_Impl::Gdi32::CreatePolygonRgn
  def call(args)
    points_ptr, count, fill_mode = args
    return 0 if points_ptr.nil? || count <= 0
    
    # 解包点数据，每个点是两个长整型(x, y)
    # Ruby 1.8.7 兼容性处理
    begin
      points_data = points_ptr.unpack("l#{count * 2}")
    rescue
      points_data = points_ptr.unpack('l*')[0, count * 2]
    end
    points = []
    
    count.times do |i|
      x = points_data[i * 2]
      y = points_data[i * 2 + 1]
      points << [x, y]
    end
    
    region_data = {
      :type => :polygon,
      :points => points,
      :fill_mode => fill_mode || 2  # WINDING
    }
    
    return Win32API_Impl::Gdi32_Helper.create_handle(region_data)
  end
end

# CreatePolyPolygonRgn - 创建复合多边形区域
class Win32API_Impl::Gdi32::CreatePolyPolygonRgn
  def call(args)
    points_ptr, counts_ptr, polygon_count, fill_mode = args
    return 0 if points_ptr.nil? || counts_ptr.nil? || polygon_count <= 0
    
    # 解包每个多边形的点数
    # Ruby 1.8.7 兼容性处理
    begin
      counts = counts_ptr.unpack("l#{polygon_count}")
    rescue
      counts = counts_ptr.unpack('l*')[0, polygon_count]
    end
    
    # inject 方法在 Ruby 1.8.7 中可能叫 inject
    if counts.respond_to?(:inject)
      total_points = counts.inject(0) { |sum, count| sum + count }
    else
      total_points = 0
      counts.each { |count| total_points += count }
    end
    
    # 解包所有点数据
    # Ruby 1.8.7 兼容性处理
    begin
      points_data = points_ptr.unpack("l#{total_points * 2}")
    rescue
      points_data = points_ptr.unpack('l*')[0, total_points * 2]
    end
    
    polygons = []
    point_index = 0
    
    polygon_count.times do |i|
      point_count = counts[i]
      points = []
      
      point_count.times do |j|
        x = points_data[point_index * 2]
        y = points_data[point_index * 2 + 1]
        points << [x, y]
        point_index += 1
      end
      
      polygons << points
    end
    
    region_data = {
      :type => :polypolygon,
      :polygons => polygons,
      :fill_mode => fill_mode || 2  # WINDING
    }
    
    return Win32API_Impl::Gdi32_Helper.create_handle(region_data)
  end
end

# CombineRgn - 合并区域
class Win32API_Impl::Gdi32::CombineRgn
  # 合并模式常量
  RGN_AND  = 1
  RGN_OR   = 2
  RGN_XOR  = 3
  RGN_DIFF = 4
  RGN_COPY = 5

  def call(args)
    dest_rgn, src_rgn1, src_rgn2, combine_mode = args
    
    return 0 if dest_rgn.nil? || dest_rgn == 0
    return 0 if src_rgn1.nil? || src_rgn1 == 0
    
    src1_data = Win32API_Impl::Gdi32_Helper.get_region_data(src_rgn1)
    return 0 if src1_data.nil?
    
    result_data = nil
    
    case combine_mode
    when RGN_COPY
      # 复制源区域1
      result_data = src1_data.dup
    when RGN_AND, RGN_OR, RGN_XOR, RGN_DIFF
      # 需要第二个源区域
      return 0 if src_rgn2.nil? || src_rgn2 == 0
      src2_data = Win32API_Impl::Gdi32_Helper.get_region_data(src_rgn2)
      return 0 if src2_data.nil?
      
      # 简化实现：创建合并区域数据
      result_data = {
        :type => :combined,
        :operation => combine_mode,
        :region1 => src1_data,
        :region2 => src2_data
      }
    else
      return 0  # 未知的合并模式
    end
    
    # 更新目标区域
    Win32API_Impl::Gdi32_Helper.delete_handle(dest_rgn)
    # Ruby 1.8.7 兼容性处理：避免使用 class_variable_get
    begin
      if defined?(@@region_handles)
        @@region_handles[dest_rgn] = result_data
      else
        # 通过Helper模块的类变量访问
        Win32API_Impl::Gdi32_Helper.class_eval do
          @@region_handles[dest_rgn] = result_data
        end
      end
    rescue
      # 简化处理：重新创建句柄
      Win32API_Impl::Gdi32_Helper.create_handle(result_data)
    end
    
    return 1  # 成功，简单区域
  end
end 