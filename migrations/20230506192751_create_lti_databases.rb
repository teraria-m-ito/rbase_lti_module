class CreateLtiDatabases < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_databases, comment: "LTIデータベース" do |t|
      t.string :name, comment: "名前"
      t.string :iss, null: false, unique: true, commnet: "iss"
      t.string :client_id, commnet: "クライアントID"
      t.string :auth_login_url, commnet: "authログインURL"
      t.string :auth_token_url, commnet: "authトークンURL"
      t.string :key_set_url, commnet: "キーセットURL"
      t.text :private_key_file, commnet: "プライベートキーファイル"
      t.string :kid, commnet: "kid"
      t.string :deployment_json, commnet: "デプロイID"
      t.datetime :deleted_at, index: true, commnet: "削除日時"
      t.timestamps
    end
    add_index :lti_databases, :iss
  end
end
