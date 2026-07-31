require "digest"
require 'securerandom'

module LTI
  class LTIDeepLink
    @registration = nil
    @deployment_id = nil
    @deep_link_settings = nil

    def initialize(registration, deployment_id,deep_link_settings)
      @registration = registration
      @deployment_id = deployment_id
      @deep_link_settings = deep_link_settings
    end

    def get_response_jwt(resources)
      message_jwt = {
            iss: @registration.get_client_id,
            aud: [@registration.get_issuer],
            exp: (Time.now + 600.second).to_i,
            iat: Time.now.to_i,
            nonce: "nonce#{Digest::SHA256.hexdigest(SecureRandom.random_bytes( 64))}",
            "https://purl.imsglobal.org/spec/lti/claim/deployment_id".to_sym => @deployment_id,
            "https://purl.imsglobal.org/spec/lti/claim/message_type".to_sym => "LtiDeepLinkingResponse",
            "https://purl.imsglobal.org/spec/lti/claim/version".to_sym => "1.3.0",
            "https://purl.imsglobal.org/spec/lti-dl/claim/content_items".to_sym => resources.map{|x| x.__to_array},
            "https://purl.imsglobal.org/spec/lti-dl/claim/data".to_sym => @deep_link_settings['data']
      }
      message_jwt
    end
    
    def get_response_jwt(resources)
      message_jwt = {
            iss: @registration.get_client_id,
            aud: [@registration.get_issuer],
            exp: (Time.now + 600.second).to_i,
            iat: Time.now.to_i,
            nonce: "nonce#{Digest::SHA256.hexdigest(SecureRandom.random_bytes(64))}",
            "https://purl.imsglobal.org/spec/lti/claim/deployment_id".to_sym => @deployment_id,
            "https://purl.imsglobal.org/spec/lti/claim/message_type".to_sym => "LtiDeepLinkingResponse",
            "https://purl.imsglobal.org/spec/lti/claim/version".to_sym => "1.3.0",
            "https://purl.imsglobal.org/spec/lti-dl/claim/content_items".to_sym => resources.map{|x| x.__to_array},
            "https://purl.imsglobal.org/spec/lti-dl/claim/data".to_sym => @deep_link_settings['data'],
      }
      rsa_private = OpenSSL::PKey::RSA.new(@registration.get_tool_private_key)

      JWT.encode(message_jwt, rsa_private, 'RS256', kid: @registration.get_kid)
    end
  end
end