class AddLmsUsersAtLtiOrgId < ActiveRecord::Migration[7.0]
  def change
    add_column :lms_users, :lti_org_id, :integer, comment: "LTI組織ID"
  end
end
