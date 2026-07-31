class MigrateLtiOrgAtParentOrgId < ActiveRecord::Migration[7.0]
  def up
    change_column :lti_orgs, :parent_org_id, :integer
  end

  def down
    change_column :lti_orgs, :parent_org_id, :string
  end
end
