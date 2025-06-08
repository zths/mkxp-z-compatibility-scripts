# encoding:utf-8
$win32KeyStates = nil

module Graphics
  class << self
    alias_method(:win32wrap_update, :update)

    def update
      win32wrap_update
      $win32KeyStates = nil
    end
  end
end

# User32 模块实现
module Win32API_Impl
  module User32
  end
  module User32_Helper
    def self.get_raw_keystates
      if $win32KeyStates == nil
        $win32KeyStates = MKXP.raw_key_states
      end
  
      return $win32KeyStates
    end
  
    def self.common_keystate(vkey)
      vkey_name = Scancodes::WIN32INV[vkey]
  
      states = get_raw_keystates
      pressed = false
  
      if vkey_name == :LBUTTON
        pressed = Input.press?(Input::MOUSELEFT)
      elsif vkey_name == :RBUTTON
        pressed = Input.press?(Input::MOUSERIGHT)
      elsif vkey_name == :MBUTTON
        pressed = Input.press?(Input::MOUSEMIDDLE)
      elsif vkey_name == :SHIFT
        pressed = double_state(states, :LSHIFT, :RSHIFT)
      elsif vkey_name == :MENU
        pressed = double_state(states, :LALT, :RALT)
      elsif vkey_name == :CONTROL
        pressed = double_state(states, :LCTRL, :RCTRL)
      else
        scan = nil
        if Scancodes::SDL.key?(vkey_name)
          scan = vkey_name
        else
          scan = Scancodes::WIN2SDL[vkey_name] || :UNKNOWN
        end
  
        pressed = state_pressed(states, scan)
      end
  
      return pressed ? 1 : 0
    end
  
    def self.memcpy_string(dst, src)
      i = 0
      src.each_byte do |b|
        dst.setbyte(i, b)
        i += 1
      end
    end
  
    def self.state_pressed(states, sdl_scan)
      sdl_value = Scancodes::SDL[sdl_scan] || Scancodes::SDL[:UNKNOWN]
      return !!states[sdl_value]
    end
  
    def self.double_state(states, left, right)
      return state_pressed(states, left) || state_pressed(states, right)
    end
    
    module Scancodes
      SDL = { :UNKNOWN => 0x00,
              :A => 0x04, :B => 0x05, :C => 0x06, :D => 0x07,
              :E => 0x08, :F => 0x09, :G => 0x0A, :H => 0x0B,
              :I => 0x0C, :J => 0x0D, :K => 0x0E, :L => 0x0F,
              :M => 0x10, :N => 0x11, :O => 0x12, :P => 0x13,
              :Q => 0x14, :R => 0x15, :S => 0x16, :T => 0x17,
              :U => 0x18, :V => 0x19, :W => 0x1A, :X => 0x1B,
              :Y => 0x1C, :Z => 0x1D, :N1 => 0x1E, :N2 => 0x1F,
              :N3 => 0x20, :N4 => 0x21, :N5 => 0x22, :N6 => 0x23,
              :N7 => 0x24, :N8 => 0x25, :N9 => 0x26, :N0 => 0x27,
              :RETURN => 0x28, :ESCAPE => 0x29, :BACKSPACE => 0x2A, :TAB => 0x2B,
              :SPACE => 0x2C, :MINUS => 0x2D, :EQUALS => 0x2E, :LEFTBRACKET => 0x2F,
              :RIGHTBRACKET => 0x30, :BACKSLASH => 0x31, :NONUSHASH => 0x32, :SEMICOLON => 0x33,
              :APOSTROPHE => 0x34, :GRAVE => 0x35, :COMMA => 0x36, :PERIOD => 0x37,
              :SLASH => 0x38, :CAPSLOCK => 0x39, :F1 => 0x3A, :F2 => 0x3B,
              :F3 => 0x3C, :F4 => 0x3D, :F5 => 0x3E, :F6 => 0x3F,
              :F7 => 0x40, :F8 => 0x41, :F9 => 0x42, :F10 => 0x43,
              :F11 => 0x44, :F12 => 0x45, :PRINTSCREEN => 0x46, :SCROLLLOCK => 0x47,
              :PAUSE => 0x48, :INSERT => 0x49, :HOME => 0x4A, :PAGEUP => 0x4B,
              :DELETE => 0x4C, :END => 0x4D, :PAGEDOWN => 0x4E, :RIGHT => 0x4F,
              :LEFT => 0x50, :DOWN => 0x51, :UP => 0x52, :NUMLOCKCLEAR => 0x53,
              :KP_DIVIDE => 0x54, :KP_MULTIPLY => 0x55, :KP_MINUS => 0x56, :KP_PLUS => 0x57,
              :KP_ENTER => 0x58, :KP_1 => 0x59, :KP_2 => 0x5A, :KP_3 => 0x5B,
              :KP_4 => 0x5C, :KP_5 => 0x5D, :KP_6 => 0x5E, :KP_7 => 0x5F,
              :KP_8 => 0x60, :KP_9 => 0x61, :KP_0 => 0x62, :KP_PERIOD => 0x63,
              :NONUSBACKSLASH => 0x64, :APPLICATION => 0x65, :POWER => 0x66, :KP_EQUALS => 0x67,
              :F13 => 0x68, :F14 => 0x69, :F15 => 0x6A, :F16 => 0x6B,
              :F17 => 0x6C, :F18 => 0x6D, :F19 => 0x6E, :F20 => 0x6F,
              :F21 => 0x70, :F22 => 0x71, :F23 => 0x72, :F24 => 0x73,
              :EXECUTE => 0x74, :HELP => 0x75, :MENU => 0x76, :SELECT => 0x77,
              :STOP => 0x78, :AGAIN => 0x79, :UNDO => 0x7A, :CUT => 0x7B,
              :COPY => 0x7C, :PASTE => 0x7D, :FIND => 0x7E, :MUTE => 0x7F,
              :VOLUMEUP => 0x80, :VOLUMEDOWN => 0x81, :LOCKINGCAPSLOCK => 0x82, :LOCKINGNUMLOCK => 0x83,
              :LOCKINGSCROLLLOCK => 0x84, :KP_COMMA => 0x85, :KP_EQUALSAS400 => 0x86, :INTERNATIONAL1 => 0x87,
              :INTERNATIONAL2 => 0x88, :INTERNATIONAL3 => 0x89, :INTERNATIONAL4 => 0x8A, :INTERNATIONAL5 => 0x8B,
              :INTERNATIONAL6 => 0x8C, :INTERNATIONAL7 => 0x8D, :INTERNATIONAL8 => 0x8E, :INTERNATIONAL9 => 0x8F,
              :LANG1 => 0x90, :LANG2 => 0x91, :LANG3 => 0x92, :LANG4 => 0x93,
              :LANG5 => 0x94, :LANG6 => 0x95, :LANG7 => 0x96, :LANG8 => 0x97,
              :LANG9 => 0x98, :ALTERASE => 0x99, :SYSREQ => 0x9A, :CANCEL => 0x9B,
              :CLEAR => 0x9C, :PRIOR => 0x9D, :RETURN2 => 0x9E, :SEPARATOR => 0x9F,
              :OUT => 0xA0, :OPER => 0xA1, :CLEARAGAIN => 0xA2, :CRSEL => 0xA3,
              :EXSEL => 0xA4, :KP_00 => 0xB0, :KP_000 => 0xB1, :THOUSANDSSEPARATOR => 0xB2,
              :DECIMALSEPARATOR => 0xB3, :CURRENCYUNIT => 0xB4, :CURRENCYSUBUNIT => 0xB5, :KP_LEFTPAREN => 0xB6,
              :KP_RIGHTPAREN => 0xB7, :KP_LEFTBRACE => 0xB8, :KP_RIGHTBRACE => 0xB9, :KP_TAB => 0xBA,
              :KP_BACKSPACE => 0xBB, :KP_A => 0xBC, :KP_B => 0xBD, :KP_C => 0xBE,
              :KP_D => 0xBF, :KP_E => 0xC0, :KP_F => 0xC1, :KP_XOR => 0xC2,
              :KP_POWER => 0xC3, :KP_PERCENT => 0xC4, :KP_LESS => 0xC5, :KP_GREATER => 0xC6,
              :KP_AMPERSAND => 0xC7, :KP_DBLAMPERSAND => 0xC8, :KP_VERTICALBAR => 0xC9, :KP_DBLVERTICALBAR => 0xCA,
              :KP_COLON => 0xCB, :KP_HASH => 0xCC, :KP_SPACE => 0xCD, :KP_AT => 0xCE,
              :KP_EXCLAM => 0xCF, :KP_MEMSTORE => 0xD0, :KP_MEMRECALL => 0xD1, :KP_MEMCLEAR => 0xD2,
              :KP_MEMADD => 0xD3, :KP_MEMSUBTRACT => 0xD4, :KP_MEMMULTIPLY => 0xD5, :KP_MEMDIVIDE => 0xD6,
              :KP_PLUSMINUS => 0xD7, :KP_CLEAR => 0xD8, :KP_CLEARENTRY => 0xD9, :KP_BINARY => 0xDA,
              :KP_OCTAL => 0xDB, :KP_DECIMAL => 0xDC, :KP_HEXADECIMAL => 0xDD, :LCTRL => 0xE0,
              :LSHIFT => 0xE1, :LALT => 0xE2, :LGUI => 0xE3, :RCTRL => 0xE4,
              :RSHIFT => 0xE5, :RALT => 0xE6, :RGUI => 0xE7, :MODE => 0x101,
              :AUDIONEXT => 0x102, :AUDIOPREV => 0x103, :AUDIOSTOP => 0x104, :AUDIOPLAY => 0x105,
              :AUDIOMUTE => 0x106, :MEDIASELECT => 0x107, :WWW => 0x108, :MAIL => 0x109,
              :CALCULATOR => 0x10A, :COMPUTER => 0x10B, :AC_SEARCH => 0x10C, :AC_HOME => 0x10D,
              :AC_BACK => 0x10E, :AC_FORWARD => 0x10F, :AC_STOP => 0x110, :AC_REFRESH => 0x111,
              :AC_BOOKMARKS => 0x112, :BRIGHTNESSDOWN => 0x113, :BRIGHTNESSUP => 0x114, :DISPLAYSWITCH => 0x115,
              :KBDILLUMTOGGLE => 0x116, :KBDILLUMDOWN => 0x117, :KBDILLUMUP => 0x118, :EJECT => 0x119,
              :SLEEP => 0x11A, :APP1 => 0x11B, :APP2 => 0x11C
      }
  
      # 为了兼容 Ruby 1.8.7，使用 default_proc 或 fetch 替代 default=
      if RUBY_VERSION.split('.')[0].to_i >= 2
        SDL.default = SDL[:UNKNOWN]
      end
  
      WIN32 = {
        :LBUTTON => 0x01, :RBUTTON => 0x02, :MBUTTON => 0x04,
  
        :BACK => 0x08, :TAB => 0x09, :RETURN => 0x0D, :SHIFT => 0x10,
        :CONTROL => 0x11, :MENU => 0x12, :PAUSE => 0x13, :CAPITAL => 0x14,
        :ESCAPE => 0x1B, :SPACE => 0x20, :PRIOR => 0x21, :NEXT => 0x22,
        :END => 0x23, :HOME => 0x24, :LEFT => 0x25, :UP => 0x26,
        :RIGHT => 0x27, :DOWN => 0x28, :PRINT => 0x2A, :INSERT => 0x2D,
        :DELETE => 0x2E,
  
        :N0 => 0x30, :N1 => 0x31, :N2 => 0x32, :N3 => 0x33,
        :N4 => 0x34, :N5 => 0x35, :N6 => 0x36, :N7 => 0x37, :N8 => 0x38,
        :N9 => 0x39,
  
        :A => 0x41, :B => 0x42, :C => 0x43, :D => 0x44, :E => 0x45, :F => 0x46,
        :G => 0x47, :H => 0x48, :I => 0x49, :J => 0x4A, :K => 0x4B, :L => 0x4C,
        :M => 0x4D, :N => 0x4E, :O => 0x4F, :P => 0x50, :Q => 0x51, :R => 0x52,
        :S => 0x53, :T => 0x54, :U => 0x55, :V => 0x56, :W => 0x57, :X => 0x58,
        :Y => 0x59, :Z => 0x5A,
  
        :LWIN => 0x5B, :RWIN => 0x5C,
  
        :NUMPAD0 => 0x60, :NUMPAD1 => 0x61, :NUMPAD2 => 0x62, :NUMPAD3 => 0x63,
        :NUMPAD4 => 0x64, :NUMPAD5 => 0x65, :NUMPAD6 => 0x66, :NUMPAD7 => 0x67,
        :NUMPAD8 => 0x68, :NUMPAD9 => 0x69,
        :MULTIPLY => 0x6A, :ADD => 0x6B, :SEPARATOR => 0x6C, :SUBTRACT => 0x6D,
        :DECIMAL => 0x6E, :DIVIDE => 0x6F,
  
        :F1 => 0x70, :F2 => 0x71, :F3 => 0x72, :F4 => 0x73,
        :F5 => 0x74, :F6 => 0x75, :F7 => 0x76, :F8 => 0x77,
        :F9 => 0x78, :F10 => 0x79, :F11 => 0x7A, :F12 => 0x7B,
        :F13 => 0x7C, :F14 => 0x7D, :F15 => 0x7E, :F16 => 0x7F,
        :F17 => 0x80, :F18 => 0x81, :F19 => 0x82, :F20 => 0x83,
        :F21 => 0x84, :F22 => 0x85, :F23 => 0x86, :F24 => 0x87,
  
        :NUMLOCK => 0x90, :SCROLL => 0x91,
        :LSHIFT => 0xA0, :RSHIFT => 0xA1, :LCONTROL => 0xA2, :RCONTROL => 0xA3,
        :LMENU => 0xA4, :RMENU => 0xA5,
  
        :OEM_1 => 0xBA,
        :OEM_PLUS => 0xBB, :OEM_COMMA => 0xBC, :OEM_MINUS => 0xBD, :OEM_PERIOD => 0xBE,
        :OEM_2 => 0xBF, :OEM_3 => 0xC0, :OEM_4 => 0xDB, :OEM_5 => 0xDC,
        :OEM_6 => 0xDD, :OEM_7 => 0xDE
      }
  
      WIN32INV = WIN32.invert
  
      WIN2SDL = {
        :BACK => :BACKSPACE,
        :CAPITAL => :CAPSLOCK,
        :PRIOR => :PAGEUP, :NEXT => :PAGEDOWN,
        :PRINT => :PRINTSCREEN,
  
        :LWIN => :LGUI, :RWIN => :RGUI,
  
        :NUMPAD0 => :KP_0, :NUMPAD1 => :KP_1, :NUMPAD2 => :KP_2, :NUMPAD3 => :KP_3,
        :NUMPAD4 => :KP_4, :NUMPAD5 => :KP_5, :NUMPAD6 => :KP_6, :NUMPAD7 => :KP_7,
        :NUMPAD8 => :KP_8, :NUMPAD9 => :KP_9,
        :MULTIPLY => :KP_MULTIPLY, :ADD => :KP_PLUS, :SUBTRACT => :KP_MINUS,
        :DECIMAL => :KP_DECIMAL, :DIVIDE => :KP_DIVIDE,
  
        :NUMLOCK => :NUMLOCKCLEAR, :SCROLL => :SCROLLLOCK,
        :LCONTROL => :LCTRL, :RCONTROL => :RCTRL,
        :LMENU => :LALT, :RMENU => :RALT,
  
        # These are OEM and can vary by country
        # Values taken from Joiplay's src/input.cpp
        :OEM_1 => :SEMICOLON,
        :OEM_PLUS => :EQUALS, :OEM_COMMA => :COMMA, :OEM_MINUS => :MINUS, :OEM_PERIOD => :PERIOD,
        :OEM_2 => :SLASH, :OEM_3 => :GRAVE, :OEM_4 => :LEFTBRACKET, :OEM_5 => :BACKSLASH,
        :OEM_6 => :RIGHTBRACKET, :OEM_7 => :APOSTROPHE
      }
  
      # 为了兼容 Ruby 1.8.7，使用 default_proc 或 fetch 替代 default=
      if RUBY_VERSION.split('.')[0].to_i >= 2
        WIN2SDL.default = :UNKNOWN
      end
    end
  end

