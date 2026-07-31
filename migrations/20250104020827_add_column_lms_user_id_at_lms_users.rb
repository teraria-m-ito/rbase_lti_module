class AddColumnLmsUserIdAtLmsUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :lms_users, :lms_user_id, :integer, comment: "LMSユーザID"
  end
end
