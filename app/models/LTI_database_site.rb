class LTIDatabaseSite < ApplicationRecord
  self.table_name = "lti_database_sites"

  belongs_to :lti_database, class_name: 'LTIDatabase', optional: true
  belongs_to :site, optional: true

end
