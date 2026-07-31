# -*- coding: utf-8 -*-
module RbaseLtiModule
  module AdminSettingExt
    extend ActiveSupport::Concern
    include ::ActiveModel::Validations

    def self.included(mod)
      mod.extend(ClassMethods)
      mod.module_eval do
      end
    end

    module ClassMethods
      # editable_divのselectable_attrをプラグインで拡張します
      def added_entries_for_menus_with_rbase_lti_module(mod)
        added_entries_for_menus_without_rbase_lti_module(mod)
        mod.entry 'lti_databases', :lti_databases, 'LTI Databases', url: "admin_lti_databases_path(clear: true)", icon: "fa fa-table", display_order: 92
      end
    end
  end
end