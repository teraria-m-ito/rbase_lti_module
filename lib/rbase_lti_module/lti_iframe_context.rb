# frozen_string_literal: true

module RbaseLtiModule
  # 3rd party iframe 等でセッションが維持できない場合、lti_ctx から LmsUser / launch 文脈を復元する
  module LtiIframeContext
    extend ::ActiveSupport::Concern

    included do
      before_action :restore_lti_context_from_lti_ctx_param, prepend: true, if: :lti_ctx_in_request?
    end

    def lti_ctx_in_request?
      params[:lti_ctx].present?
    end

    def default_url_options
      o = (defined?(super) ? super : nil)
      o = o.respond_to?(:to_h) ? o.to_h : {}
      o = o.symbolize_keys
      if params[:lti_ctx].present?
        o = o.merge(lti_ctx: params[:lti_ctx])
      end
      o
    end

    private

    def restore_lti_context_from_lti_ctx_param
      # 本コールバックが prepend により ApplicationController#set_request_filter より先に動くと
      # Thread.current[:request] が未設定のまま AdminUser#selected_site= 等が呼ばれ 500 になる
      ::Thread.current[:request] = request
      data = ::LTI::LaunchContextToken.verify_lti_ctx_param(params[:lti_ctx])
      unless data
        ::Rails.logger.info("LtiIframeContext: invalid or expired lti_ctx")
        return
      end
      unless ::LTICache.exists?(launch_id: data["launch_id"])
        ::Rails.logger.warn("LtiIframeContext: launch_id not in lti_caches: #{data['launch_id']}")
        return
      end
      lms_user = ::LmsUser.find_by(id: data["lms_user_id"])
      unless lms_user
        ::Rails.logger.warn("LtiIframeContext: lms_user not found: #{data['lms_user_id']}")
        return
      end
      admin_user = lms_user.create_admin_user
      if current_admin_user && current_admin_user.id != admin_user.id
        sign_out(current_admin_user)
      end
      sign_in(admin_user) unless current_admin_user
      session[:current_lms_user] = lms_user
      if current_admin_user && current_admin_user.sites.any?
        current_admin_user.selected_site = current_admin_user.sites.first.id
      end
      rebuild_session_launch_data_from_cache(data["launch_id"])
    end

    def rebuild_session_launch_data_from_cache(launch_id)
      launch = ::LTI::LTIMessageLaunch.from_cache(launch_id, ::LTIDatabase.new)
      session[:launch_data] = { launch_id: launch_id }
      if (user_context = launch.get_basic_outcome).present?
        session[:launch_data][:user] = { id: user_context["userid"] }
      end
      if (course_context = launch.get_context).present?
        session[:launch_data][:course] = {
          id: course_context["id"],
          label: course_context["label"]
        }
      end
      if (resource_context = launch.get_resource).present?
        session[:launch_data][:resource] = {
          id: resource_context["id"],
          title: resource_context["title"]
        }
      end
    rescue ::StandardError => e
      ::Rails.logger.warn("LtiIframeContext#rebuild_session_launch_data_from_cache: #{e.class} #{e.message}")
    end
  end
end
