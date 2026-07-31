class CreateLtiUsages < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_usages, comment: "LTI利用ガイド" do |t|
      t.text :message, comment: "利用ガイドメッセージ"
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
      t.integer :creator_id, comment: "作成ユーザID"
      t.integer :updater_id, comment: "更新ユーザID"
      t.integer :deleter_id, comment: "削除ユーザID"
    end
  end
end
