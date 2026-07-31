module LTI
  class Cookie
    def get_cookie(name)
      cookie = Thread.current[:request].cookies

      unless cookie[name].nil?
        return cookie[name]
      end
      
      # Look for backup cookie if same site is not supported by the user's browser.
      unless cookie["LEGACY_#{name}"].nil?
        return cookie["LEGACY_#{name}"]
      end
      
      false
    end

    def set_cookie(name, value, exp = 3600, options = {})
      cookie_options = {
        expires: exp.second
      }
      
      same_site_options = {
        samesite: 'None',
        secure: true
      }
      
      cookie = Thread.current[:request].cookies
      cookie[name] = {value: value}.merge(cookie_options).merge(same_site_options)
      
      # Set a second fallback cookie in the event that "SameSite" is not supported
      cookie["LEGACY_#{name}"] = {value: value}.merge(cookie_options).merge(same_site_options)

      self
    end
  end
end