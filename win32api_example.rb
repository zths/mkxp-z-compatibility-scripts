# encoding:utf-8
# win32api_example.rb
# Win32API 扩展示例文件
# 展示如何添加新的 DLL 支持和方法实现

# !!!! 非常重要! 代码需要可以同时兼容 Ruby 1.8.7 1.9.3 和 3.1.3  !!!!

# 这个文件应该在 win32_wrap.rb 之后加载
# 例如：通过 preload 脚本或者在游戏脚本中 require

# ============================================================================
# 1. 扩展 Win32API_Impl 模块的基本结构
# ============================================================================
# Win32API_Impl 模块用于存放各个 DLL 的实现
# 每个 DLL 作为一个常量模块，每个函数作为一个类

module Win32API_Impl
  
  # ============================================================================
  # 2. 添加新的 DLL 支持 - User32 示例
  # ============================================================================
  module User32
    
    # ---- MessageBox 函数实现 ----
    # 对应 Win32 API: MessageBoxA/MessageBoxW
    class MessageBox
      def initialize
        @name = "MessageBox"
      end
      
      def call(args)
        # args 参数说明:
        # args[0] - hwnd (父窗口句柄，通常为 0)
        # args[1] - text (消息文本)
        # args[2] - caption (标题文本)  
        # args[3] - type (消息框类型，如 MB_OK = 0)
        
        hwnd, text, caption, type = args
        
        # 在非 Windows 平台模拟 MessageBox 行为
        puts "=" * 50
        puts "MessageBox 调用:"
        puts "标题: #{caption || '提示'}"
        puts "内容: #{text || ''}"
        puts "类型: #{format_mb_type(type || 0)}"
        puts "=" * 50
        
        # 返回值模拟 (通常 MessageBox 返回按钮 ID)
        return 1  # IDOK
      end
      
      private
      
      def format_mb_type(type)
        case type
        when 0 then "MB_OK"
        when 1 then "MB_OKCANCEL" 
        when 2 then "MB_ABORTRETRYIGNORE"
        when 3 then "MB_YESNOCANCEL"
        when 4 then "MB_YESNO"
        when 5 then "MB_RETRYCANCEL"
        else "Unknown (#{type})"
        end
      end
    end
    
    # ---- FindWindow 函数实现 ----
    # 对应 Win32 API: FindWindowA/FindWindowW
    class FindWindow
      def initialize
        @name = "FindWindow"
      end
      
      def call(args)
        # args[0] - lpClassName (窗口类名)
        # args[1] - lpWindowName (窗口标题)
        
        class_name, window_name = args
        
        puts "[Win32API模拟] FindWindow 调用:"
        puts "  类名: #{class_name || 'NULL'}"
        puts "  窗口名: #{window_name || 'NULL'}"
        
        # 模拟找到窗口，返回假的句柄
        return 12345  # 假的 HWND
      end
    end
    
  end
  
  # ============================================================================
  # 3. 添加新的 DLL 支持 - Kernel32 示例
  # ============================================================================
  module Kernel32
    
    # ---- GetTickCount 函数实现 ----
    # 对应 Win32 API: GetTickCount
    class GetTickCount
      def initialize
        @name = "GetTickCount"
        @start_time = Time.now
      end
      
      def call(args)
        # GetTickCount 返回系统启动后的毫秒数
        # 这里用程序运行时间模拟
        elapsed_ms = ((Time.now - @start_time) * 1000).to_i
        puts "[Win32API模拟] GetTickCount 返回: #{elapsed_ms} ms"
        return elapsed_ms
      end
    end
    
    # ---- Sleep 函数实现 ----
    # 对应 Win32 API: Sleep
    class Sleep
      def initialize
        @name = "Sleep"
      end
      
      def call(args)
        # args[0] - 睡眠时间(毫秒)
        sleep_ms = args[0] || 0
        puts "[Win32API模拟] Sleep #{sleep_ms} 毫秒"
        
        # 实际执行睡眠
        sleep(sleep_ms / 1000.0) if sleep_ms > 0
        return 0
      end
    end
    
  end
  
  # ============================================================================
  # 4. 添加自定义 DLL 支持示例
  # ============================================================================
  module CustomDll
    
    # 自定义函数示例
    class CustomFunction
      def initialize
        @name = "CustomFunction"
        @call_count = 0
      end
      
      def call(args)
        @call_count += 1
        puts "[自定义DLL] CustomFunction 第 #{@call_count} 次调用"
        puts "  参数: #{args.inspect}"
        
        # 返回调用次数
        return @call_count
      end
    end
    
  end
  
