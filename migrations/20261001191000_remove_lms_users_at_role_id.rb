class RemoveLmsUsersAtRoleId < ActiveRecord::Migration[7.0]
  def up
    return unless column_exists?(:lms_users, :role_id)

    remove_index :lms_users, :role_id if index_exists?(:lms_users, :role_id)
    remove_column :lms_users, :role_id
  end

  def down
    return if column_exists?(:lms_users, :role_id)

    add_column :lms_users, :role_id, :bigint, comment: "現在選択中のロールID"
    add_index :lms_users, :role_id
  end
end
