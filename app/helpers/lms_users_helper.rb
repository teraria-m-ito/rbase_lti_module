module LmsUsersHelper
  include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）

  def lms_user_show_title_actions
    return if proxy_login?
    return if current_lms_user.try(:id) == @lms_user.try(:id)
    return unless Ability.new(current_admin_user, "lms_users", "proxy_login").is_enable?

    button_to t(:"views.lms_users.show.button_proxy_login"),
              proxy_login_lms_user_path(@lms_user),
              method: :post,
              class: "btn btn-primary btn-sm js-proxy-login",
              form: { class: "d-inline", data: { turbo: false } },
              data: { confirm_message: t(:"views.lms_users.show.confirm_proxy_login") }
  end
end
