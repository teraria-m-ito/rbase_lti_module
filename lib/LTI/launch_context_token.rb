# frozen_string_literal: true

# iframe 等でセッション Cookie が使えない場合、LTI 起動文脈を
# 署名付きパラメータ lti_ctx で次画面以降に持ち回る。
module LTI
  class LaunchContextToken
    class << self
      def message_verifier
        @message_verifier ||= ::Rails.application.message_verifier("rbase7/lti_iframe_context")
      end

      # リダイレクト先 URL に lti_ctx= を付与する
      def append_lti_context_to_url(url, lms_user_id, launch_id)
        return url if lms_user_id.blank? || launch_id.blank?
        token = message_verifier.generate(
          { "lms_user_id" => lms_user_id, "launch_id" => launch_id },
          expires_in: 1.week
        )
        s = url.to_s
        separator = s.include?("?") ? "&" : "?"
        "#{s}#{separator}lti_ctx=#{::CGI.escape(token)}"
      end

      # 検証成功時は { "lms_user_id" =>, "launch_id" => } の Hash、失敗時 nil
      def verify_lti_ctx_param(value)
        return nil if value.blank?
        h = message_verifier.verify(value)
        return nil unless h.is_a?(Hash) && h["lms_user_id"].present? && h["launch_id"].present?
        h
      rescue ::StandardError
        # 改ざん・期限切れ等
        nil
      end
    end
  end
end
