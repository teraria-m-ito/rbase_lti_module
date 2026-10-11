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
    rescue => e
      # 再試行で同じ失敗を繰り返して「処理中」のまま残らないよう、エラーとして記録して終了する
      ::Rails.logger.error("[LmsUserImportJob]#{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
      ::LmsUserImportError.create!(lms_user_import_id: args[0], line_no: 0, error_message: "#{e.class}: #{e.message}".truncate(255)) if ::LmsUserImport.exists?(args[0])
    end
  end
end