end

# User32 具体类实现
class Win32API_Impl::User32::Keybd_event
  Seq = [
    [0xA4, 0, 0, 0],
    [0xD, 0, 0, 0],
    [0xD, 0, 2, 0],
    [0xA4, 0, 2, 0]]
  Seq2 = [
    [0x12, 0, 0, 0],
    [0xD, 0, 0, 0],
    [0xD, 0, 2, 0],
    [0x12, 0, 2, 0]]

  def initialize
    @index = 0
  end

  def call(args)
    seq = [args[0], args[1], args[2], args[3]]

    if seq == Seq[@index] or seq == Seq2[@index]
      @index += 1
    else
      @index = 0
    end

    if @index == 4
      @index = 0
      Graphics.fullscreen = !Graphics.fullscreen
    end
  end
end

class Win32API_Impl::User32::GetKeyState
  def call(vkey)
    return Win32API_Impl::User32_Helper::common_keystate(vkey[0])
  end
end

class Win32API_Impl::User32::GetAsyncKeyState
  PRESSED_BIT = (1 << 15)

  def call(vkey)
    return Win32API_Impl::User32_Helper::common_keystate(vkey[0]) == 1 ? PRESSED_BIT : 0
  end
end

class Win32API_Impl::User32::GetKeyboardState
  PRESSED_BIT = 0x80

  def call(args)
    out_states = args[0]

    Win32API_Impl::User32_Helper::Scancodes::WIN32.each do |name, val|
      pressed = Win32API_Impl::User32_Helper::common_keystate(val) == 1

      out_states.setbyte(val, pressed ? PRESSED_BIT : 0)
    end
    return 1
  end
