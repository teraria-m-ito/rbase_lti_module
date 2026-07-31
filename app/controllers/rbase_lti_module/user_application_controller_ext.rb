module RbaseLtiModule
  module UserApplicationControllerExt
    def index_with_rbase_lti_modulle
      case @sso_type
      when "saml2" then
        request = OneLogin::RubySaml::Authrequest.new
        redirect_to(request.create(saml_settings), allow_other_host: true)
      end
    end

    def consume_with_rbase_lti_module
      case @sso_type
      when "saml2" then
        response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], {skip_conditions: true})
        response.settings = saml_settings
        iss = nil
        if response.is_valid?
          ActiveRecord::Base.transaction do
            iss_list = SystemSetting.get_multivalue_list(:issue_mapping, Site.first.id)
            iss_list.each do |iss_value|
              if iss_value[:value_div] == response.issuers.to_a.first
                iss = iss_value[:value]
                break
              end
            end

            Rails.logger.info("sign_in nameid:#{response.nameid.downcase}, lms:#{iss}")

            lms_user = ::LmsUser.where(email: response.nameid.downcase)
            lms_user = ::LmsUser.where(username: response.nameid.downcase) unless lms_user.first
            lms_user = lms_user.where(lms: iss) if iss.present?
            lms_user = lms_user.first

            #iss無しで検索
            unless lms_user
              lms_user = ::LmsUser.where(email: response.nameid.downcase)
              lms_user = ::LmsUser.where(username: response.nameid.downcase) unless lms_user.first
              lms_user = lms_user.first
            end

            unless lms_user
              lms_user = ::LmsUser.where(username: response.attributes["username"])
              lms_user = lms_user.where(lms: iss) if iss.present?
              lms_user = lms_user.first
            end

            #iss無しで検索
            unless lms_user
              lms_user = ::LmsUser.where(username: response.attributes["username"])
              lms_user = lms_user.first
            end

            unless lms_user
              lms_user = ::LmsUser.new
              lms_user.username = response.attributes["username"]
              lms_user.name = "#{response.attributes["lastName"]} #{response.attributes["firstName"]}"
              lms_user.given_name = response.attributes["firstName"]
              lms_user.family_name = response.attributes["lastName"]
              lms_user.email = response.attributes["email"]
              lms_user.lms = iss

              lms_user.role = "STUDENT"

              site = Site.first
              lms_user.site_ids = [site.id]
              lms_user.save!
            end

            # 対象がMOODLEの場合、ユーザ情報を取得する
            logic = nil
            ::Rails.logger.info("[lms_logic]lms_type:#{::Logic::MoodleLogic.get_lms_type(lms_user.lms)}")
            if ::Logic::MoodleLogic.get_lms_type(lms_user.lms) == "MOODLE"
              logic = ::Logic::MoodleLogic.new
              user_info = logic.get_user_info(lms_user).try(:first)

              ::Rails.logger.info("[lms_logic]user_info:#{user_info}")
              if user_info
                department = user_info["department"]
                if department.present?
                  lti_dept_org = ::LTIOrg.where(org_name: department).first
                  if lti_dept_org
                    lms_user.lti_org_id = lti_dept_org.id
                    lms_user.dept_org_id = lti_dept_org.id
                    lms_user.inst_org_id = lti_dept_org.parent_org_id
                  end
                end

                #カスタムフィールの設定
                customfields = user_info["customfields"] || []
                customfields.each do |customfield|
                  if lti_field_name = ::Logic::MoodleLogic.get_lms_field_type(customfield["shortname"])
                    lms_user.send("#{lti_field_name}=", customfield["value"])
                  end
                end
                lms_user.save!
              end
            end

            admin_user = AdminUser.where(email: lms_user.email).first
            admin_user = lms_user.create_admin_user unless admin_user
            if lms_user.admin_user.try(:id) != admin_user.id
              lms_user.admin_user = admin_user
              lms_user.save!
            end

            if lms_user.admin_user.try(:name) != lms_user.username
              admin_user.name = lms_user.username
              admin_user.save!
            end


            if response.settings.idp_entity_id and response.sessionindex
              admin_user.login_from = response.settings.idp_entity_id
              admin_user.sso_session_id = response.sessionindex
              admin_user.save!
            end

            if current_admin_user and current_admin_user.id != admin_user.id
              sign_out(current_admin_user)
            end

            # ログイン処理を実行
            sign_in(admin_user) unless current_admin_user

            # LTIログインセッションを設定
            session[:current_lms_user] = ::LmsUser.where(admin_user_id: current_admin_user.id).first
            session[:launch_url] = session[:direct_url].to_s.split("?")[0]
            # set_login
            current_admin_user.selected_site = current_admin_user.sites.first.id

            sign_in(admin_user) unless current_admin_user
            flash[:notice] = t("devise.sessions.signed_in")

            # authorize_success, log the user
            # session[:userid] = response.nameid
            # session[:attributes] = response.attributes
          end
        else
          flash[:notice] = t("views.common.fail_login_message")
          raise "[SAML] invalid response errors=#{response.errors.inspect}"
          # authorize_failure  # This method shows an error message
          # List of errors is available in response.errors array
        end

        redirect_to root_path, status: :see_other
        # if session[:direct_url]
        #   redirect_to session[:direct_url], status: :see_other
        # else
        #   redirect_to root_path, status: :see_other
        # end
      end
    end

    private
    def admin_users_sso_login_form_param
      params.require(:admin_users_sso_login_form).permit!
    end
  end
end