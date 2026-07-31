module LTI
  module MessageValidators
    class DeepLinkMessageValidator < ::LTI::MessageValidator
      def can_validate?(jwt_body)
        jwt_body['https://purl.imsglobal.org/spec/lti/claim/message_type'] == 'LtiDeepLinkingRequest'
      end
      
      def validate(jwt_body)
        if jwt_body['sub'].nil?
          raise ::LTI::Exception.new("Must have a user (sub).").nil?
        end
        
        if jwt_body['https://purl.imsglobal.org/spec/lti/claim/version'] != '1.3.0'
          raise ::LTI::Exception.new("Incorrect version, expected 1.3.0")
        end
        
        if jwt_body['https://purl.imsglobal.org/spec/lti/claim/roles'].nil?
          raise ::LTI::Exception.new("Missing Roles Claim.")
        end
        
        if jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings'].nil?
          raise ::LTI::Exception.new("Missing Deep Linking Settings.")
        end

        deep_link_settings = jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']
        
        if deep_link_settings['deep_link_return_url'].nil?
          raise ::LTI::Exception.new("Missing Deep Linking Return URL.")
        end

        if deep_link_settings['accept_types'].nil? || !deep_link_settings['accept_types'].include?('ltiResourceLink')
          raise ::LTI::Exception.new("Must support resource link placement types.")
        end

        if deep_link_settings['accept_presentation_document_targets'].nil?
          raise ::LTI::Exception.new("Must support a presentation type.")
        end
        
        true
      end
    end
  end
end