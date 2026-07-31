# Include hook code here
require './lib/rbase/plugin_module'

# SessionsControllerExt が include する Lti::OperationLogCreation を、
# autoload より先に読み込む（constantize 時の NameError を防ぐ）
require File.expand_path("app/controllers/concerns/lti/operation_log_creation", __dir__)

Rbase::PluginModule.register(
  "RbaseLtiModule::SystemSettingExt",
  "RbaseLtiModule::AdminUserExt",
  "RbaseLtiModule::AdminSettingExt",
  "RbaseLtiModule::CustomFieldExt",
  "RbaseLtiModule::ApplicationHelperExt",
  "RbaseLtiModule::TopHelperExt",
  "RbaseLtiModule::AdminUsers::SessionsControllerExt",
)