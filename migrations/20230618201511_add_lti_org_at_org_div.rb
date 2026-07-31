class AddLtiOrgAtOrgDiv < ActiveRecord::Migration[7.0]
  def change
    add_column :lti_orgs, :org_div, :string, comment: "組織区分"
    add_column :lti_orgs, :order, :integer, comment: "表示順"
  end
end
