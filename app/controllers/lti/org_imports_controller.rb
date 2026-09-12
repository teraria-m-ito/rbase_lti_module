module Lti
  class OrgImportsController < CustomUserApplicationController
    include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
    respond_to :html

    before_action :set_lti_org_import, only: [:edit]

    def new
      @lti_org_import = ::LTIOrgImport.new
      set_unique_key
      @stimulus_params = {
        url1: lti_org_imports_org_import_attachments_path,
        url2: lti_orgs_path,
        confirm_message: I18n.t(:"views.common.upload_confirm_message")
      }.to_json
    end

    def create
      ActiveRecord::Base.transaction do
        @lti_org_import = ::LTIOrgImport.new(lti_org_import_params)

        lti_org_import_attachement = ::LTIOrgImportAttachment.where(token: @lti_org_import.uuid).first

        set_unique_key
        @stimulus_params = {
          url1: lti_org_imports_org_import_attachments_path,
          url2: lti_orgs_path,
          confirm_message: I18n.t(:"views.common.upload_confirm_message")
        }.to_json

        if lti_org_import_attachement.nil?
          @lti_org_import.errors.add(:base, I18n.t(:"activerecord.errors.messages.attachement_file_invalid"))
          render :new, status: :unprocessable_entity
        else
          @lti_org_import.build_lti_org_import_attachments if @lti_org_import.lti_org_import_attachments.nil?
          @lti_org_import.lti_org_import_attachments << lti_org_import_attachement
          @lti_org_import.current_admin_user = current_admin_user
          @lti_org_import.save!

          import_history = LTIImportHistory.new
          import_history.target = @lti_org_import
          import_history.current_admin_user = current_admin_user
          import_history.save!

          result = ::LTI::LtiOrgImportJob.perform_later(@lti_org_import.id)

          import_history.provider_job_id = result.instance_of?(Integer) ? result : result.provider_job_id
          import_history.save!

          flash[:notice] = "#{t('views.common.upload_complete_message')}"
          redirect_to lti_orgs_path(clear: true)
        end
      end
    end

    desc :auth_as => :other, :display_name => 'lti_org_imports_download'
    def download
      condition = session[:lti_orgs_search_conditions] || ::LTI::Orgs::SearchConditions.new
      data = ::LTIOrgImport.build_data(condition)
      xlsx = ::LTIOrgImport.generate_xlsx(data)
      send_data(xlsx.to_stream.read,
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                filename: "組織.xlsx")
    end

    private
    def set_unique_key
      @lti_org_import.set_unique_key
    end

    def set_lti_org_import
      @lti_org_import = ::LTIOrgImport.find(params[:id])
    end

    def lti_org_import_params
      params.require(:lti_org_import).permit!
    end
  end
end
