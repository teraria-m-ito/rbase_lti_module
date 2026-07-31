# RbaseLtiModule::LtiIframeContext を、initializer より前に定義する（同 gem 内の他ファイルより先に engine だけ
# 読まれる状況でも NameError にしない）
require File.expand_path("lti_iframe_context", __dir__)

module RbaseLtiModule
  class Engine < ::Rails::Engine
    isolate_namespace RbaseLtiModule

    initializer "rbase_lti_module.iframe_lti_context" do
      # UserApplication 配下は LTI 起動後の遷移先なので lti_ctx を有効化
      config.to_prepare do
        lti = ::RbaseLtiModule::LtiIframeContext
        if defined?(::UserApplicationController) &&
            !::UserApplicationController.ancestors.include?(lti)
          ::UserApplicationController.include(lti)
        end
      end
    end
  end
end
