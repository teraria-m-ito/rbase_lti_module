class AddLmsUsersAtInstOrgId < ActiveRecord::Migration[7.0]
  def change
    add_column :lms_users, :inst_org_id, :integer, comment: "学部組織ID"
    add_column :lms_users, :dept_org_id, :integer, comment: "学科組織ID"
    add_column :lms_users, :course_org_id, :integer, comment: "コース組織ID"
  end
end
