# -*- coding: utf-8 -*-
module RbaseLtiModule
  module ApplicationHelperExt
    extend ActiveSupport::Concern

    def self.included(mod)
      mod.module_eval do
        def current_lms_user
          session[:current_lms_user]
        end

        def render_aside_with_rbase_lti_module
          render "common/aside_custom"
        end

        # LTI 経由（iframe / lti_ctx / launch セッション）では「閉じる」を出さない。
        # Turbo 等の fetch では Sec-Fetch-Dest が iframe にならないため、一度判定したらセッションに保持する。
        # 最上位の document ナビゲーションかつ LTI 文脈が無いときだけ解除する。
        def hide_canvas_admin_top_menu_close_button?
          dest = request.get_header("HTTP_SEC_FETCH_DEST").to_s
          mode = request.get_header("HTTP_SEC_FETCH_MODE").to_s
          via_lti = params[:lti_ctx].present? || dest == "iframe" || session[:launch_data].present?
          if via_lti
            session[:canvas_admin_embedded_ui] = true
          elsif dest == "document" && mode == "navigate"
            session.delete(:canvas_admin_embedded_ui)
          end
          session[:canvas_admin_embedded_ui].present?
        end

        def custom_field_input_else_field_type_with_rbase_lti_module(form, options={})
          case form.object.custom_field.field_type
          when "institution"
            institutions = ::LTIOrg.where(org_div: ::LTIOrg.org_div_id_by_key(:institution)).order(:org_cd).all
            options.update({as: :select, collection: institutions.map{|x|[x.org_name, x.id]}, input_html: {class: "select_institution"}})
          when "department"
            departments = ::LTIOrg.where(org_div: ::LTIOrg.org_div_id_by_key(:department)).order(:org_cd).all
            options.update({as: :select, collection: departments.map{|x|[x.org_name, x.id, data: { parent_org_id: x.parent_org_id }]}, input_html: {class: "select_department"}})
          end
        end
      end
    end
  end
end
