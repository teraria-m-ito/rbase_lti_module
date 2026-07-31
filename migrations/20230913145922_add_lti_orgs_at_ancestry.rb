class AddLtiOrgsAtAncestry < ActiveRecord::Migration[7.0]
  def change
    add_column :lti_orgs, :ancestry, :string, comment: "階層"
  end
end
