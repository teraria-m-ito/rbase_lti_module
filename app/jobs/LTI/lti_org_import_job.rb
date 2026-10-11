module LTI
  class LtiOrgImportJob < ApplicationJob
    include ::ActionController

    queue_as :default

    def perform(*args)
      ::Rails.logger.info("[LtiOrgImportJob]start..... id:#{args[0]}")

      lti_org_import = ::LTIOrgImport.find(args[0])
      admin_user = AdminUser.where(id: lti_org_import.creator_id).first
      lti_org_import.current_admin_user = admin_user
      if lti_org_import.import_csv
        ::Rails.logger.info("[LtiOrgImportJob]success")
      else
        ::Rails.logger.info("[LtiOrgImportJob]error")
      end
      ::Rails.logger.info("[LtiOrgImportJob]finished.....")
    rescue => e
      # 再試行で同じ失敗を繰り返して「処理中」のまま残らないよう、エラーとして記録して終了する
      ::Rails.logger.error("[LtiOrgImportJob]#{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
      ::LTIOrgImportError.create!(lti_org_import_id: args[0], line_no: 0, error_message: "#{e.class}: #{e.message}".truncate(255)) if ::LTIOrgImport.exists?(args[0])
    end
  end
end
