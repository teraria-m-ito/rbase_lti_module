class RemoveColumnFieldsAtLmsUsers < ActiveRecord::Migration[7.0]
  def up
    remove_column :lms_users, :entering_year
    remove_column :lms_users, :grade
    remove_column :lms_users, :attr1
    remove_column :lms_users, :attr2
    remove_column :lms_users, :attr3
    remove_column :lms_users, :attr4
    remove_column :lms_users, :attr5
    remove_column :lms_users, :attr6
    remove_column :lms_users, :attr7
    remove_column :lms_users, :attr8
    remove_column :lms_users, :attr9
    remove_column :lms_users, :attr10
  end

  def down
    add_column :lms_users, :entering_year, :integer, comment: "入学年度"
    add_column :lms_users, :grade, :integer, comment: "学年"
    add_column :lms_users, :attr1, :string, comment: "ユーザ属性1"
    add_column :lms_users, :attr2, :string, comment: "ユーザ属性2"
    add_column :lms_users, :attr3, :string, comment: "ユーザ属性3"
    add_column :lms_users, :attr4, :string, comment: "ユーザ属性4"
    add_column :lms_users, :attr5, :string, comment: "ユーザ属性5"
    add_column :lms_users, :attr6, :string, comment: "ユーザ属性6"
    add_column :lms_users, :attr7, :string, comment: "ユーザ属性7"
    add_column :lms_users, :attr8, :string, comment: "ユーザ属性8"
    add_column :lms_users, :attr9, :string, comment: "ユーザ属性9"
    add_column :lms_users, :attr10, :string, comment: "ユーザ属性10"  end
end
