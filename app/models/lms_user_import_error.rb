class LmsUserImportError < ApplicationRecord

  belongs_to :lms_user_import, class_name: '::LmsUserImport'
  
end
