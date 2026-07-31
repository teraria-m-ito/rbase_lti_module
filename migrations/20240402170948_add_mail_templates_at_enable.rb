class AddMailTemplatesAtEnable < ActiveRecord::Migration[7.0]
  def change
    add_column :mail_templates, :enable, :boolean, comment: "有効フラグ"
  end
end
