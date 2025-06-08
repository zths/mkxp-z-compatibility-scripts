# encoding:utf-8
# win32_wrap.rb
# Author: Ancurio (2014)
# https://github.com/Ancurio/mkxp/issues/73
# https://pastebin.com/zXW1hdrx

# Creative Commons CC0: To the extent possible under law, Ancurio has waived
# all copyright and related or neighboring rights to win32_wrap.rb.
# https://creativecommons.org/publicdomain/zero/1.0/

# Edits by Splendide Imaginarius (2023-2024) also CC0.

# This preload script provides a subset of Win32API in a cross-platform way, so
# you can play Win32API-based games on Linux and macOS.

# To tweak behavior, you can set the following Win32API class constants in an
# earlier preload script (these are usually only helpful for debugging):
#
# NATIVE_ON_WINDOWS=false
# TOLERATE_ERRORS=false
# LOG_NATIVE=true


module Win32API_Impl
end

class Win32API
  NATIVE_ON_WINDOWS = true unless const_defined?("NATIVE_ON_WINDOWS")
  TOLERATE_ERRORS = true unless const_defined?("TOLERATE_ERRORS")
  LOG_NATIVE = false unless const_defined?("LOG_NATIVE")
  
  # ObjectSpace::WeakMap 在 Ruby 2.0 中引入，为较旧版本提供 Hash 替代
  if RUBY_VERSION.split('.')[0].to_i >= 2 && defined?(ObjectSpace::WeakMap)
    @@_mkxp_called_map = ObjectSpace::WeakMap.new
  else
    @@_mkxp_called_map = {}
  end

  alias_method :mkxp_native_initialize, :initialize

  def initialize(dll, func, *args)
    @dll = dll
    @func = func
    @called = false

    # 确保 dll 和 func 是字符串，防止传入非字符串参数导致错误
    dll_str = dll.to_s
    func_str = func.to_s
    
    dll = kappatalize(dll_str.chomp(".dll"))
    func = kappatalize(func_str)

    if !System.is_windows? or !NATIVE_ON_WINDOWS
      dll_name = File.basename(dll)
      dll_name = dll_name.sub(/\.dll\z/i, '')
      dll_name = kappatalize(dll_name)
      if Win32API_Impl.const_defined?(dll_name)
        dll_impl = Win32API_Impl.const_get(dll_name)
        if dll_impl.const_defined?(func)
          @mkxp_wrap_impl = dll_impl.const_get(func).new
          return
        end
      end
    end

    @mkxp_native_available = false
    begin
      mkxp_native_initialize(@dll, @func, *args)
      @mkxp_native_available = true
      return
    rescue
    end

  end

  def kappatalize(str)
    str = str.to_s.dup
    return str if str.empty?
    
    # Ruby 1.8 兼容性：str[0] 在 1.8 中返回整数，在 1.9+ 中返回字符串
    if RUBY_VERSION.split('.')[0].to_i >= 2 || 
       (RUBY_VERSION.split('.')[0].to_i == 1 && RUBY_VERSION.split('.')[1].to_i >= 9)
      # Ruby 1.9+: str[0] 返回字符串
      str[0] = str[0].upcase
    else
      # Ruby 1.8: str[0] 返回整数，转为字符后大写再赋值
      char_code = str[0]
      upper_char = char_code.chr.upcase
      str[0] = upper_char[0]  # 在Ruby 1.8中，字符串[0]返回整数
    end
    return str
  end

  alias_method :mkxp_native_call, :call

  def call(*args)
    if @mkxp_wrap_impl
      return @mkxp_wrap_impl.call(args)
    end

    if @mkxp_native_available
      if LOG_NATIVE
        System.puts("[Win32API] [#{@dll}:#{@func}] #{args.to_s}")
      end
      return mkxp_native_call(*args)
    end

    if TOLERATE_ERRORS
      System.puts("[Win32API] [#{@dll}:#{@func}] #{args.to_s}") if !@called
      @called = true
      return 0
    else
      raise RuntimeError, "[Win32API] [#{@dll}:#{@func}] #{args.to_s}"
    end
  end
end
