require 'net/http'
require 'json'
require 'uri'

module Api
  module Lti
    class LtiToolRegisterController < ::Api::BasesController
      include ApiCommon

      protect_from_forgery except: :new

      def new
        @base_url = request.base_url
        @database_name = params[:database_name]
        @tool_name = params[:tool_name] || "LTI"
        @tool_part_url = params[:app_part_url]
        if params[:custom_params]
          @custom_params = params[:custom_params].to_a.split(",").map { |pair|
            key, value = pair.split("=")
            [key, value]
          }.to_h
        else
          @custom_params = {}
        end

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

        payload = build_client_registration_payload
        registration_response = post_json_with_bearer(registration_endpoint, @registration_token, payload)

        unless registration_response&.dig('client_id')
          @error_message = "registration failed: #{registration_response.inspect}"
          return render :registration_result, status: :bad_gateway
        end

        @client_id       = registration_response['client_id']
        @deployment_id   = registration_response.dig('https://purl.imsglobal.org/spec/lti-tool-configuration', 'deployment_id') || registration_response['lti_deployment_id']

        lti_database.client_id = @client_id
        lti_database.iss = issuer
        lti_database.auth_login_url = oidc["authorization_endpoint"]
        lti_database.auth_token_url = oidc["token_endpoint"]
        lti_database.key_set_url = oidc["jwks_uri"]
        lti_database.deployment_json = @deployment_id
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

      private
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
        return nil unless res.is_a?(Net::HTTPSuccess)
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
        return nil unless res.is_a?(Net::HTTPSuccess)
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

        result = {
          "application_type" => "web",
          "response_types"   => ["id_token"],
          "grant_types"      => ["implicit", "client_credentials"],
          "token_endpoint_auth_method" => "private_key_jwt",
          "client_name"      => @tool_name,
          "initiate_login_uri" => initiate_login_uri,
          "redirect_uris"      => [launch_url], #[LAUNCH_URL, DEEP_LINK_RETURN_URL],
          "jwks_uri"           => "#{jwks_url}?name=#{@database_name}",
          "https://purl.imsglobal.org/spec/lti-tool-configuration" => {
            "domain"           => URI.parse(launch_url).host,
            "target_link_uri"  => launch_url,
            "messages" => [
              { "type" => "LtiResourceLinkRequest" },
              { "type" => "LtiDeepLinkingRequest" }
            ],
            "custom_parameters" => @custom_params,
            "claims"  => ["iss","sub","name","email"]
          },
          "https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings" => {
            "deep_link_return_url" => deep_link_return_url
          }
        }
        Rails.logger.info(result)
        result
      end
    end
  end
end
