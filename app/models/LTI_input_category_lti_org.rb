class LTIInputCategoryLtiOrg < ApplicationRecord
  self.table_name = "lti_input_category_lti_orgs"

  belongs_to :lti_input_category, class_name: "::LTIInputCategory", optional: true
  belongs_to :lti_org, class_name: "::LTIOrg", optional: true
end
