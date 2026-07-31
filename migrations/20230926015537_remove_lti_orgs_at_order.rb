class RemoveLtiOrgsAtOrder < ActiveRecord::Migration[7.0]
  def change
    remove_column :lti_orgs, :order, :integer
  end
end
