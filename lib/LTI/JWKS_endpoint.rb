require 'openssl'

module LTI
  class JWKSEndpoint
    @keys = nil
    
    def initialize(keys)
      @keys = keys
    end

    def self.instance(keys)
      ::LTI::JWKSEndpoint.new(keys)
    end
    
    def self.from_issuer(database, issuer)
      registration = database.find_registration_by_issuer(issuer)
      raise ::LTI::Exception.new("Registration not found.") unless registration

      return ::LTI::JWKSEndpoint.new({registration.get_kid => get_tool_private_key})
    end

    def self.from_registration(registration)
      return ::LTI::JWKSEndpoint.new({registration.get_kid => registration.get_tool_private_key})
    end

    def get_public_jwks
      jwks = []
      
      @keys.each do |kid, private_key|
        rsa_private = OpenSSL::PKey::RSA.new(private_key)
        digest  = OpenSSL::Digest::SHA256.new
        
        rsa_public = rsa_private.public_key
        
        # Todo 取得の仕方は、異なるので見直す
        next if rsa_public.e.nil?
        
        components = {
          'kty' => 'RSA',
          'alg' => 'RS256',
          'use' => 'sig',
          'e' => Base64.urlsafe_encode64(encode256(rsa_public.e.to_i)),
          'n' => Base64.urlsafe_encode64(encode256(rsa_public.n.to_i)),
          'kid' => kid,
        }
        
        jwks << components
      end
      
      return {keys: jwks}
    end

    def output_jwks
      get_public_jwks
    end
    
    private
    def encode256(n)
      result = []
      while n > 0
        r = n % 256
        n = (n - r) / 256
        result << r
      end
      result.reverse.pack('C*')
    end
  end
end