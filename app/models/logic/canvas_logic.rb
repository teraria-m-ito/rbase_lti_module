require 'httparty'
require 'json'
require 'mechanize'
require 'cgi'
require 'uri'

module Logic
  class CanvasLogic < Logic::LmsApiBaseLogic
    include ActiveModel::Model
    include Rails.application.routes.url_helpers

    attr_accessor :wstoken
    attr_accessor :base_url

    ##
    # 設定で定義
    # lmsのURLからLMSタイプに変換する
    # MOODLE or CANVAS
    # lms_types が一致しなくても、CANVAS LMS 設定（canvas_api_base_url）と iss が同じなら CANVAS
    def self.get_lms_type(target, site_id = nil)
      sid = if site_id.present?
              id = site_id.to_i
              (id > 0 && ::Site.active.exists?(id)) ? id : nil
            else
              sess = Thread.current[:request].try(:session).try(:[], :active_site_id)
              if sess.present?
                id = sess.to_i
                (id > 0 && ::Site.active.exists?(id)) ? id : nil
              elsif ::Site.active.count == 1
                ::Site.active.limit(1).pick(:id)
              end
            end
      return nil if sid.blank?

      ::SystemSetting.get_setting(:lms_types, sid).to_s.split("\n").each do |lms_type|
        lms = lms_type.split("|")[0]
        type = lms_type.split("|")[1].to_s.strip
        next if type.blank?
        return type if lms_url_match?(target, lms)
      end

      token = ::SystemSetting.get_setting(:canvas_api_token, sid).to_s
      base = ::SystemSetting.get_setting(:canvas_api_base_url, sid).to_s
      return "CANVAS" if token.present? && base.present? && lms_url_match?(target, base)

      nil
    end

    def self.lms_url_match?(a, b)
      na = a.to_s.strip.gsub("\uFF1A", ":").downcase.sub(/\/+\z/, "")
      nb = b.to_s.strip.gsub("\uFF1A", ":").downcase.sub(/\/+\z/, "")
      return false if na.blank? || nb.blank?
      return true if na == nb

      uri_a = URI.parse(na.match?(/\Ahttps?:/i) ? na : "https://#{na}") rescue nil
      uri_b = URI.parse(nb.match?(/\Ahttps?:/i) ? nb : "https://#{nb}") rescue nil
      uri_a && uri_b && uri_a.host.present? && uri_a.host == uri_b.host
    end

    ##
    # 設定で定義
    # APIで取得されるカスタムフィールド名をlms_usersのカラム名に変換する
    def self.get_lms_field_type(target)
      lms_field_names = ::SystemSetting.get_setting(:lms_field_names, 1).to_s.split("\n")
      result = nil
      lms_field_names.each do |lms_field_name|
        lms_name = lms_field_name.split("|")[0]
        lti_name = lms_field_name.split("|")[1]

        if target == lms_name
          result = lti_name
          break
        end
      end

      result
    end

    ACCOUNT_INFO_API_URL = "/api/v1/accounts"
    SUBACCOUNT_LIST_API_URL = "/api/v1/accounts/:account_id/sub_accounts"
    USER_ENROLLMENTS_API_URL = "/api/v1/users/:user_id/enrollments"

    ##
    # canvas apiを通して、アカウント情報を取得する
    def get_account_info(admin_user)
      get_account_infos(admin_user).first
    end

    ##
    # canvas apiを通して、アカウント情報を取得する
    def get_account_infos(admin_user)
      site_id = admin_user.sites.first.id
      self.wstoken = ::SystemSetting.get_setting(:canvas_api_token, site_id) unless self.wstoken
      self.base_url = ::SystemSetting.get_setting(:canvas_api_base_url, site_id) unless self.base_url

      url = "#{self.base_url}#{ACCOUNT_INFO_API_URL}"

      CanvasLogic.debug_log "[CanvasLogic][get_account_info]url:#{url} / token:#{self.wstoken}"

      response = HTTParty.get(url,
                              headers: {
                                'Authorization' => "Bearer #{self.wstoken}",
                                'Accept' => 'application/json',
                              }
      )

      if response.try(:code) != 200
        CanvasLogic.debug_log "[CanvasLogic][get_account_info] error:#{response.try(:code)}"
        CanvasLogic.debug_log JSON.parse(response.body)
        return nil
      end

      CanvasLogic.debug_log "[CanvasLogic][get_account_info]response:#{response}"
      JSON.parse(response.body)
    end

    ##
    # root account_idの取得
    def get_root_account_id(admin_user)
      account_info = get_account_info(admin_user)
      if account_info
        account_info.first["id"]
      else
        nil
      end
    end

    ##
    # root account_idリストの取得
    def get_root_account_ids(admin_user)
      result = []
      account_infos = get_account_infos(admin_user)
      account_infos.eaech do |account_info|
        result << account_info if account_info["parent_account_id"].blank?
      end
      result
    end

    ##
    # canvas apiを通して、サブアカウントの一覧を取得する
    def get_subaccount_list(admin_user, root_account_id = nil)
      CanvasLogic.debug_log "[CanvasLogic][get_subaccount_list]admin_user:#{admin_user.id}"

      root_account_id = get_root_account_id(admin_user) unless root_account_id

      if root_account_id
        self.wstoken = ::SystemSetting.get_setting(:canvas_api_token, site_id) unless self.wstoken
        self.base_url = ::SystemSetting.get_setting(:canvas_api_base_url, site_id) unless self.base_url

        url = "#{self.base_url}#{SUBACCOUNT_LIST_API_URL}"

        url = url.gsub(":account_id", root_account_id.to_s)
        CanvasLogic.debug_log "[CanvasLogic][get_subaccount_list]url:#{url} / token:#{self.wstoken}"

        response = HTTParty.get(url,
                                 headers: {
                                   'Authorization' => "Bearer #{self.wstoken}",
                                   'Accept' => 'application/json',
                                 }
        )

        if response.try(:code) != 200
          CanvasLogic.debug_log "[CanvasLogic][get_subaccount_list] error:#{response.try(:code)}"
          return nil
        end

        CanvasLogic.debug_log "[CanvasLogic][get_subaccount_list]response:#{response}"
        JSON.parse(response.body)
      end
    end

    ##
    # Canvas ユーザを email / login_id で取得する。接続先は CANVAS LMS 設定（canvas_api_base_url / canvas_api_token）
    def get_user_info(lms_user, site_id)
      return nil unless apply_canvas_api_settings!(site_id)

      if lms_user.lms_user_id.present?
        response = canvas_http_get("/api/v1/users/#{lms_user.lms_user_id}")
        if response.try(:code) == 200
          user = JSON.parse(response.body)
          CanvasLogic.debug_log "[CanvasLogic][get_user_info]id:#{user['id']}"
          return user
        end
        CanvasLogic.debug_log "[CanvasLogic][get_user_info] by id error:#{response.try(:code)}"
      end

      login = lms_user.username.to_s
      %w[sis_login_id sis_user_id].each do |prefix|
        next if login.blank?
        id_path = "#{prefix}:#{login}"
        response = canvas_http_get("/api/v1/users/#{prefix}:#{CGI.escape(login)}")
        if response.try(:code) == 200
          user = JSON.parse(response.body)
          CanvasLogic.debug_log "[CanvasLogic][get_user_info]#{id_path}:#{user['id']}"
          return user
        end
        CanvasLogic.debug_log "[CanvasLogic][get_user_info] #{id_path} error:#{response.try(:code)}"
      end

      email = lms_user.email.to_s.downcase
      terms = [email, login].map(&:presence).uniq
      terms.each do |term|
        response = canvas_http_get("/api/v1/accounts/self/users", search_term: term, per_page: 50)
        unless response.try(:code) == 200
          CanvasLogic.debug_log "[CanvasLogic][get_user_info] search error:#{response.try(:code)} term=#{term}"
          next
        end

        users = JSON.parse(response.body)
        users = [users] if users.is_a?(Hash)
        found = Array(users).find { |u| u["email"].to_s.downcase == email }
        found ||= Array(users).find { |u| u["login_id"].to_s.downcase == login.downcase }
        found ||= Array(users).find { |u| u["sis_user_id"].to_s.downcase == login.downcase }
        CanvasLogic.debug_log "[CanvasLogic][get_user_info]search:#{found.try(:[], 'id')} term=#{term}"
        return found if found.present?
      end
      nil
    end

    ##
    # USER（AdminUser ロールは MEMBER）の履修から STUDENT / TEACHER を決める。両方あれば STUDENT。該当なしは変更しない
    def apply_member_role_from_enrollments!(lms_user, site_id)
      return unless lms_user.role == "USER"
      return if lms_user.lms_user_id.blank?
      return unless apply_canvas_api_settings!(site_id)

      enrollments = get_user_enrollments(lms_user.lms_user_id)
      CanvasLogic.debug_log "[CanvasLogic][apply_member_role_from_enrollments] count=#{Array(enrollments).size}"
      return if enrollments.blank?

      types = enrollments.map { |e| e["type"].to_s }
      has_student = types.any? { |t| %w[StudentEnrollment StudentViewEnrollment].include?(t) }
      has_teacher = types.any? { |t| %w[TeacherEnrollment TaEnrollment].include?(t) }

      if has_student
        lms_user.role = "STUDENT"
      elsif has_teacher
        lms_user.role = "TEACHER"
      end
      CanvasLogic.debug_log "[CanvasLogic][apply_member_role_from_enrollments] types=#{types.uniq} student:#{has_student} teacher:#{has_teacher} role:#{lms_user.role}"
    end

    def get_user_enrollments(canvas_user_id)
      base = "#{self.base_url.to_s.chomp('/')}#{USER_ENROLLMENTS_API_URL.gsub(':user_id', canvas_user_id.to_s)}"
      queries = [
        URI.encode_www_form([["state[]", "active"], ["state[]", "invited"], ["per_page", "100"]]),
        URI.encode_www_form([["per_page", "100"]])
      ]
      queries.each do |query|
        url = "#{base}?#{query}"
        result = []
        while url.present?
          CanvasLogic.debug_log "[CanvasLogic][get_user_enrollments]url:#{url}"
          response = HTTParty.get(url,
                                  headers: {
                                    'Authorization' => "Bearer #{self.wstoken}",
                                    'Accept' => 'application/json',
                                  }
          )
          unless response.try(:code) == 200
            CanvasLogic.debug_log "[CanvasLogic][get_user_enrollments] error:#{response.try(:code)}"
            break
          end

          body = JSON.parse(response.body)
          result.concat(Array(body))
          url = canvas_link_rel_next(response.headers["link"] || response.headers["Link"])
        end
        CanvasLogic.debug_log "[CanvasLogic][get_user_enrollments]count:#{result.size}"
        return result if result.present?
      end
      []
    end

    def apply_canvas_api_settings!(site_id)
      id = site_id.to_i
      return false unless id > 0 && ::Site.active.exists?(id)

      self.wstoken = ::SystemSetting.get_setting(:canvas_api_token, id) unless self.wstoken
      self.base_url = ::SystemSetting.get_setting(:canvas_api_base_url, id) unless self.base_url
      if self.wstoken.blank? || self.base_url.blank?
        CanvasLogic.debug_log "[CanvasLogic] canvas_api_token / canvas_api_base_url 未設定 site_id=#{id}"
        return false
      end
      true
    end

    def canvas_http_get(path, query = {})
      url = "#{self.base_url.to_s.chomp('/')}#{path}"
      url += "?#{query.to_query}" if query.present?
      CanvasLogic.debug_log "[CanvasLogic][GET]#{url}"
      HTTParty.get(url,
                   headers: {
                     'Authorization' => "Bearer #{self.wstoken}",
                     'Accept' => 'application/json',
                   }
      )
    end

    def canvas_link_rel_next(link_header)
      return nil if link_header.blank?

      link_header.to_s.split(",").each do |part|
        next unless part.include?('rel="next"')
        m = part.match(/<([^>]+)>/)
        return m[1] if m
      end
      nil
    end
  end
end
