class CreateLtiOrgs < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_orgs, comment: "LTI組織" do |t|
      t.string :org_cd, index: true, comment: "組織CD"
      t.string :org_name, comment: "組織名"
      t.string :parent_org_cd, comment: "親組織CD"
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
    end
  end
end
