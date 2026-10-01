class ChangeAdminUserRolesLmsUserIdToAdminUserId < ActiveRecord::Migration[7.0]
  def up
    return unless table_exists?(:admin_user_roles)
    return if column_exists?(:admin_user_roles, :admin_user_id) && !column_exists?(:admin_user_roles, :lms_user_id)

    unless column_exists?(:admin_user_roles, :admin_user_id)
      add_column :admin_user_roles, :admin_user_id, :bigint, comment: "管理ユーザID"
    end

    if column_exists?(:admin_user_roles, :lms_user_id)
      execute <<~SQL
        UPDATE admin_user_roles aur
        INNER JOIN lms_users lu ON lu.id = aur.lms_user_id
        SET aur.admin_user_id = lu.admin_user_id
      SQL

      if index_name_exists?(:admin_user_roles, :index_admin_user_roles_on_lms_user_id_and_role_id)
        remove_index :admin_user_roles, name: :index_admin_user_roles_on_lms_user_id_and_role_id
      end

      execute "DELETE FROM admin_user_roles WHERE admin_user_id IS NULL"
      execute <<~SQL
        DELETE aur FROM admin_user_roles aur
        INNER JOIN admin_user_roles keep
          ON keep.admin_user_id = aur.admin_user_id
         AND keep.role_id = aur.role_id
         AND keep.id < aur.id
      SQL

      remove_index :admin_user_roles, :lms_user_id if index_exists?(:admin_user_roles, :lms_user_id)
      remove_column :admin_user_roles, :lms_user_id
    end

    add_index :admin_user_roles, :admin_user_id unless index_exists?(:admin_user_roles, :admin_user_id)
    unless index_name_exists?(:admin_user_roles, :index_admin_user_roles_on_admin_user_id_and_role_id)
      add_index :admin_user_roles, [:admin_user_id, :role_id], unique: true, name: :index_admin_user_roles_on_admin_user_id_and_role_id
    end
  end

  def down
    return unless table_exists?(:admin_user_roles)
    return if column_exists?(:admin_user_roles, :lms_user_id)

    add_column :admin_user_roles, :lms_user_id, :bigint, comment: "LMSユーザID"
    execute <<~SQL
      UPDATE admin_user_roles aur
      INNER JOIN lms_users lu ON lu.admin_user_id = aur.admin_user_id
      SET aur.lms_user_id = lu.id
    SQL

    if index_name_exists?(:admin_user_roles, :index_admin_user_roles_on_admin_user_id_and_role_id)
      remove_index :admin_user_roles, name: :index_admin_user_roles_on_admin_user_id_and_role_id
    end
    remove_index :admin_user_roles, :admin_user_id if index_exists?(:admin_user_roles, :admin_user_id)
    remove_column :admin_user_roles, :admin_user_id

    add_index :admin_user_roles, :lms_user_id
    add_index :admin_user_roles, [:lms_user_id, :role_id], unique: true, name: :index_admin_user_roles_on_lms_user_id_and_role_id
  end
end
