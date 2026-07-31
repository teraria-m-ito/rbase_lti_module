class LmsUserCustomField < ApplicationRecord
  include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
  self.table_name = "lms_user_custom_fields"

  include ::SelectableAttr::Base
  include CustomFieldConcern

  belongs_to :lms_user, inverse_of: :lms_user_custom_fields
  belongs_to :custom_field, optional: true

  validate :custom_fields_validate

  def custom_fields_validate
    self.validate_field
  end

end