end

# ============================================================================
# 5. 使用示例
# ============================================================================

# 创建 Win32API 实例的示例
puts "Win32API 扩展使用示例:"
puts

# 示例 1: 使用 User32.MessageBox
begin
  msg_box = Win32API.new("user32", "MessageBox", ['L', 'P', 'P', 'L'], 'L')
  result = msg_box.call(0, "这是测试消息", "测试标题", 0)
  puts "MessageBox 返回值: #{result}"
rescue => e
  puts "MessageBox 调用失败: #{e.message}"
end

puts

# 示例 2: 使用 User32.FindWindow  
begin
  find_window = Win32API.new("user32", "FindWindow", ['P', 'P'], 'L')
  hwnd = find_window.call("Notepad", nil)
  puts "FindWindow 返回句柄: #{hwnd}"
rescue => e
  puts "FindWindow 调用失败: #{e.message}"
end

puts

# 示例 3: 使用 Kernel32.GetTickCount
begin
  get_tick = Win32API.new("kernel32", "GetTickCount", [], 'L')
  tick_count = get_tick.call()
  puts "GetTickCount 返回: #{tick_count}"
rescue => e
  puts "GetTickCount 调用失败: #{e.message}"
end

puts

# 示例 4: 使用 Kernel32.Sleep
begin
  sleep_api = Win32API.new("kernel32", "Sleep", ['L'], 'V')
  puts "开始睡眠..."
  sleep_api.call(1000)  # 睡眠 1 秒
  puts "睡眠结束"
rescue => e
  puts "Sleep 调用失败: #{e.message}"
end

puts

# 示例 5: 使用自定义 DLL
begin
  custom_func = Win32API.new("CustomDll", "CustomFunction", ['L', 'P'], 'L')
  result1 = custom_func.call(123, "测试参数")
  result2 = custom_func.call(456, "另一个测试")
  puts "自定义函数调用结果: #{result1}, #{result2}"
rescue => e
  puts "自定义函数调用失败: #{e.message}"
end

# ============================================================================
# 6. 开发说明和最佳实践
# ============================================================================

=begin

【添加新 DLL 支持的步骤】

1. 在 Win32API_Impl 模块中创建新的 DLL 模块
   - 模块名应该与 DLL 名称对应（首字母大写）
   - 例如: user32.dll -> User32, kernel32.dll -> Kernel32

2. 在 DLL 模块中为每个函数创建对应的类
   - 类名应该与函数名对应（首字母大写）
   - 例如: MessageBox, FindWindow, GetTickCount

3. 在函数类中实现以下方法:
   - initialize: 初始化方法，可以设置初始状态
   - call(args): 主要的函数实现，args 是参数数组

【实现函数时的注意事项】

1. 参数处理:
   - args 是一个数组，包含所有传入的参数
   - 需要根据原 Win32 API 的参数顺序和类型进行处理
   - 注意处理 nil/null 参数

2. 返回值:
   - 应该返回与原 Win32 API 相同类型的值
   - 对于 void 函数，返回 0
   - 对于有意义的返回值，尽量模拟真实行为

3. 错误处理:
   - win32_wrap.rb 已经处理了基本的错误情况
   - 避免抛出异常，除非确实需要

4. 跨平台兼容性:
   - 实现应该在所有平台上工作
   - 对于平台特定的功能，提供合理的替代行为
   - 使用标准 Ruby 库而不是平台特定的扩展

【调试和测试】

1. 启用日志:
   Win32API::LOG_NATIVE = true  # 显示原生调用日志

2. 容错模式:
   Win32API::TOLERATE_ERRORS = true  # 忽略错误，返回默认值

3. 禁用原生调用:
   Win32API::NATIVE_ON_WINDOWS = false  # 强制使用模拟实现

=end 