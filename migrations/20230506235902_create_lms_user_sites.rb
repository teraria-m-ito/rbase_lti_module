class CreateLmsUserSites < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_user_sites, comment: "LMSユーザサイト" do |t|
      t.integer  :lms_user_id, index: true, comment: "LMSユーザID"
      t.integer  :site_id, index: true, comment: "サイトID"
      t.datetime :deleted_at, index: true, comment: "削除日時"
      t.timestamps
    end
  end
end
