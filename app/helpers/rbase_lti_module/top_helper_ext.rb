# -*- coding: utf-8 -*-
module RbaseLtiModule
  module TopHelperExt
    extend ActiveSupport::Concern

    def self.included(mod)
      mod.module_eval do

        def manager_top_page_content_with_rbase_lti_module
          content = SystemSetting.get_setting(:top_page_content, current_site_id)
          content.to_s.html_safe
        end
      end
    end
  end
end
