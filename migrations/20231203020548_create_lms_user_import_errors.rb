class CreateLmsUserImportErrors < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_user_import_errors, comment: "LMSユーザインポートエラー" do |t|
      t.integer :lms_user_import_id, index: true, comment: "LMSユーザインポートID"
      t.integer :line_no, comment: "行番号"
      t.string :error_message, comment: "エラーメッセージ"
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
    end
  end
end