end

class Win32API_Impl::User32::ShowCursor
  def initialize
    @cursor_count = 0
  end

  def call(args)
    if args[0] == 1
      @cursor_count += 1
    else
      @cursor_count -= 1
    end

    Graphics.show_cursor = @cursor_count >= 0
  end
end

class Win32API_Impl::User32::GetCursorPos
  def call(args)
    out = [Input.mouse_x, Input.mouse_y].pack('ll')
    Win32API_Impl::User32_Helper::memcpy_string(args[0], out)
    return 1
  end
end

class Win32API_Impl::User32::GetClientRect
  def call(args)
    hwnd, rect_ptr = args
    
    # 获取当前Graphics大小
    begin
      width = Graphics.width
    rescue
      width = 544
    end
    
    begin
      height = Graphics.height
    rescue
      height = 416
    end
    
    # 客户区矩形 (left, top, right, bottom)
    rect = [0, 0, width, height].pack('l4')
    Win32API_Impl::User32_Helper::memcpy_string(rect_ptr, rect)
    return 1
  end
end

class Win32API_Impl::User32::ScreenToClient
  def call(args)
    return 1
  end
end

class Win32API_Impl::User32::FindWindow
  def call(args)
    class_name, window_name = args
    # 如果查找的是RGSS Player窗口，返回一个固定的句柄
    if class_name == "RGSS Player" || window_name
      return 42  # 返回固定的窗口句柄
    else
      return 0   # 窗口未找到
    end
  end
