# frozen_string_literal: true

module Lti
  # LTIOperationLog への操作ログ記録（参照／登録更新／削除）
  module OperationLogCreation
    extend ActiveSupport::Concern

    def create_view_operation(from_type, instance, screen_name, description = nil)
      lti_operation_log = ::LTIOperationLog.new
      lti_operation_log.create_view_operation(from_type, instance, screen_name, description)
    end

    def create_saved_operation(from_type, instance, screen_name, description = nil)
      lti_operation_log = ::LTIOperationLog.new
      lti_operation_log.create_saved_operation(from_type, instance, screen_name, description)
    end

    def create_deleted_operation(from_type, instance, screen_name, description = nil)
      lti_operation_log = ::LTIOperationLog.new
      lti_operation_log.create_deleted_operation(from_type, instance, screen_name, description)
    end

    private :create_view_operation, :create_saved_operation, :create_deleted_operation
  end
end
