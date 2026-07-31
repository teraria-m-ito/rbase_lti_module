require "digest"

module LTI
  class LTIRegistration
    @issuer = nil
    @client_id = nil
    @key_set_url = nil
    @auth_token_url = nil
    @auth_login_url = nil
    @auth_server = nil
    @tool_private_key = nil
    @kid = nil
    
    def self.instance
      ::LTI::LTIRegistration.new
    end
    
    def get_issuer
      @issuer
    end
    
    def set_issuer(issuer)
      @issuer = issuer
      
      self
    end
    
    def get_client_id
      @client_id
    end
    
    def set_client_id(client_id)
      @client_id = client_id
      
      self
    end
    
    def get_key_set_url
      @key_set_url
    end
    
    def set_key_set_url(key_set_url)
      @key_set_url = key_set_url
      
      self
    end
    
    def get_auth_token_url
      @auth_token_url
    end
    
    def set_auth_token_url(auth_token_url)
      @auth_token_url = auth_token_url
      
      self
    end
    
    def get_auth_login_url
      @auth_login_url
    end
    
    def set_auth_login_url(auth_login_url)
      @auth_login_url = auth_login_url
      
      self
    end
    
    def get_auth_server
      @auth_server.nil? ? @auth_token_url : @auth_server
    end
    
    def set_auth_server(auth_server)
      @auth_server = auth_server
      
      self
    end
    
    def get_tool_private_key
      @tool_private_key
    end
    
    def set_tool_private_key(tool_private_key)
      @tool_private_key = tool_private_key
      
      self
    end
    
    def get_kid
      if @kid.nil?
        return Digest::SHA256.digest("#{@issuer}#{@client_id}".strip)
      end
      
      @kid
    end
    
    def set_kid(kid)
      @kid = kid
      
      self
    end
  end
end