end

class Win32API_Impl::User32::GetDesktopWindow
  def call(args)
    return 1  # 返回桌面窗口句柄
  end
end

class Win32API_Impl::User32::SetWindowPos
  def call(args)
    hwnd, hwnd_insert_after, x, y, width, height, flags = args
    
    # SWP_NOSIZE = 0x01, SWP_NOMOVE = 0x02, SWP_NOZORDER = 0x04
    swp_nosize = 0x01
    swp_nomove = 0x02
    
    begin
      # 如果不是NOSIZE标志，尝试调整Graphics大小
      unless (flags & swp_nosize) != 0
        if width > 0 && height > 0
          # 计算客户区大小（减去边框）
          client_width = [width - 16, 544].max   # 最小544像素宽
          client_height = [height - 39, 416].max # 最小416像素高，减去标题栏高度
          
          # 尝试调整Graphics大小
          if Graphics.respond_to?("resize_screen")
            Graphics.resize_screen(client_width, client_height)
          end
        end
      end
      
      return 1  # 成功
    rescue => e
      return 0  # 失败
    end
  end
end

class Win32API_Impl::User32::GetWindowRect
  def call(args)
    hwnd, rect_ptr = args
    
    # 获取当前Graphics大小并加上边框
    begin
      base_width = Graphics.width
    rescue
      base_width = 544
    end
    
    begin
      base_height = Graphics.height
    rescue
      base_height = 416
    end
    
    width = base_width + 16    # 加上左右边框
    height = base_height + 39  # 加上标题栏和上下边框
    
    # 窗口矩形 (left, top, right, bottom)，假设窗口在 (100, 100) 位置
    left, top = 100, 100
    rect = [left, top, left + width, top + height].pack('l4')
    Win32API_Impl::User32_Helper::memcpy_string(rect_ptr, rect)
    return 1
  end
