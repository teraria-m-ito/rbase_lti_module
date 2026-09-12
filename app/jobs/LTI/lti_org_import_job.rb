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
    end
  end
end
