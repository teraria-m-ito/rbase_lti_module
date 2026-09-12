class LTIOrgImportAttachment < ApplicationRecord
  self.table_name = "lti_org_import_attachments"

  mount_uploader :document, DocumentUploader

  belongs_to :lti_org_import, class_name: '::LTIOrgImport', foreign_key: 'lti_org_import_id', optional: true

  def to_jq_upload
    {
      "name" => document.filename,
      "size" => document.size,
      "url" => document.url,
      "delete_url" => "/lti/org_imports/#{id}",
      "delete_type" => "DELETE"
    }
  end
end
