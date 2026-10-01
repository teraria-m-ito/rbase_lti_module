class RenameLmsUserRolesToAdminUserRoles < ActiveRecord::Migration[7.0]
  def up
    if table_exists?(:lms_user_roles)
      rename_table :lms_user_roles, :admin_user_roles
    end

    return unless table_exists?(:admin_user_roles)

    if index_name_exists?(:admin_user_roles, :index_lms_user_roles_on_deleted_at)
      rename_index :admin_user_roles, :index_lms_user_roles_on_deleted_at, :index_admin_user_roles_on_deleted_at
    end
    if index_name_exists?(:admin_user_roles, :index_lms_user_roles_on_lms_user_id)
      rename_index :admin_user_roles, :index_lms_user_roles_on_lms_user_id, :index_admin_user_roles_on_lms_user_id
    end
    if index_name_exists?(:admin_user_roles, :index_lms_user_roles_on_role_id)
      rename_index :admin_user_roles, :index_lms_user_roles_on_role_id, :index_admin_user_roles_on_role_id
    end
    if index_name_exists?(:admin_user_roles, :index_lms_user_roles_on_lms_user_id_and_role_id)
      rename_index :admin_user_roles, :index_lms_user_roles_on_lms_user_id_and_role_id, :index_admin_user_roles_on_lms_user_id_and_role_id
    end

    execute "ALTER TABLE admin_user_roles COMMENT = '管理ユーザロール'"
  end

  def down
    return unless table_exists?(:admin_user_roles)
    return if table_exists?(:lms_user_roles)

    if index_name_exists?(:admin_user_roles, :index_admin_user_roles_on_deleted_at)
      rename_index :admin_user_roles, :index_admin_user_roles_on_deleted_at, :index_lms_user_roles_on_deleted_at
    end
    if index_name_exists?(:admin_user_roles, :index_admin_user_roles_on_lms_user_id)
      rename_index :admin_user_roles, :index_admin_user_roles_on_lms_user_id, :index_lms_user_roles_on_lms_user_id
    end
    if index_name_exists?(:admin_user_roles, :index_admin_user_roles_on_role_id)
      rename_index :admin_user_roles, :index_admin_user_roles_on_role_id, :index_lms_user_roles_on_role_id
    end
    if index_name_exists?(:admin_user_roles, :index_admin_user_roles_on_lms_user_id_and_role_id)
      rename_index :admin_user_roles, :index_admin_user_roles_on_lms_user_id_and_role_id, :index_lms_user_roles_on_lms_user_id_and_role_id
    end

    rename_table :admin_user_roles, :lms_user_roles
    execute "ALTER TABLE lms_user_roles COMMENT = 'LMSユーザロール'"
  end
end
