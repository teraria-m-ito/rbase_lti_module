class AddColumnPublicKeyAtLtiDatabases < ActiveRecord::Migration[7.0]
  def change
    add_column :lti_databases, :public_key, :text, index: true, comment: "公開鍵"
  end
end
