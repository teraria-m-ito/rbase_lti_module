module Lti
  class AdminBasesController < BasesController
    include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
    layout "application_lti_admin"
    prepend_view_path 'custom/app/views'

    #    before_action :set_login
  end
end