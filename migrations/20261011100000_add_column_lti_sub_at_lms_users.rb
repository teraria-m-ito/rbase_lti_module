class AddColumnLtiSubAtLmsUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :lms_users, :lti_sub, :string, comment: "LTI sub（LMS 上のユーザ識別子）"
    add_index :lms_users, [:lms, :lti_sub]
  end
end
