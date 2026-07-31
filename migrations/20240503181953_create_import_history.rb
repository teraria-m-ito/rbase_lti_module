class CreateImportHistory < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_import_histories, comment: "LTIインポート履歴" do |t|
      t.string :target_type, comment: "インポートタイプ"
      t.integer :target_id, comment: "履歴ID"
      t.integer :provider_job_id, comment: "delayed_job ID"
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
      t.integer :creator_id, comment: "作成ユーザID"
      t.integer :updater_id, comment: "更新ユーザID"
      t.integer :deleter_id, comment: "削除ユーザID"

    end

    add_index :lti_import_histories, [:target_type, :target_id], unique: true

  end
end
