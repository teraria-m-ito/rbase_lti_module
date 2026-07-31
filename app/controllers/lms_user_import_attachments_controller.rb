class LmsUserImportAttachmentsController < CustomUserApplicationController
  respond_to :html

  def create
    @lms_user_import = ::LmsUserImport.new(lms_user_import_params)
    attachment_document = @lms_user_import.lms_user_import_attachments[0].document

    ::LmsUserImportAttachment.transaction do
      @lms_user_import.lms_user_import_attachments[0].token = @lms_user_import.uuid
      @lms_user_import.lms_user_import_attachments[0].filename = attachment_document.filename
      @lms_user_import.lms_user_import_attachments[0].file_size = attachment_document.size

      @lms_user_import.lms_user_import_attachments[0].save!
    end
    render json: {}, status: :created
  end

  private
  def lms_user_import_params
    params.require(:lms_user_import).permit!
  end
end

