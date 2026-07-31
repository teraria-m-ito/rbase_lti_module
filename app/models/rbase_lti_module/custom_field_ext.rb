# -*- coding: utf-8 -*-
module RbaseLtiModule
  module CustomFieldExt
    extend ActiveSupport::Concern
    include ::ActiveModel::Validations

    def self.included(mod)
      mod.extend(ClassMethods)
      mod.module_eval do
        scope :lms_users, -> { where(custom_field_type: 'lms_user').order(:display_order) }
      end
    end

    module ClassMethods
      def added_entries_for_setting_custom_field_type_with_rbase_lti_module(mod)
        added_entries_for_setting_custom_field_type_without_rbase_lti_module(mod)
        mod.entry 'lms_user', :lms_user, 'Lmsユーザ'
      end

      def added_entries_for_setting_field_type_with_rbase_lti_module(mod)
        added_entries_for_setting_field_type_without_rbase_lti_module(mod)
        mod.entry 'institution', :institution, '学部'
        mod.entry 'department', :department, '学科'
      end
    end
  end
end