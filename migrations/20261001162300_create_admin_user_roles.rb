class CreateAdminUserRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :admin_user_roles, comment: "管理ユーザロール" do |t|
      t.bigint :lms_user_id, comment: "LMSユーザID"
      t.bigint :role_id, comment: "ロールID"
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
    end
    add_index :admin_user_roles, :lms_user_id
    add_index :admin_user_roles, :role_id
    add_index :admin_user_roles, [:lms_user_id, :role_id], unique: true, name: :index_admin_user_roles_on_lms_user_id_and_role_id
  end
end
