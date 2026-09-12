class CreateLtiOrgImportErrors < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_org_import_errors, comment: "LTI組織インポートエラー" do |t|
      t.integer :lti_org_import_id, index: true, comment: "LTI組織インポートID"
      t.integer :line_no, comment: "行番号"
      t.string :error_message, comment: "エラーメッセージ"
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
    end
  end
end
