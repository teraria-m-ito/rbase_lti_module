class LTICache < ApplicationRecord
  self.table_name = "lti_caches"

  include ::SelectableAttr::Base

  validates :nonce, presence: true

end
