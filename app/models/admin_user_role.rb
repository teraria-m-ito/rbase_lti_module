class AdminUserRole < ApplicationRecord
  include ::Rbase::PluginModule::Extendable

  self.table_name = "admin_user_roles"

  belongs_to :lms_user, optional: true
  belongs_to :role, class_name: "::Role", optional: true

  validates :lms_user_id, presence: true
  validates :role_id, presence: true
  validates :role_id, uniqueness: { scope: :lms_user_id }
end
