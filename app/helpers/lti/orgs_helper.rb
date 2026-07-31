module Lti
  module OrgsHelper
    
    def display_institution(org)
      org.parent_org.try(:org_name)
    end
 
    def set_disabled_when_top(instance)
      instance.display_order <= 1 ? "disabled" : ""
    end
    
    def set_disabled_when_bottom(instance)
      lti_input_categories = ::LTIInputCategory.display_order.all
      max_display_order = lti_input_categories.map(&:display_order).try(:max).to_i
      
      instance.display_order == max_display_order ? "disabled" : ""
    end
    
  end
end
