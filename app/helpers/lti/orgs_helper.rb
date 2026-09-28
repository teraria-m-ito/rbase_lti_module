module Lti
  module OrgsHelper
    
    def display_institution(org)
      org.parent_org.try(:org_name)
    end
    
  end
end
