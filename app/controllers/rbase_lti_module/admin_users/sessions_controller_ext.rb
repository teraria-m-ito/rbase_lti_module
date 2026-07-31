module RbaseLtiModule
  module AdminUsers
    module SessionsControllerExt
      include ::Lti::OperationLogCreation

      def after_sign_in_path_for_with_rbase_lti_module(resource)
        if current_admin_user && session[:current_lms_user].blank?
          lms_user = ::LmsUser.where(admin_user_id: current_admin_user.id).first
          session[:current_lms_user] = lms_user if lms_user
        end
        create_view_operation(:common, nil, I18n.t(:"views.lti.common.operation_log.sign_in.title"))
        after_sign_in_path_for_without_rbase_lti_module(resource)
      end

      def destroy_with_rbase_lti_module
        create_view_operation(:common, nil, I18n.t(:"views.lti.common.operation_log.sign_out.title"))
        destroy_without_rbase_lti_module
        session[:current_lms_user] = nil
      end
    end
  end
end