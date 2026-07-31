# require "tmpdir"
require "json"
require "base64"

module LTI
  class Cache
    @cache = nil

    def get_launch_data(key)
      Rails.logger.info("===========[CACHE]get_launch_data key:#{key}")
      load_cache

      @cache[key]
    end

    def cache_launch_data(key, jwt_body)
      Rails.logger.info("===========[CACHE]cache_launch_data key:#{key}")
      @cache[key] = jwt_body
      save_cache(@cache["nonce"].keys.first)

      self
    end

    def cache_nonce(nonce, launch_id = nil)
      Rails.logger.info("===========[CACHE]cache_nonce:#{nonce}")
      load_cache(nonce)

      @cache['nonce'] = {} if @cache['nonce'].nil?
      @cache['nonce'][nonce] = true
      save_cache(nonce, launch_id)

      self
    end

    def restore_nonce(nonce)
      Rails.logger.info("===========[CACHE]cache_nonce:#{nonce}")
      load_cache(nonce)

      @cache['nonce'] = {} if @cache['nonce'].nil?
      @cache['nonce'][nonce] = true
      self
    end

    def check_nonce(nonce)
      Rails.logger.info("===========[CACHE]check_nonce:#{nonce}")
      load_cache(nonce)

      if @cache['nonce'][nonce].nil?
        return false
      end
      true
    end

    def get_cache
      @cache
    end

    def remove_cache(nonce)
      Rails.logger.info("===========[CACHE]remove_cache:#{nonce}")
      cache = ::LTICache.where(nonce: nonce).first
      cache.destroy! if cache
    end

    private
    def load_cache(nonce = nil)
      Rails.logger.info("===========[CACHE]load_cache:#{nonce}")
      unless @cache
        cache = ::LTICache.where(nonce: nonce).first
        if cache and cache.data.present?
          decoded = Base64.decode64(cache.data)
        else
          decoded = "{}"
        end
        @cache = ::JSON.parse(decoded)
      else
        Rails.logger.info("===========[CACHE]use:#{@cache}")
      end
    end

    def save_cache(nonce, launch_id = nil)
      launch_id = launch_id || (@cache.keys - ["nonce"]).first
      Rails.logger.info("===========[CACHE]save_cache:#{nonce} / #{launch_id}")
      cache = ::LTICache.where(nonce: nonce).first || ::LTICache.new(nonce: nonce)
      cache.launch_id = launch_id if launch_id
      Rails.logger.info("===========[CACHE]save_cache data:#{::JSON.generate(@cache)}")
      encoded = Base64.strict_encode64(::JSON.generate(@cache))
      cache.data = encoded
      cache.save!
    end
  end
end