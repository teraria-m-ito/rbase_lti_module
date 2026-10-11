class AddColumnRegistrationLmsUrlAtLtiDatabases < ActiveRecord::Migration[7.0]
  def change
    add_column :lti_databases, :registration_lms_url, :string, comment: "呼び出し元LMS URL（動的登録を許可するLMS）"
  end
end
