class LmsUserImportAttachment < ApplicationRecord

  mount_uploader :document, DocumentUploader

  belongs_to :lms_user_import, class_name: '::LmsUserImport', foreign_key: 'lms_user_import_id', optional: true
  
  def to_jq_upload
    {
      "name" => document.filename,
      "size" => document.size,
      "url" => document.url,
      "delete_url" => "/lms_users/import/#{id}",
      "delete_type" => "DELETE" 
    }
  end
  
end
