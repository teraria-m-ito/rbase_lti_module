module Lti
  class OrgImportAttachmentsController < CustomUserApplicationController
    respond_to :html

    def create
      @lti_org_import = ::LTIOrgImport.new(lti_org_import_params)
      attachment_document = @lti_org_import.lti_org_import_attachments[0].document

      ::LTIOrgImportAttachment.transaction do
        @lti_org_import.lti_org_import_attachments[0].token = @lti_org_import.uuid
        @lti_org_import.lti_org_import_attachments[0].filename = attachment_document.filename
        @lti_org_import.lti_org_import_attachments[0].file_size = attachment_document.size

        @lti_org_import.lti_org_import_attachments[0].save!
      end
      render json: {}, status: :created
    end

    private
    def lti_org_import_params
      params.require(:lti_org_import).permit!
    end
  end
end
