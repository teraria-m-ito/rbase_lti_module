module LTI
  class LTIOidcLogin
    @db = nil
    @cache = nil
    @cookie = nil


    def tool_host
      (Thread.current[:request].headers["HTTP_X_FORWARDED_PROTO"] ? "#{Thread.current[:request].headers["HTTP_X_FORWARDED_PROTO"]}://" : Thread.current[:request].protocol) + "#{Thread.current[:request].host}"
    end

    def initialize(database, cache = nil, cookie = nil)
      @db = database
      
      if cache.nil?
        cache = ::LTI::Cache.new
      end
      @cache = cache
      
      if cookie.nil?
        cookie = ::LTI::CookieStore.new
      end
      
      @cookie = cookie
    end
    
    def self.instance(database, cache = nil, cookie = nil)
      ::LTI::LTIOidcLogin.new(database, cache, cookie)
    end
    
    def do_oidc_login_redirect(launch_url, params = nil)
      if params.nil?
        params = Thread.current[:request].params
      end
      
      if launch_url.blank?
        raise ::LTI::Exception.new("No launch URL configured.")
      end
      
      # Validate Request Data.
      registration = validate_oidc_login(params)
      
      # Build OIDC Auth Response.
      # Generate State.
      # Set cookie (short lived)
      state = "state-#{SecureRandom.alphanumeric(13).downcase}"
      @cookie.set_state(state)
      @cookie.set_cookie("lti1p3_#{state}", state)
      
      # Generate Nonce.
      nonce = "nonce-#{SecureRandom.alphanumeric(13).downcase}.#{SecureRandom.alphanumeric(9).downcase}"
      begin
        launch_id = JSON.parse(params["lti_message_hint"])["launchid"]
      rescue
        launch_id = Digest::SHA256.hexdigest(
          params["lti_deployment_id"].to_s +
          nonce
        )
      end
      @cache.cache_nonce(nonce, launch_id)
      
      # Build Response.
      auth_params = {
        scope: 'openid',                            # OIDC Scope.
        response_type: 'id_token',                  # OIDC response is always an id token.
        response_mode: 'form_post',                 # OIDC response is always a form post.
        prompt: 'none',                             # Don't prompt user on redirect.
        client_id: registration.get_client_id,      # Registered client id.
        redirect_uri: "#{tool_host}#{launch_url}",  # URL to return to after login.
        state: state,                               # State to identify browser session.
        nonce: nonce,                               # Prevent replay attacks.
        login_hint: params['login_hint']            # Login hint to identify platform session.
      }
      
      # Pass back LTI message hint if we have it.
      unless params['lti_message_hint'].nil?
        auth_params[:lti_message_hint] = params['lti_message_hint']
      end
      
      auth_login_return_url = "#{registration.get_auth_login_url}?#{auth_params.to_query}";

      auth_login_return_url
      # Return auth redirect.
      # ::LTI::Redirect.new(auth_login_return_url, params)
    end

    protected
    def validate_oidc_login(params)
      # Validate Issuer.
      if params['iss'].nil?
        raise ::LTI::Exception.new("Could not find issuer.")
      end
      
      # Validate Login Hint.
      if params['login_hint'].nil?
        raise ::LTI::Exception.new("Could not find login hint.")
      end
      
      # Fetch Registration Details.
      # registration = @db.find_registration_by_issuer(params['iss'])
      registration = @db.find_registration_by_issuer_and_client_id(params['iss'], params['client_id'])
      
      # Check we got something（LTIDatabase は未ヒット時に false を返していたため unless で判定）
      unless registration
        raise ::LTI::Exception.new("Could not find registration details.")
      end
      
      # Return Registration.
      registration
    end
  end
end