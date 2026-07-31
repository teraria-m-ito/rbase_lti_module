module LTI
  class LmsUserImportJob < ApplicationJob
    include ::ActionController

    queue_as :default

    def perform(*args)
      ::Rails.logger.info("[ImportHistoryJob]start..... id:#{args[0]}")

      lms_user_import = ::LmsUserImport.find(args[0])
      admin_user = AdminUser.where(id: lms_user_import.creator_id).first
      lms_user_import.current_admin_user = admin_user
      if lms_user_import.import_csv
        ::Rails.logger.info("[LmsUserImportJob]success")
      else
        ::Rails.logger.info("[LmsUserImportJob]error")
      end
      ::Rails.logger.info("[LmsUserImportJob]finished.....")
    end
  end
end
