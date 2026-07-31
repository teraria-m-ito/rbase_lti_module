class AddLmsUsersAtAdminUserId < ActiveRecord::Migration[7.0]
  def change
    add_column :lms_users, :admin_user_id, :integer, index: true, comment: "ユーザID"
  end
end