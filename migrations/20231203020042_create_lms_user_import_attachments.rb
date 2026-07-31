class CreateLmsUserImportAttachments < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_user_import_attachments, comment: "LMSユーザインポート添付" do |t|
      t.integer  :lms_user_import_id, comment: "LTI振り返りインポートID"
      t.string   :filename, comment: "ファイル名"
      t.integer  :file_size, comment: "ファイルサイズ"
      t.string   :document, comment: "ドキュメント"
      t.string   :token, comment: "トークン"
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
    end
    add_index :lms_user_import_attachments, [:lms_user_import_id], name: :index_lms_user_import_atts_import_id
  end
end
