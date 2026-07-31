require 'active_support/configurable'

module LTI
  class Redirect
    
    include ActiveSupport::Configurable
    prepend ::ActionController::Redirecting
    
    @location = nil
    @referer_query = nil
    CAN_302_COOKIE = 'LTI1p3_302_Redirect';

    def initialize(location, referer_query = nil)
      @location = location
      @referer_query = referer_query
    end

    def do_redirect
      query = @referer_query.nil? ? "" : "&#{@referer_query.to_query}"
      redirect_to "#{@location}#{query}"
    end

    def do_hybrid_redirect(cookie = nil)
      if cookie.nil?
        cookie = ::LTI::Cookie.new
      end
      
      if cookie.get_cookie(CAN_302_COOKIE).nil?
        return do_redirect
      end
      
      cookie.set_cookie(CAN_302_COOKIE, true)
      do_js_redirect
    end

    def get_redirect_url
      @location
    end

    def do_js_redirect
      result = <<-EOS
        <a id="try-again" target="_blank">If you are not automatically redirected, click here to continue</a>
        <script>

        document.getElementById('try-again').href=<?php
        if (empty($this->referer_query)) {
            echo 'window.location.href';
         } else {
            echo "window.location.origin + window.location.pathname + '?" . $this->referer_query . "'";
        }
        ?>;

        var canAccessCookies = function() {
            if (!navigator.cookieEnabled) {
                // We don't have access
                return false;
            }
            // Firefox returns true even if we don't actually have access
            try {
                if (!document.cookie || document.cookie == "" || document.cookie.indexOf('<?php echo self::$CAN_302_COOKIE; ?>') === -1) {
                    return false;
                }
            } catch (e) {
                return false;
            }
            return true;
        };

        if (canAccessCookies()) {
            // We have access, continue with redirect
            window.location = '<?php echo $this->location ?>';
        } else {
            // We don't have access, reopen flow in a new window.
            var opened = window.open(document.getElementById('try-again').href, '_blank');
            if (opened) {
                document.getElementById('try-again').innerText = "New window opened, click to reopen";
            } else {
                document.getElementById('try-again').innerText = "Popup blocked, click to open in a new window";
            }
        }

        </script>
EOS
      result
    end
  end
end