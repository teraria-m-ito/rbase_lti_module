# frozen_string_literal: true

# custom_field_type が lms_user の CustomField を field_name 単位で参照するゲッター／セッター（ActiveModel 用・ハッシュ保持）。
# 定義順は CustomField#display_order 昇順（CustomField.lms_users と同じ）。
# 既存のインスタンスメソッド名と field_name が衝突した場合は、明示メソッドが優先されます。
module LmsUserImportRowCustomFieldAccessors
  extend ActiveSupport::Concern

  class_methods do
    def reset_lms_user_import_row_custom_field_access_cache!
      @lms_user_import_row_custom_field_definitions = nil
      @lms_user_import_row_custom_field_method_name_index = nil
    end

    def database_ready_for_lms_user_import_row_custom_fields?
      return false unless ActiveRecord::Base.connected?

      ActiveRecord::Base.connection.data_source_exists?(:custom_fields)
    end

    def lms_user_import_row_custom_field_definitions
      @lms_user_import_row_custom_field_definitions ||= _load_lms_user_import_row_definitions
    end

    def _load_lms_user_import_row_definitions
      return [] unless database_ready_for_lms_user_import_row_custom_fields?

      if ::CustomField.respond_to?(:lms_users)
        ::CustomField.lms_users.to_a
      else
        ::CustomField.where(custom_field_type: "lms_user").order(:display_order).to_a
      end
    end

    def lms_user_import_row_custom_field_method_name_index
      @lms_user_import_row_custom_field_method_name_index ||= lms_user_import_row_custom_field_definitions.each_with_object({}) do |cf, h|
        next if cf.field_name.blank?

        h[cf.field_name.to_s] = cf
      end
    end
  end

  def method_missing(method_name, *args, &block)
    s = method_name.to_s
    base = setter_method_name?(s) ? s.chomp("=") : s
    cf = self.class.lms_user_import_row_custom_field_method_name_index[base]
    if cf
      return write_import_row_custom_field(cf, args.first) if setter_method_name?(s)

      return read_import_row_custom_field(cf)
    end

    super
  end

  def respond_to_missing?(method_name, include_private = false)
    s = method_name.to_s
    base = setter_method_name?(s) ? s.chomp("=") : s
    return true if self.class.database_ready_for_lms_user_import_row_custom_fields? &&
                   self.class.lms_user_import_row_custom_field_method_name_index.key?(base)

    super
  end

  private

  def setter_method_name?(method_name_str)
    method_name_str.end_with?("=") && method_name_str != "="
  end

  def read_import_row_custom_field(custom_field)
    lms_user_import_row_custom_field_values[custom_field.field_name.to_s]
  end

  def write_import_row_custom_field(custom_field, value)
    lms_user_import_row_custom_field_values[custom_field.field_name.to_s] = value
  end

  def lms_user_import_row_custom_field_values
    @lms_user_import_row_custom_field_values ||= {}
  end
end
