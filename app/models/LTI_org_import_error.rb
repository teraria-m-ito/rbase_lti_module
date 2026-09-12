class LTIOrgImportError < ApplicationRecord
  self.table_name = "lti_org_import_errors"
  belongs_to :lti_org_import, class_name: '::LTIOrgImport'
end
