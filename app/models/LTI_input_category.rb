class LTIInputCategory < ApplicationRecord
  self.table_name = "lti_input_categories"

  stampable

  has_many :lti_input_category_lti_orgs, class_name: "::LTIInputCategoryLtiOrg", foreign_key: "lti_input_category_id", dependent: :destroy
  has_many :lti_orgs, class_name: "::LTIOrg", through: :lti_input_category_lti_orgs

  scope :display_order, -> { order(:display_order) }
end
