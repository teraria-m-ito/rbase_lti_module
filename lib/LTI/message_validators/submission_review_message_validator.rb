module LTI
  module MessageValidators
    class SubmissionReviewMessageValidator < ::LTI::MessageValidator
      def can_validate?(jwt_body)
        jwt_body['https://purl.imsglobal.org/spec/lti/claim/message_type'] == 'LtiSubmissionReviewRequest'
      end
      
      def validate(jwt_body)
        if jwt_body['sub'].nil?
          raise ::LTI::Exception.new("Must have a user (sub)").nil?
        end
        
        if jwt_body['https://purl.imsglobal.org/spec/lti/claim/version'] != '1.3.0'
          raise ::LTI::Exception.new("Incorrect version, expected 1.3.0")
        end

        if jwt_body['https://purl.imsglobal.org/spec/lti/claim/roles'].nil?
          raise ::LTI::Exception.new("Missing Roles Claim.")
        end

        if jwt_body['https://purl.imsglobal.org/spec/lti/claim/resource_link'].nil? && jwt_body['https://purl.imsglobal.org/spec/lti/claim/resource_link']['id'].nil?
          raise ::LTI::Exception.new("Missing Resource Link Id.")
        end
        
        if jwt_body['https://purl.imsglobal.org/spec/lti/claim/for_user'].nil?
          raise ::LTI::Exception.new("Missing For User.")
        end

        true
      end
    end
  end
end