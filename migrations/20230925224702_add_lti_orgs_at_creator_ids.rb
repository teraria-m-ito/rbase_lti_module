class AddLtiOrgsAtCreatorIds < ActiveRecord::Migration[7.0]
  def change
    add_column :lti_orgs, :creator_id, :integer, comment: "作成ユーザID"
    add_column :lti_orgs, :updater_id, :integer, comment: "更新ユーザID"
    add_column :lti_orgs, :deleter_id, :integer, comment: "削除ユーザID"
  end
end
