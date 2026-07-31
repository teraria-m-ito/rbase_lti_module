require 'securerandom'
require 'openssl'
require 'jwt'
require 'json/jwt'

module LTI
  class LTIMessageLaunch
    @db = nil
    @cache = nil
    @params = nil
    @cookie = nil
    @jwt = nil
    @registration = nil
    @launch_id = nil
    
    def initialize(database, cache = nil, cookie = nil)
      
      @db = database
      
      @cache = cache
      
      @launch_id = "#{SecureRandom.alphanumeric(13).downcase}"

      if cache.nil?
        @cache = ::LTI::Cache.new
      else
        @cache = cache
      end

      if cookie.nil?
        @cookie = ::LTI::CookieStore.new
      else
        @cookie = cookie
      end
      
      @jwt = {}
    end
    
    def self.instance(database, cache = nil, cookie = nil)
      ::LTI::LTIMessageLaunch.new(database, cache, cookie)
    end

    def self.from_cache(launch_id, database, cache = nil)
      unless cache
        lti_cache = ::LTICache.where(launch_id: launch_id).first
        cache = ::LTI::Cache.new
        cache.restore_nonce(lti_cache.nonce)
      end
      new_instance = ::LTI::LTIMessageLaunch.new(database, cache, nil)
      new_instance.instance_variable_set(:@launch_id, launch_id)
      new_instance.instance_variable_set(:@jwt, {'body' => new_instance.instance_variable_get(:@cache).get_launch_data(launch_id)})
      
      new_instance.validate_registration
      
      new_instance
    end

    def validate(params = nil)
      params = Thread.current[:request].params if params.nil?
      
      @params = params
      
      validate_state
      validate_jwt_format
      validate_nonce
      validate_registration
      validate_jwt_signature
      validate_deployment
      validate_message
      cache_launch_data
      
      self
    end

    def set_token(name, value)
      @cookie.set_state(@params['state'])

      enc_value, salt = @cookie.aes_encrypt(value, 128)
      @cookie.set_cookie("token_salt", salt)
      @cookie.set_cookie("token_#{name}", enc_value)
    end

    def has_nrps
      !@jwt['body']['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice']['context_memberships_url'].nil?
    end

    def get_nrps
      service = ::LTI::LTINamesRolesProvisioningService.new(
        ::LTI::LTIServiceConnector.new(@registration),
        @jwt['body']['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice']
      )
      
      service
    end
    
    def has_gs
      !@jwt['body']['https://purl.imsglobal.org/spec/lti-gs/claim/groupsservice']['context_groups_url'].nil?
    end

    def get_gs
      serice = ::LTI::LTICourseGroupsService.new(
        ::LTI::LTIServiceConnector.new(@registration),
        @jwt['body']['https://purl.imsglobal.org/spec/lti-gs/claim/groupsservice']
      
      )
      
      serice
    end
    
    def has_ags
      !@jwt['body']['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint'].nil?
    end

    def get_ags
      service = ::LTI::LTIAssignmentsGradesService.new(
        ::LTI::LTIServiceConnector.new(@registration),
        @jwt['body']['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']
      
      )
      
      service
    end
    
    def get_deep_link
      ::LTI::LTIDeepLink.new(
        @registration,
        @jwt['body']['https://purl.imsglobal.org/spec/lti/claim/deployment_id'],
        @jwt['body']['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']
      )
    end
    
    def is_deep_link_launch
      @jwt['body']['https://purl.imsglobal.org/spec/lti/claim/message_type'] == 'LtiDeepLinkingRequest'
    end
    
    def is_submission_review_launch
      @jwt['body']['https://purl.imsglobal.org/spec/lti/claim/message_type'] == 'LtiSubmissionReviewRequest'
    end
    
    def is_resource_launch
      @jwt['body']['https://purl.imsglobal.org/spec/lti/claim/message_type'] == 'LtiResourceLinkRequest'
    end
    
    def get_launch_data
      @jwt['body']
    end
    
    def get_launch_id
      @launch_id
    end

    def get_context
      @jwt['body']['https://purl.imsglobal.org/spec/lti/claim/context']
    end

    def get_resource
      @jwt['body']['https://purl.imsglobal.org/spec/lti/claim/resource_link']
    end

    def get_endpoint
      @jwt['body']['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']
    end

    def get_deep_link_setting
      @jwt['body']['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']
    end

    def get_basic_outcome
      basic_outcome={}
      lis_result_sourcedid  = @jwt['body']['https://purl.imsglobal.org/spec/lti-bo/claim/basicoutcome']['lis_result_sourcedid'] if @jwt['body']['https://purl.imsglobal.org/spec/lti-bo/claim/basicoutcome']
      if lis_result_sourcedid
        if lis_result_sourcedid.is_a?(String)
          lis_result_sourcedid = JSON.parse(lis_result_sourcedid)
          basic_outcome = lis_result_sourcedid['data']
        else
          basic_outcome = lis_result_sourcedid['data']
        end
      end
      basic_outcome
    end

    private
    def get_public_key
      key_set_url = @registration.get_key_set_url
      
      # Download key set
      begin
        response = Net::HTTP.get_response(URI.parse(key_set_url))

        public_key_set = JSON.parse(response.body)

        # Find key used to sign the JWT (matches the KID in the header)
        public_key_set['keys'].each do |key|
          if key['kid'] == @jwt['header']['kid']
            public_key = ::JSON::JWK.new(key).to_key
            # Todo 本来は、SSL証明書を戻して、戻した先でデコードすることが正しい
            return public_key
          end
        end
      rescue => e
        # Failed to fetch public keyset from URL.
        raise ::LTI::Exception.new("Failed to fetch or vaidate public key:#{e.message}")
        return false
      end
      
      raise ::LTI::Exception.new("Unable to find public key")
    end
    
    def cache_launch_data
      @cache.cache_launch_data(@launch_id, @jwt['body'])
      self
    end

    public
    def validate_state
      # Check State for OIDC.
      @cookie.set_state(@params['state'])
      if @cookie.get_cookie("lti1p3_#{@params['state']}") != @params['state']
        # Error if state doesn't match
        raise ::LTI::Exception.new("State not found.")
      end
    end
    
    def validate_jwt_format
      jwt = @params['id_token']
      
      if jwt.nil?
        raise ::LTI::Exception.new("Missing id_token.")
      end
      
      jwt_parts = jwt.split(".")
      
      if jwt_parts.size != 3
        raise ::LTI::Exception.new("Invalid id_token, JWT must contain 3 parts.")
      end
      
      @jwt['header'] = JSON.parse(Base64.urlsafe_decode64(jwt_parts[0]))
      @jwt['body'] = JSON.parse(Base64.urlsafe_decode64(jwt_parts[1]))
    end

    def validate_nonce
      unless @cache.check_nonce(@jwt['body']['nonce'])
        raise ::LTI::Exception.new("Invalid Nonce.")
      end
    end
    
    def validate_registration
      # Find registration.
      # @registration = @db.find_registration_by_issuer(@jwt['body']['iss'])
      @registration = @db.find_registration_by_issuer_and_client_id(@jwt['body']['iss'], @jwt['body']['aud'])
      
      unless @registration
        raise ::LTI::Exception.new("Registration not found.")
      end
      
      # Check client id.
      if @jwt['body']['aud'].is_a?(Hash)
        client_id = @jwt['body']['aud'][0]
      else
        client_id = @jwt['body']['aud']
      end
      
      if client_id != @registration.get_client_id
        raise ::LTI::Exception.new("Client id not registered for this issuer.")
      end
    end

    def validate_jwt_signature
      # Fetch public key.
      public_key = get_public_key
      
      # Validate JWT signature
      begin
        JWT.decode(@params['id_token'], public_key, true, { algorithm: 'RS256' })
      rescue => e
        raise ::LTI::Exception.new("Invalid signature on id_token.#{e.message}")
      end
    end

    def validate_deployment
      # Find deployment.
      # deployment = @db.find_deployment(@jwt['body']['iss'], @jwt['body']['https://purl.imsglobal.org/spec/lti/claim/deployment_id'])
      deployment = @db.find_deployment_by_iss_and_client_id(@jwt['body']['iss'], @jwt['body']['aud'], @jwt['body']['https://purl.imsglobal.org/spec/lti/claim/deployment_id'])
      
      unless deployment
        raise ::LTI::Exception.new("Unable to find deployment.")
      end
    end
    
    def validate_message
      if @jwt['body']['https://purl.imsglobal.org/spec/lti/claim/message_type'].nil?
        raise ::LTI::Exception.new("Invalid message type.")
      end
      
      validators = [
        ::LTI::MessageValidators::DeepLinkMessageValidator,
        ::LTI::MessageValidators::ResourceMessageValidator,
        ::LTI::MessageValidators::SubmissionReviewMessageValidator
      ]

      message_validator = false
      
      validators.each do |validator|
        instance = validator.new
        
        if instance.can_validate?(@jwt['body'])
          if message_validator != false
            raise ::LTI::Exception.new("Validator conflict.")
          end
          message_validator = instance
        end
      end

      if message_validator == false
        raise ::LTI::Exception.new("Unrecognized message type.")
      end
      
      unless message_validator.validate(@jwt['body'])
        raise ::LTI::Exception.new("Message validation failed.")
      end
    end
  end
end