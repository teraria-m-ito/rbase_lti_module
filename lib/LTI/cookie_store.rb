module LTI
  require 'openssl'
  require 'base64'
  # OIDC の state ごとの値を保持する。
  # login と launch が別プロセスで処理されても参照できるようプロセス外（ファイル）に置き、期限切れで自動的に消す。
  # Rails.cache は開発環境で null_store になり得るため専用のストアを使う。
  class CookieStore
    EXPIRES_IN = 10.minutes

    def self.store
      @store ||= ::ActiveSupport::Cache::FileStore.new(::Rails.root.join("tmp", "cache", "lti_state"))
    end

    def set_state(state)
      @state = state
    end

    def get_cookie(name)
      return false if @state.blank?

      value = read_values[name]
      value.nil? ? false : value
    end

    def set_cookie(name, value)
      return false if @state.blank?

      values = read_values
      values[name] = value
      self.class.store.write(cache_key(@state), values, expires_in: EXPIRES_IN)

      self
    end

    def clear_cookie(state)
      self.class.store.delete(cache_key(state))
    end

    private

    def read_values
      self.class.store.read(cache_key(@state)) || {}
    end

    def cache_key(state)
      "lti_state/#{::Digest::SHA256.hexdigest(state.to_s)}"
    end

    public
    
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