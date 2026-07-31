class AddColumnLmsUserAtEnteringYear < ActiveRecord::Migration[7.0]
  def change
    add_column :lms_users, :entering_year, :integer, comment: "入学年度"
    add_column :lms_users, :grade, :integer, comment: "学年"
  end
end