end

class Win32API_Impl::User32::GetWindowLong
  def call(args)
    hwnd, index = args
    
    case index
    when -16  # GWL_STYLE
      # 返回标准窗口样式 (WS_OVERLAPPEDWINDOW)
      return 0x00CF0000
    when -20  # GWL_EXSTYLE
      # 返回扩展窗口样式
      return 0x00000100
    else
      return 0
    end
  end
end

class Win32API_Impl::User32::GetSystemMetrics
  def call(args)
    index = args[0]
    
    case index
    when 0x04  # SM_CYCAPTION (标题栏高度)
      return 23
    when 0x07  # SM_CXDLGFRAME (对话框边框宽度)
      return 8
    when 0x08  # SM_CYDLGFRAME (对话框边框高度)
      return 8
    when 0x00  # SM_CXSCREEN (屏幕宽度)
      return 1920
    when 0x01  # SM_CYSCREEN (屏幕高度)
      return 1080
    else
      return 0
    end
  end
end

class Win32API_Impl::User32::SystemParametersInfo
  def call(args)
    action, param, pv_param, win_ini = args
    
    case action
    when 0x30  # SPI_GETWORKAREA (获取工作区域)
      if pv_param
        # 返回桌面工作区域 (left, top, right, bottom)
        work_area = [0, 0, 1920, 1040].pack('l4')  # 减去任务栏高度
        Win32API_Impl::User32_Helper::memcpy_string(pv_param, work_area)
        return 1
      end
    end
    
    return 0
  end
end

class Win32API_Impl::User32::GetForegroundWindow
  def call(args)
    return 42  # 返回前台窗口句柄（与FindWindow返回的相同）
  end
end