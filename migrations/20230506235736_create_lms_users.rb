class CreateLmsUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_users, comment: "LMSユーザ" do |t|
      t.string :username, comment: "ユーザID"
      t.string :name, comment: "氏名"
      t.string :given_name, comment: "姓"
      t.string :family_name, comment: "名"
      t.string :email, comment: "Eメール"
      t.string :lms, comment: "登録元LMS"
      t.string :role, comment: "権限"
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
    end
  end
end
