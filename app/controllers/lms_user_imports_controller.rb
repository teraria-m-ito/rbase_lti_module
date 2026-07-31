class LmsUserImportsController < CustomUserApplicationController
  include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
  respond_to :html

  before_action :set_lms_user_import, only: [:edit]

  def new
    @lms_user_import = ::LmsUserImport.new
    set_unique_key
    @stimulus_params = {
      url1: lms_user_imports_lms_user_import_attachments_path(@lms_user_import),
      url2: lms_users_path,
      confirm_message: I18n.t(:"views.common.upload_confirm_message")
    }.to_json
  end

  def create
    ActiveRecord::Base.transaction do
      @lms_user_import = ::LmsUserImport.new(lms_user_import_params)

      lms_user_import_attachement = ::LmsUserImportAttachment.where(token: @lms_user_import.uuid).first

      set_unique_key
      @stimulus_params = {
        url1: lms_user_imports_lms_user_import_attachments_path(@lms_user_import),
        url2: lms_users_path,
        confirm_message: I18n.t(:"views.common.upload_confirm_message")
      }.to_json

      if lms_user_import_attachement.nil?
        @lms_user_import.errors.add(:base, I18n.t(:"activerecord.errors.messages.attachement_file_invalid"))
        render :new, status: :unprocessable_entity
      else
        @lms_user_import.build_lms_user_import_attachments if @lms_user_import.lms_user_import_attachments.nil?
        @lms_user_import.lms_user_import_attachments <<  lms_user_import_attachement
        @lms_user_import.current_admin_user = current_admin_user
        @lms_user_import.save!

        import_history = LTIImportHistory.new
        import_history.target = @lms_user_import
        import_history.current_admin_user = current_admin_user
        import_history.save!

        # ::LTI::LmsUserImportJob.perform_now(@lms_user_import.id)
        result = ::LTI::LmsUserImportJob.perform_later(@lms_user_import.id)

        import_history.provider_job_id = result.instance_of?(Integer) ? result : result.provider_job_id
        import_history.save!

        flash[:notice] = "#{t('views.common.upload_complete_message')}"
        redirect_to lms_users_path(clear: true)

        # if @lms_user_import.import_csv
        #   flash[:notice] = "#{t('views.common.upload_complete_message')}"
        #   redirect_to lms_users_path(clear: true)
        # else
        #   @lms_user_import.errors.add(:base, I18n.t(:"activerecord.errors.messages.invalid_file_contents"))
        #   @lms_user_import.filename = lms_user_import_attachement.filename
        #   @lms_user_import_errors = @lms_user_import.lms_user_import_errors.to_a
        #   render :new, status: :unprocessable_entity
        # end
      end
    end
  end

  desc :auth_as => :other, :display_name => 'lms_user_imports_download'
  def download
    condition = session[:lms_users_search_conditions] || ::LmsUsers::SearchConditions.new
    condition.current_admin_user = current_admin_user
    data = ::LmsUserImport.build_data(condition)
    xlsx = ::LmsUserImport.generate_xlsx(data)
    send_data(xlsx.to_stream.read,
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              filename: "LMSユーザ.xlsx")
  end

  private
  def set_unique_key
    @lms_user_import.set_unique_key
  end

  def set_lms_user_import
    @lms_user_import = ::LmsUserImport.find(params[:id])
  end

  def lms_user_import_params
    params.require(:lms_user_import).permit!
  end
end

