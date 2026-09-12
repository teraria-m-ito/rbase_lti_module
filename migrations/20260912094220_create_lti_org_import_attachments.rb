class CreateLtiOrgImportAttachments < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_org_import_attachments, comment: "LTI組織インポート添付" do |t|
      t.integer  :lti_org_import_id, comment: "LTI組織インポートID"
      t.string   :filename, comment: "ファイル名"
      t.integer  :file_size, comment: "ファイルサイズ"
      t.string   :document, comment: "ドキュメント"
      t.string   :token, comment: "トークン"
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
    end
    add_index :lti_org_import_attachments, [:lti_org_import_id], name: :index_lti_org_import_atts_import_id
  end
end
