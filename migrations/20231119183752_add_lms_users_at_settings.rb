class AddLmsUsersAtSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :lms_users, :attr1, :string, comment: "ユーザ属性1"
    add_column :lms_users, :attr2, :string, comment: "ユーザ属性2"
    add_column :lms_users, :attr3, :string, comment: "ユーザ属性3"
    add_column :lms_users, :attr4, :string, comment: "ユーザ属性4"
    add_column :lms_users, :attr5, :string, comment: "ユーザ属性5"
    add_column :lms_users, :attr6, :string, comment: "ユーザ属性6"
    add_column :lms_users, :attr7, :string, comment: "ユーザ属性7"
    add_column :lms_users, :attr8, :string, comment: "ユーザ属性8"
    add_column :lms_users, :attr9, :string, comment: "ユーザ属性9"
    add_column :lms_users, :attr10, :string, comment: "ユーザ属性10"
  end
end
