require 'digest'
require 'jwt'

module LTI
  class LTIServiceConnector
    NEXT_PAGE_REGEX = "/^Link:.*<([^>]*)>; ?rel=\"next\"/i"
    
    @registration = nil
    @access_tokens = nil;

    def initialize(registration)
      @registration = registration
      @access_tokens = {}
    end

    def get_access_token(scopes)
      # Don't fetch the same key more than once.
      scopes = scopes.sort
      
      scope_key = Digest::MD5.hexdigest(scopes.join("|"))
      
      unless @access_tokens[scope_key].nil?
        return @access_tokens[scope_key]
      end
      
      # Build up JWT to exchange for an auth token
      client_id = @registration.get_client_id
      jwt_claim = {
        iss: client_id,
        sub: client_id,
        aud: @registration.get_auth_server,
        iat: (Time.now.- 5.second).to_i,
        exp: (Time.now + 60.second).to_i,
        jti: "lti-service-token#{Digest::SHA256.hexdigest(SecureRandom.alphanumeric(16).downcase)}"
      }
      
      rsa_private = OpenSSL::PKey::RSA.new(@registration.get_tool_private_key)
      # Sign the JWT with our private key (given by the platform on registration)
      jwt = JWT.encode(jwt_claim, rsa_private, 'RS256', kid: @registration.get_kid)
      
      # Build auth token request headers
      auth_request = {
        grant_type: 'client_credentials',
        client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
        client_assertion: jwt,
        scope: scopes.join(" ")
      }
      
      # Make request to get auth token
      uri = URI(@registration.get_auth_token_url)
      
      req = Net::HTTP::Post.new(uri)
      
      req["Content-Type"] = 'application/x-www-form-urlencoded'

      # req.set_form_data(auth_request)
      req.body = auth_request.to_query

      req_options = {
        use_ssl: uri.scheme == "https"
      }

      token_data = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(req)
      end
      
      @access_tokens[scope_key] = JSON.parse(token_data.body)['access_token']
      
      @access_tokens[scope_key]
    end

    def make_service_request(scopes, method, url, body = nil, content_type = 'application/json', accept = 'application/json')
      uri = URI.parse(url)
      if method == 'POST'
        req = Net::HTTP::Post.new(uri)
        if body.is_a?(Hash)
          req.set_form_data(body)
        else
          req.body = body
        end
      else 
        req = Net::HTTP::Get.new(uri)
      end
      req["Authorization"] = "Bearer #{get_access_token(scopes)}"
      req["Accept"] = accept
      req["Content-Type"] = content_type

      req_options = {
        use_ssl: uri.scheme == "https" 
      }
      ::Rails.logger.info("----------request url:#{url}")
      ::Rails.logger.info("----------request body:#{req.body}")

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(req)
      end
      
      resp_headers = {}
      response.each do |name, value|
        resp_headers[name] = value
      end

      ::Rails.logger.info("----------status:#{response.code}")
      response_body = response.body.size > 0 ? JSON.parse(response.body) : nil

      ::Rails.logger.info("----------response body:#{response.body}")

      #レスポンスコードが200以外の場合は、エラーにする
      raise ::LTI::Exception.new("Response code is #{response.code}(expected 200 or 201 or 204) / #{response_body["reason"]}") unless ["200", "201", "204"].include?(response.code) #and response_body.blank?

      return {
        headers: resp_headers,
        body: response_body
      }
    end
  end
end