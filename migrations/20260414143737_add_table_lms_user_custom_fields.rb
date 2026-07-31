class AddTableLmsUserCustomFields < ActiveRecord::Migration[7.0]
  def change
    create_table :lms_user_custom_fields do |t|
      t.integer :lms_user_id, index: true
      t.integer :custom_field_id, index: true
      t.string  :field_value

      t.datetime :deleted_at, index: true
      t.timestamps
    end
  end
end
