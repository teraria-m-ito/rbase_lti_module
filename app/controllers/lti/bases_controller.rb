module Lti
  class BasesController < ApplicationController
    include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
    include RbaseLtiModule::LtiIframeContext
    include Lti::OperationLogCreation
    before_action :set_login
    before_action :set_restrict_display
    before_action :redirect_root, except: [:login, :launch]
    before_action :set_page_number
    before_action :set_referrer
    before_action :set_admin_user

    layout "application_lti"

    def login
      oidc = ::LTI::LTIOidcLogin.new(::LTIDatabase.new)

      tool_host = (request.headers["HTTP_X_FORWARDED_PROTO"] ? "#{request.headers["HTTP_X_FORWARDED_PROTO"]}://" : request.protocol) + "#{request.host}"
      launch_url_index = params["target_link_uri"].index(tool_host)
      if launch_url_index == 0
        launch_url = params["target_link_uri"].slice(tool_host.size, params["target_link_uri"].size)
      else
        launch_url = "/launch"
      end
      begin
        auth_login_return_url = oidc.do_oidc_login_redirect(launch_url)
      rescue => e
        Rails.logger.error(e.full_message)
        Rails.logger.error e.backtrace.join("\n")
        return _render_500
      end
      #Todo set_cookieならcookieを作る必要はない？
      # Thread.current[:request].cookies.keys.each do |key|
        # next if key == '_session_id'
        # cookies[key] = Thread.current[:request].cookies[key]
      # end
      redirect_to auth_login_return_url, allow_other_host: true
    end
  
    def launch
      get_launch_date
      process_launch_date
    end

    private
    def get_launch_date
      @launch = ::LTI::LTIMessageLaunch.new(::LTIDatabase.new)
      @launch.validate
      # カスタムパラメータの取得
      custom_params = @launch.get_launch_data["https://purl.imsglobal.org/spec/lti/claim/custom"]
      if custom_params.present?
        session[:lti_custom_params] = custom_params.delete_if{|k, v| ["context_memberships_url" ,"system_setting_url" ,"context_setting_url" ,"link_setting_url"].include?(k)}
      # else
      #   session.delete(:lti_custom_params) if session[:lti_custom_params]
      end
    end

    def process_launch_date
      begin
        ActiveRecord::Base.transaction do
          # カスタムパラメータの取得
          custom_params = @launch.get_launch_data["https://purl.imsglobal.org/spec/lti/claim/custom"]
          if custom_params.present?
            session[:lti_custom_params] = custom_params
          else
            session.delete(:lti_custom_params)
          end

          #Canvasの場合、usernameは連携されないので、emailをユーザ名とする
          lms_user = ::LmsUser.where(email: @launch.get_launch_data['email'].to_s.downcase).where(lms: @launch.get_launch_data['iss']).first

          if @launch.get_launch_data['https://purl.imsglobal.org/spec/lti/claim/ext']
            username = @launch.get_launch_data['https://purl.imsglobal.org/spec/lti/claim/ext']['user_username'].to_s.downcase.split("@")[0]
          else
            username = @launch.get_launch_data['email'].to_s.downcase.split("@")[0].split("@")[0]
          end

          unless lms_user
            lms_user = ::LmsUser.where(username: username).where(lms: @launch.get_launch_data['iss']).first
            lms_user = lms_user || ::LmsUser.where(username: username).first
            lms_user = lms_user || ::LmsUser.new
          end

          lms_user.username = username

          lms_user.name = @launch.get_launch_data['name']
          lms_user.given_name = @launch.get_launch_data['given_name']
          lms_user.family_name = @launch.get_launch_data['family_name']
          lms_user.email = @launch.get_launch_data['email'].to_s.downcase
          lms_user.lms = @launch.get_launch_data['iss']

          Rails.logger.info("launch name:#{lms_user.name}, given_name:#{lms_user.given_name}, family_name:#{lms_user.family_name}, email:#{lms_user.email}, lms:#{lms_user.lms}")
          lti_role = ::LmsUser.select_lti_role(@launch.get_launch_data['https://purl.imsglobal.org/spec/lti/claim/roles'])

          # 外部ツールのカスタムパラメータが設定されている場合は、同設定を優先してロール設定を行う
          if session[:lti_custom_params] and session[:lti_custom_params]["forced_role"]
            role = session[:lti_custom_params]["forced_role"]
            lti_role = ::LmsUser.role_entries.select{|x| x[:id].to_s == role}.first
            lms_user.role = lti_role[:role_name] unless lti_role.nil?
          else
            unless lms_user.role
              lms_user.role = lti_role[:role_name] unless lti_role.nil?
            end
          end

          lti_database = ::LTIDatabase.where(iss: @launch.get_launch_data['iss'], client_id: @launch.get_launch_data['aud']).first

          if lti_database.nil?
            raise ::LTI::Exception.new("LTI Database is not found!")
          end
          site_ids = lti_database.site_ids

          lms_user.site_ids = site_ids
          unless lms_user.valid?
            ::Rails.logger.error("lms_user error!:#{lms_user.errors.full_messages}")
            return _render_500
          end
          lms_user.save!

          user_info = nil
          # 対象がMOODLEの場合、ユーザ情報を取得する
          logic = nil
          if ::Logic::MoodleLogic.get_lms_type(lms_user.lms) == "MOODLE"
            logic = ::Logic::MoodleLogic.new
            user_info = logic.get_user_info(lms_user).try(:first)
            if user_info.is_a?(Array) and user_info[0] == "exception"
              return _render_500
            end
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

          unless lms_user.lms_user_id
            if lms_user.get_lms_type == "MOODLE"
              user_info = ::Logic::MoodleLogic.get_user_info(lms_user).try(:first) unless user_info
              user_id = user_info["id"]
              lms_user.lms_user_id = user_id
              lms_user.save!
            end
          end


          # admin_userの作成
          admin_user = lms_user.create_admin_user
          if lms_user.admin_user.try(:id) != admin_user.id
            lms_user.admin_user = admin_user
            lms_user.save!
          end

          if current_admin_user and current_admin_user.id != admin_user.id
            sign_out(current_admin_user)
          end

          # Todo SSO処理を入れる場合は、ここに記述
          # ログイン処理を実行
          sign_in(admin_user) unless current_admin_user

          # LTIログインセッションを設定
          session[:current_lms_user] = ::LmsUser.where(admin_user_id: current_admin_user.id).first
          # set_login
          current_admin_user.selected_site = current_admin_user.sites.first.id

          @launch.set_token("auth", session[:current_lms_user].id)

          #起動データを保存する
          session[:launch_data] = {}
          session[:launch_data][:launch_id] = @launch.get_launch_id

          user_context = @launch.get_basic_outcome
          if user_context
            session[:launch_data][:user] = {}
            session[:launch_data][:user][:id] = user_context["userid"]
          end
          course_context = @launch.get_context
          if course_context
            session[:launch_data][:course] = {}
            session[:launch_data][:course][:id] = course_context["id"]
            session[:launch_data][:course][:label] = course_context["label"]
          end
          resource_context = @launch.get_resource
          if resource_context
            session[:launch_data][:resource] = {}
            session[:launch_data][:resource][:id] = resource_context["id"]
            session[:launch_data][:resource][:title] = resource_context["title"]
          end

          #キャッシュ削除を廃止
          # cache.remove_cache(nonce)

          #LTIサービス履歴を登録
          cache = @launch.instance_variable_get(:@cache)
          nonce = cache.get_cache.to_h["nonce"].keys.first
          lti_cache = ::LTICache.where(nonce: nonce).first

          user_id = @launch.get_basic_outcome["userid"].to_i
          course_id = @launch.get_context["id"].to_i
          course_name = @launch.get_context["title"]
          resource_id = @launch.get_resource["id"].to_i
          resource_name = @launch.get_resource["title"]

          redir = @launch_url.presence || lti_default_post_launch_path
          redirect_to ::LTI::LaunchContextToken.append_lti_context_to_url(
            redir, lms_user.id, @launch.get_launch_id
          )
        end
      rescue => e
        Rails.logger.error e.full_message
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    def jwks
      name = params['name']
      if name.blank?
        raise ::LTI::Exception.new("Nessary set name!") 
      end

      lti_database = ::LTIDatabase.where(name: name).first
    
      @endpoint = ::LTI::JWKSEndpoint.new({
        lti_database.kid => lti_database.private_key_file
      })
    
      render json: @endpoint.output_jwks
    end
  
    def result_service
      launch = ::LTI::LTIMessageLaunch.from_cache(params['launch_id'], ::LTIDatabase.new)
    
      unless launch.has_nrps
        raise ::LTI::Exception.new("Don't have names and roles!") 
      end
    
      unless launch.has_ags
        raise ::LTI::Exception.new("Don't have grades!") 
      end
    
      ags = launch.get_ags
    
      score_lineitem = ::LTI::LTILineitem.new
        .set_tag('score')
        .set_score_maximum(100)
        .set_label('Score')
        .set_resource_id(launch.get_launch_data['https://purl.imsglobal.org/spec/lti/claim/resource_link']['id'])

      scores = ags.get_grades(score_lineitem)

      time_lineitem = ::LTI::LTILineitem.new
        .set_tag('time')
        .set_score_maximum(999)
        .set_label('Time Taken')
        .set_resource_id("time#{launch.get_launch_data['https://purl.imsglobal.org/spec/lti/claim/resource_link']['id']}")

      times = ags.get_grades(time_lineitem)

      members = launch.get_nrps.get_members

      scoreboards = [];

      target_score = {}
      target_result = {}
    
      scores.to_a.each do |score|
        target_score = score
        target_result = {"userId" => score['userId'], "score" => score['resultScore']}
        times.each do |time|
          if time['userId'] == score['userId']
            target_result['time'] = time['resultScore']
            scoreboards << target_result
            break
          end
        end
      end
    
      members.to_a.each do |member|
        scoreboards.each do |scoreboard|
         if member['user_id'] == scoreboard['userId']
            scoreboard['name'] = member['name']
            break
          end
        end
      end
    
      render :json => scoreboards
    end
  
    def score_service
      launch = ::LTI::LTIMessageLaunch.from_cache(params['launch_id'], ::LTIDatabase.new)

      raise ::LTI::Exception.new("Don't have grades!") unless launch.has_ags
    
      grades = launch.get_ags
    
      score = ::LTI::LTIGrade.new
        .set_score_given(params['score'].to_i)
        .set_score_maximum(100)
        .set_timestamp(DateTime.now.iso8601)
        .set_activity_progress('Completed')
        .set_grading_progress('FullyGraded')
        .set_user_id(launch.get_launch_data['sub'])

      score_lineitem = ::LTI::LTILineitem.new
        .set_tag('score')
        .set_score_maximum(100)
        .set_label('Score')
        .set_resource_id(launch.get_launch_data['https://purl.imsglobal.org/spec/lti/claim/resource_link']['id'])
      
      grades.put_grade(score, score_lineitem)

      time = ::LTI::LTIGrade.new
        .set_score_given(params['time'].to_i)
        .set_score_maximum(999)
        .set_timestamp(DateTime.now.iso8601)
        .set_activity_progress('Completed')
        .set_grading_progress('FullyGraded')
        .set_user_id(launch.get_launch_data['sub'])

      time_lineitem = ::LTI::LTILineitem.new
        .set_tag('time')
        .set_score_maximum(999)
        .set_label('Time Taken')
        .set_resource_id("time#{launch.get_launch_data['https://purl.imsglobal.org/spec/lti/claim/resource_link']['id']}")
      
      grades.put_grade(time, time_lineitem)

      render :json => {:"success" => true}
    end
  
    def configure
      tool_host = request.env["HTTP_X_FORWARDED_PROTO"] ? "#{request.env["HTTP_X_FORWARDED_PROTO"]}://#{request.host}" : "#{request.protocol}#{request.host}"

      launch = ::LTI::LTIMessageLaunch.from_cache(params['launch_id'], ::LTIDatabase.new)

      raise ::LTI::Exception.new("Must be a deep link!") unless launch.is_deep_link_launch

      resource = ::LTI::LTIDeepLinkResource.new
        .set_url("#{tool_host}/launch")
        .set_custom_params({"difficulty" => params["diff"]})
        .set_title("Breakout #{params["diff"]} mode!")
      
      deep_link = launch.get_deep_link
      @deep_link_settings = deep_link.instance_variable_get(:@deep_link_settings)
      @jwt = deep_link.get_response_jwt([resource])
    end

    def current_lms_user
      session[:current_lms_user]
    end
    
    def exception_redirect
      _render_403
    end

    def clear_session_keys(excepted_keys = [])
      keys = session.keys
      keys.each do |key|
        unless excepted_keys.include?(key.to_sym)
          session.delete(key)
        end
      end
    end

    private
    def allow_iframe
      url = ENV["LMS_HOST"] || (current_lms_user.present? ? current_lms_user.lms : "https://lti.example.com")
      response.headers['X-Frame-Options'] = "ALLOW-FROM #{url}"
      response.headers['Content-Security-Policy'] = "frame-ancestors #{url}"
    end
    
    def lti_default_post_launch_path
      root_path
    end

    def set_login
      if params[:state]
        cookie = ::LTI::CookieStore.new
        cookie.set_state(params[:state])
        salt = cookie.get_cookie("token_salt")
        if salt
          encrypted_text = cookie.get_cookie("token_auth")
          lms_user_id = cookie.aes_decrypt(encrypted_text, salt, 128)
          params[:current_lms_user] = lms_user_id
          cookie.clear_cookie(params[:state])
        end
      end

      if params[:current_lms_user]
        lms_user = ::LmsUser.find(params[:current_lms_user])
        session[:current_lms_user] = lms_user
        current_admin_user = lms_user.create_admin_user
        sign_in(current_admin_user)
        current_admin_user.selected_site = current_admin_user.sites.first.id
      else
        if current_admin_user and current_lms_user.blank?
          lms_user = ::LmsUser.where(admin_user_id: current_admin_user.id).first
          session[:current_lms_user] = lms_user
        end
      end
    end

    def set_admin_user
      if session[:current_lms_user].blank? and current_admin_user.present?
        lms_user = ::LmsUser.where(admin_user_id: current_admin_user.id).first
        session[:current_lms_user] = lms_user
      end
    end

    def set_restrict_display
      session[:restrict_display] = params[:restrict_display] if params[:restrict_display]
    end
    
    def set_sort_field
      session[@model_name] = {} if session[@model_name].nil?
      session[@model_name][@sort_field_name] = {} if session[@model_name][@sort_field_name].nil?

      count = (session[@model_name].map{|k, v| session[@model_name][k][:order].to_i}.max || 0) + 1

      case session[@model_name][@sort_field_name][:direction]
      when nil then
        session[@model_name][@sort_field_name][:direction] = :asc
        session[@model_name][@sort_field_name][:order] = count
      when :asc
        session[@model_name][@sort_field_name][:direction] = :desc
        session[@model_name][@sort_field_name][:order] = count
      else
        session[@model_name][@sort_field_name][:direction] = nil
        session[@model_name][@sort_field_name][:order] = nil
      end
      
      session[@model_name] = session[@model_name].sort_by{|k, v| session[@model_name][k][:order].to_i}.select{|x| x[1][:direction].present?}.to_h
      count = 1
      session[@model_name].each do |k, v|
        session[@model_name][k][:order] = count
        count = count + 1
      end
      session[@model_name]
    end

    def set_sort_single_field
      if session[@model_name].nil?
        session[@model_name] = {}
        session.delete(:prev_sort_field_name)
      end
      session[@model_name][@sort_field_name] = {} if session[@model_name][@sort_field_name].nil?

      if session[:prev_sort_field_name] != @sort_field_name
        session[@model_name][session[:prev_sort_field_name]] = {}
      end

      count = (session[@model_name].map{|k, v| session[@model_name][k][:order].to_i}.max || 0) + 1

      case session[@model_name][@sort_field_name][:direction]
      when nil then
        session[@model_name][@sort_field_name][:direction] = :asc
        session[@model_name][@sort_field_name][:order] = count
      when :asc
        session[@model_name][@sort_field_name][:direction] = :desc
        session[@model_name][@sort_field_name][:order] = count
      else
        session[@model_name][@sort_field_name][:direction] = nil
        session[@model_name][@sort_field_name][:order] = nil
      end

      session[@model_name] = session[@model_name].sort_by{|k, v| session[@model_name][k][:order].to_i}.select{|x| x[1][:direction].present?}.to_h
      count = 1
      session[@model_name].each do |k, v|
        session[@model_name][k][:order] = count
        count = count + 1
      end
      session[:prev_sort_field_name] = @sort_field_name
      session[@model_name]
    end

    def redirect_root
      if reject_redirect_root
        Rails.logger.info("reject redirect_root: #{params[:controller]}/#{params[:action]}}")
        return true
      end

      if params[:dashboard_menu]
        session[:dashboard_menu] = true
      end

      unless admin_user_signed_in?
        if params["current_lms_user"].present? && Rails.env == "development"
          # development かつ current_lms_user パラメータあり: 403 も未ログイン時のサインイン誘導も行わない
        elsif params["current_lms_user"].present?
          unless ["login", "launch"].include?(action_name)
            _render_403
          end
        else
          # current_lms_user パラメータなしの未ログイン — 環境に依らず SSO またはサインインへ誘導
          site = Site.first
          unexpected_url = [new_admin_user_session_path]
          unless SystemSetting.get_setting(:force_sign_in, site.id) == "1"
            unexpected_url << root_path
          end
          unless unexpected_url.include?(Thread.current[:request].path)
            if SystemSetting.get_setting(:sso_enable, site.id) == "1" and SystemSetting.get_setting(:force_sso_login, site.id) == "1"
              # 未ログインで、SSO認証がONの場合かつ、強制SSOログインを許可している場合は、SSO認証を行う
              sso_type = ::SystemSetting.get_setting(:sso_type, site.id)
              case sso_type
              when "saml2" then
                session[:direct_url] = Thread.current[:request].fullpath
                request = OneLogin::RubySaml::Authrequest.new
                redirect_to(request.create(saml_settings), allow_other_host: true)
              end
            else
              session[:direct_url] = Thread.current[:request].url
              session[:launch_url] = session[:direct_url].to_s.split("?")[0]
              redirect_to new_admin_user_session_path
            end
          end
        end
      end
    end
    
    def _render_403(e = nil)
      Rails.logger.error "Rendering 403 with excaption: #{e.message}" if e
      render "errors/403", status: :forbidden, layout: "error"
    end
    
    def set_page_number
      @page_number = params[:page]
    end
    
    def set_referrer
      @referrer = request.referrer.nil? ? nil : URI(request.referrer).path
      if request.referrer.to_s.include?("?")
        params = request.referrer.to_s.split("?")[1].to_s.split("&")
        params.delete_if{|x| x == "clear=true"}
        if params.present?
          @referrer = "#{@referrer}?#{params.join("&")}"
        end
      end
    end

    def remove_clear_param(url)
      url.gsub(/clear=true/, "").gsub(/\?&/, "?").gsub(/&&/, "&")
    end

    def add_anchor_to_path(url, anchor)
      "#{url}##{anchor}"
    end

    private
    def saml_settings
      site = Site.first
      sso_type = ::SystemSetting.get_setting(:sso_type, site.id)

      logic = eval("::Logic::Sso#{sso_type.classify}Logic.new")
      logic.settings
    end

    def set_not_need_navlink
      @not_need_navlink = true
    end
    def reject_redirect_root
      false
    end

    def get_lms_user(launch)
      lms_user = ::LmsUser.where(email: launch.get_launch_data['email'].to_s.downcase).where(lms: launch.get_launch_data['iss']).first

      if launch.get_launch_data['https://purl.imsglobal.org/spec/lti/claim/ext']
        username = launch.get_launch_data['https://purl.imsglobal.org/spec/lti/claim/ext']['user_username'].to_s.downcase.split("@")[0]
      else
        username = launch.get_launch_data['email'].to_s.downcase.split("@")[0].split("@")[0]
      end

      unless lms_user
        lms_user = ::LmsUser.where(username: username).where(lms: launch.get_launch_data['iss']).first
        lms_user = lms_user || ::LmsUser.where(username: username).first
      end
      lms_user
    end

    def clear_session_lti_custom_params
      session.delete(:lti_custom_params)
    end

  end
end