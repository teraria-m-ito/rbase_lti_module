module LTI
  class MessageValidator
    def can_validate?(jwt_body)
      false
    end
    
    def validate(jwt_body)
      false
    end
  end
end