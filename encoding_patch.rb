# encoding:utf-8
# encoding_patch.rb
# 编码兼容性补丁

class String
  # 保存原始的encode方法（如果存在）
  if method_defined?(:encode)
    alias_method :original_encode, :encode

    # 重新定义encode方法，增加错误处理
    def encode(*args)
      begin
        # 尝试调用原始的encode方法
        original_encode(*args)
      rescue => e
        self
      end
    end
  end
  if method_defined?(:force_encode)
    alias_method :original_force_encode, :force_encode
    def force_encode(*args)
      begin
        # 尝试调用原始的encode方法
        original_force_encode(*args)
      rescue => e
        self
      end
    end
  end
end