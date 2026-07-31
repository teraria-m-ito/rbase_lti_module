class CreateLtiDatabaseSites < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_database_sites, comment: "LTIデータベースサイト" do |t|
      t.integer  :lti_database_id, index: true, comment: "LTIデータベースID"
      t.integer  :site_id, index: true, comment: "サイトID"
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
    end
  end
end
