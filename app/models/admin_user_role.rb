class AdminUserRole < ApplicationRecord
  include ::Rbase::PluginModule::Extendable

  self.table_name = "admin_user_roles"

  belongs_to :admin_user, class_name: "::AdminUser", optional: true
  belongs_to :role, class_name: "::Role", optional: true

  validates :admin_user_id, presence: true
  validates :role_id, presence: true
  validates :role_id, uniqueness: { scope: :admin_user_id }
end
