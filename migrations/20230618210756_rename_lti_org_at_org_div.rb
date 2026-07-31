class RenameLtiOrgAtOrgDiv < ActiveRecord::Migration[7.0]
  def change
    rename_column :lti_orgs, :parent_org_cd, :parent_org_id
  end
end
