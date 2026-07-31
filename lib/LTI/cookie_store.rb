module LTI
  require 'openssl'
  require 'base64'
  class CookieStore
    @@cookie_state = {}
    @state = nil
    
    def set_state(state)
      @@cookie_state[state] = {} if @@cookie_state[state].nil?
      @state = state
    end

    def get_cookie(name)
      return false if @state.nil?
      
      cookie = @@cookie_state[@state]

      unless cookie[name].nil?
        return cookie[name]
      end
      
      # Look for backup cookie if same site is not supported by the user's browser.
      unless cookie["LEGACY_#{name}"].nil?
        return cookie["LEGACY_#{name}"]
      end
      
      false
    end

    def set_cookie(name, value)
      return false if @state.nil?

      cookie = @@cookie_state[@state]

      cookie[name] = value
      
      # Set a second fallback cookie in the event that "SameSite" is not supported
      cookie["LEGACY_#{name}"] = value

      self
    end
    
    def clear_cookie(state)
      @@cookie_state.delete(state)
    end
    
    PASSWORD="CHANGE_ME"
    def aes_encrypt(plain_text, bit)
      password = PASSWORD
      # salt を生成
      salt = OpenSSL::Random.random_bytes(8)

      # 暗号器を作成
      enc = OpenSSL::Cipher::AES.new(bit, :CBC)
      enc.encrypt

      # パスワードと salt をもとに鍵と iv を生成し、設定
      key_iv = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, 2000, enc.key_len + enc.iv_len, 'sha256')
      enc.key = key_iv[0, enc.key_len]
      enc.iv = key_iv[enc.key_len, enc.iv_len]

      # 文字列を暗号化
      encrypted_text = enc.update(plain_text.to_s) + enc.final

      # Base64 エンコード
      encrypted_text = Base64.encode64(encrypted_text).chomp
      salt = Base64.encode64(salt).chomp

      [encrypted_text, salt]
    end
    
    def aes_decrypt(encrypted_text, salt, bit)
      password = PASSWORD
      # Base64 デコード
      encrypted_text = Base64.decode64(encrypted_text)
      salt = Base64.decode64(salt)

      # 復号器を生成
      dec = OpenSSL::Cipher::AES.new(bit, :CBC)
      dec.decrypt

      # パスワードと salt をもとに鍵と iv を生成し、設定
      key_iv = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, 2000, dec.key_len + dec.iv_len, 'sha256')
      dec.key = key_iv[0, dec.key_len]
      dec.iv = key_iv[dec.key_len, dec.iv_len]

      # 復号
      dec.update(encrypted_text) + dec.final
    end
  end
end