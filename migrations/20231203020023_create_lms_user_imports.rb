class CreateLmsUserImports < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_user_imports, comment: "LMSユーザインポート" do |t|
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
      t.integer :creator_id, comment: "作成ユーザID"
      t.integer :updater_id, comment: "更新ユーザID"
      t.integer :deleter_id, comment: "削除ユーザID"
    end
  end
end
