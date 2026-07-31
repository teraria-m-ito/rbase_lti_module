module LTI
  class LTIDeployment
    @deployment_id = nil
    
    def self.instance
      ::LTI::LTIDeployment.new
    end
    
    def get_deployment_id
      @deployment_id
    end
    
    def set_deployment_id(deployment_id)
      @deployment_id = deployment_id
      
      self
    end
  end
end