require 'net/http'
require 'json'
require 'uri'
require 'base64'

module Api
  module Lti
    class LtiToolRegisterController < ::Api::BasesController
      include ApiCommon
      include ::SelectableAttr::Base
      include ::Rbase::PluginModule::Extendable

      layout false

      protect_from_forgery except: :new

      selectable_attr :optional_placement do
        entry "global_navigation", :global_navigation, "グローバルナビゲーション"
        entry "user_navigation", :user_navigation, "ユーザーナビゲーション"
        entry "account_navigation", :account_navigation, "アカウントナビゲーション"
        entry "course_navigation", :course_navigation, "コースナビゲーション"
        entry "course_home_sub_navigation", :course_home_sub_navigation, "コースホームサブナビゲーション"
        entry "course_settings_sub_navigation", :course_settings_sub_navigation, "コース設定サブナビゲーション"
        entry "top_navigation", :top_navigation, "トップナビゲーション"
      end

      # Instructure ホストの Canvas は、アカウントドメイン・OpenID 設定・登録 API が別ホストになる
      selectable_attr :canvas_cloud_environment do
        entry "production", :production, "本番", issuer_host: "canvas.instructure.com", service_host: "sso.canvaslms.com"
        entry "beta", :beta, "ベータ", issuer_host: "canvas.beta.instructure.com", service_host: "sso.beta.canvaslms.com"
        entry "test", :test, "テスト", issuer_host: "canvas.test.instructure.com", service_host: "sso.test.canvaslms.com"
      end

      def new
        @base_url = request.base_url
        @database_name = params[:database_name]
        @tool_name = params[:tool_name] || "LTI"
        assign_tool_part_url_and_custom_params!

        if @database_name.blank?
          return render status: :bad_request, plain: 'missing database_name'
        end
        lti_database = ::LTIDatabase.where(name: @database_name).first
        unless lti_database
          return render status: :bad_request, plain: 'invalid database_name'
        end

        @openid_configuration_url = params[:openid_configuration]
        @registration_token       = params[:registration_token]
        unless @openid_configuration_url.present? && @registration_token.present?
          return render status: :bad_request, plain: 'missing openid_configuration or registration_token'
        end

        # 認証なしで呼べる API のため、事前登録した呼び出し元LMS以外からの登録で LTI 設定を上書きさせない
        registered_origin = url_origin(lti_database.registration_lms_url)
        unless registered_origin
          Rails.logger.warn("[LTI DynReg] registration_lms_url not registered: database_name=#{@database_name}")
          return render status: :forbidden, plain: 'calling LMS is not registered'
        end
        unless trusted_dynreg_url?(@openid_configuration_url, registered_origin, @openid_configuration_url)
          Rails.logger.warn("[LTI DynReg] untrusted openid_configuration: #{@openid_configuration_url} (registered: #{registered_origin})")
          return render status: :forbidden, plain: 'untrusted openid_configuration'
        end

        oidc = fetch_json(@openid_configuration_url)
        unless oidc
          return render status: :bad_gateway, plain: 'failed to fetch openid_configuration'
        end

        issuer = oidc["issuer"]
        begin
          host = URI.parse(issuer).host
          # unless LtiTool::TRUSTED_ISSUER_HOSTS.include?(host)
          #   return render status: :forbidden, plain: "untrusted issuer: #{host}"
          # end
        rescue URI::InvalidURIError
          return render status: :bad_request, plain: 'invalid issuer'
        end

        registration_endpoint = oidc['registration_endpoint']
        unless registration_endpoint
          return render status: :bad_request, plain: 'registration_endpoint not found in openid_configuration'
        end
        unless trusted_dynreg_url?(registration_endpoint, registered_origin, @openid_configuration_url)
          Rails.logger.warn("[LTI DynReg] untrusted registration_endpoint: #{registration_endpoint} (registered: #{registered_origin})")
          return render status: :forbidden, plain: 'untrusted registration_endpoint'
        end

        payload = build_client_registration_payload
        registration_response = post_json_with_bearer(registration_endpoint, @registration_token, payload)

        unless registration_response&.dig('client_id')
          @error_message = "registration failed: #{registration_response.inspect}"
          return render :registration_result, status: :bad_gateway
        end

        @client_id       = registration_response['client_id']
        @deployment_id   = registration_response.dig('https://purl.imsglobal.org/spec/lti-tool-configuration', 'deployment_id') ||
                           registration_response['lti_deployment_id'] ||
                           registration_response['deployment_id']

        lti_database.client_id = @client_id
        lti_database.iss = issuer
        lti_database.auth_login_url = oidc["authorization_endpoint"]
        lti_database.auth_token_url = oidc["token_endpoint"]
        lti_database.key_set_url = oidc["jwks_uri"]
        lti_database.deployment_json = @deployment_id.present? ? JSON.generate([@deployment_id]) : nil
        if lti_database.private_key_file.blank? or lti_database.private_key_file == "dummy"
          plain, public_key = ::LTIDatabase.create_pem
          lti_database.private_key_file = plain
          lti_database.public_key = public_key
        end
        if lti_database.kid.blank? or lti_database.kid == "dummy"
          kid = ::LTIDatabase.create_kid
          lti_database.kid = kid
        end
        lti_database.save!
        render :registration_result, layout: false
      rescue => e
        Rails.logger.error("[LTI DynReg] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
        render status: :internal_server_error, plain: 'unexpected error'
      end

      # 権限マスタ用。new は convert_action で create を参照する。
      def create
        new
      end

      private

      def url_origin(url)
        host = url_host(url)
        return nil if host.blank?

        uri = URI.parse(url.to_s.strip)
        return nil unless uri.is_a?(URI::HTTP)

        "#{uri.scheme}://#{host}:#{uri.port}"
      rescue URI::InvalidURIError
        nil
      end

      def url_host(url)
        URI.parse(url.to_s.strip).host.to_s.downcase
      rescue URI::InvalidURIError
        ""
      end

      # 呼び出し元LMSと同じオリジン、または Instructure クラウドの対応ホストを許可する。
      # クラウドの場合は registration_token の root_account_domain が呼び出し元LMSのホストと一致する必要がある。
      # トークン署名は未検証なので、ホストの許可リストとセットで見る。任意の URL は許可しない。
      def trusted_dynreg_url?(url, registered_origin, openid_configuration_url)
        origin = url_origin(url)
        return false unless origin
        return true if origin == registered_origin

        issuer_host = url_host(openid_configuration_url)
        environment = self.class.canvas_cloud_environment_entries.detect { |entry| entry[:issuer_host] == issuer_host }
        return false unless environment

        segment = @registration_token.to_s.split(".")[1].to_s
        return false if segment.blank?

        padded = segment + ("=" * ((4 - segment.length % 4) % 4))
        account_host = JSON.parse(Base64.urlsafe_decode64(padded))["root_account_domain"].to_s.strip.downcase
        return false if account_host.blank? || account_host != url_host(registered_origin)

        host = url_host(url)
        host == environment[:issuer_host] || host == environment[:service_host]
      rescue ArgumentError, JSON::ParserError
        false
      end

      # app_part_url は LTI エンドポイント用パス（例: ldi/dashboard）。
      # クエリ文字列が付いている場合は custom_parameters へ取り込む。
      def assign_tool_part_url_and_custom_params!
        raw = params[:app_part_url].to_s.strip
        @custom_params = parse_custom_params_param(params[:custom_params])

        path_part = raw
        if raw.include?("?")
          path_part, query_part = raw.split("?", 2)
          URI.decode_www_form(query_part).each do |key, value|
            next if key == "clear"
            next if value.blank?

            @custom_params[key] = value
          end
        end

        @tool_part_url = normalize_tool_part_path(path_part)
      end

      def normalize_tool_part_path(path)
        path.to_s.strip.sub(%r{\A/}, "").sub(%r{/index\z}, "")
      end

      def parse_custom_params_param(raw)
        return {} if raw.blank?

        raw.to_s.split(",").each_with_object({}) do |pair, h|
          key, value = pair.split("=", 2)
          next if key.blank?

          h[key] = value.to_s
        end
      end

      def fetch_json(url)
        Rails.logger.debug("[fetch_json]url:#{url}")
        uri = URI.parse(url)
        req = Net::HTTP::Get.new(uri)
        req['Accept'] = 'application/json'

        res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.read_timeout = 10
          http.open_timeout = 5
          http.request(req)
        end
        unless res.is_a?(Net::HTTPSuccess)
          Rails.logger.warn("[fetch_json]failed: #{res.code} #{res.body.to_s[0, 300]}")
          return nil
        end
        Rails.logger.debug("[fetch_json]res:#{res.body}")
        JSON.parse(res.body)
      end

      def post_json_with_bearer(url, token, body_hash)
        Rails.logger.debug("[post_json_with_bearer]url:#{url}")
        uri = URI.parse(url)
        req = Net::HTTP::Post.new(uri)
        req['Content-Type']  = 'application/json'
        req['Accept']        = 'application/json'
        req['Authorization'] = "Bearer #{token}"
        req.body = JSON.generate(body_hash)

        res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.read_timeout = 15
          http.open_timeout = 5
          http.request(req)
        end
        unless res.is_a?(Net::HTTPSuccess)
          Rails.logger.warn("[post_json_with_bearer]failed: #{res.code} #{res.body.to_s[0, 300]}")
          return nil
        end
        Rails.logger.debug("[post_json_with_bearer]res:#{res.body}")
        result = res.body
        match = result.to_s.match(/.*\{(.+)\}.*\z/)
        if match and match[1]
          result = "#{match}"
        end
        JSON.parse(result)
      end

      def build_client_registration_payload
        domain_url = @base_url
        initiate_login_uri= "#{domain_url}/#{@tool_part_url}/login"
        launch_url = "#{domain_url}/#{@tool_part_url}/launch"
        jwks_url = "#{domain_url}/#{@tool_part_url}/jwks"
        deep_link_url = "#{domain_url}/#{@tool_part_url}/configure"
        deep_link_return_url = "#{domain_url}/#{@tool_part_url}/configure"

        requested_placements = Array(params[:placements]).flat_map { |v| v.to_s.split(",") }.map(&:strip)
        resource_link_placements = [
          "https://canvas.instructure.com/lti/assignment_selection",
          "https://canvas.instructure.com/lti/homework_submission",
          "https://canvas.instructure.com/lti/link_selection"
        ]
        self.class.optional_placement_ids.each do |id|
          next unless requested_placements.include?(id)
          resource_link_placements << "https://canvas.instructure.com/lti/#{id}"
        end

        icon_url = "#{domain_url}#{view_context.asset_path("menu_icon.svg")}"
        # scope=true のときだけ scope を付ける。中身は利用プロジェクトが dynamic_registration_scopes で返す
        requested_scopes = if ActiveModel::Type::Boolean.new.cast(params[:scope])
                             Array(dynamic_registration_scopes).flat_map { |value| value.to_s.split(/\s+/) }.map(&:strip).reject(&:blank?).uniq
                           else
                             []
                           end

        result = {
          "application_type" => "web",
          "response_types"   => ["id_token"],
          "grant_types"      => ["implicit", "client_credentials"],
          "token_endpoint_auth_method" => "private_key_jwt",
          "client_name"      => @tool_name,
          "initiate_login_uri" => initiate_login_uri,
          "redirect_uris"      => [launch_url], #[LAUNCH_URL, DEEP_LINK_RETURN_URL],
          "jwks_uri"           => "#{jwks_url}?name=#{@database_name}",
          "logo_uri"           => icon_url,
          "https://purl.imsglobal.org/spec/lti-tool-configuration" => {
            "domain"           => URI.parse(launch_url).host,
            "target_link_uri"  => launch_url,
            "messages" => [
              {
                "type" => "LtiResourceLinkRequest",
                "placements" => resource_link_placements,
                "icon_uri" => icon_url
              },
              {
                "type" => "LtiDeepLinkingRequest",
                "placements" => [
                  "https://canvas.instructure.com/lti/assignment_selection",
                  "https://canvas.instructure.com/lti/homework_submission"
                ]
              }
            ],
            "custom_parameters" => @custom_params,
            "claims"  => ["iss","sub","name","email"]
          },
          "https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings" => {
            "deep_link_return_url" => deep_link_return_url
          }
        }
        result["scope"] = requested_scopes.join(" ") if requested_scopes.present?
        Rails.logger.info(result)
        result
      end

      # scope=true のときに登録へ載せる scope。利用プロジェクトが差し替える。未指定なら空
      def dynamic_registration_scopes
        []
      end
    end
  end
end
