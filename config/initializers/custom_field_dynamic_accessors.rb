# frozen_string_literal: true

# CustomFieldDynamicAccessors / ImportRow 用アクセサのキャッシュをリロード時に破棄する
Rails.application.config.to_prepare do
  if (klass = "LmsUser".safe_constantize) &&
     klass.respond_to?(:reset_custom_field_dynamic_access_cache!)
    klass.reset_custom_field_dynamic_access_cache!
  end

  if (row_klass = "LmsUserImportRow".safe_constantize) &&
     row_klass.respond_to?(:reset_lms_user_import_row_custom_field_access_cache!)
    row_klass.reset_lms_user_import_row_custom_field_access_cache!
  end

  if (row_klass = "LTIOrgImportRow".safe_constantize) &&
     row_klass.respond_to?(:reset_lti_org_import_row_custom_field_access_cache!)
    row_klass.reset_lti_org_import_row_custom_field_access_cache!
  end
end
