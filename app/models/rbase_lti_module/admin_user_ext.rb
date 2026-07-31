# -*- coding: utf-8 -*-
module RbaseLtiModule
  module AdminUserExt
    extend ActiveSupport::Concern
    include ::ActiveModel::Validations

    def self.included(mod)
      mod.extend(ClassMethods)
      mod.module_eval do
      end
    end

    def lms_user
      ::LmsUser.where(admin_user_id: self.id).first
    end

    def teacher?
      self.role.role_short_name == 'TEACHER'
    end

    def student?
      ['STUDENT', 'ALUMNI'].include?(self.role.role_short_name)
    end

    def almuni?
      ['ALUMNI'].include?(self.role.role_short_name)
    end


    def inst_org_id
      lms_user = self.lms_user.inst_org_id
    end

    def dept_org_id
      lms_user = self.lms_user.dept_org_id
    end

    module ClassMethods
      def find_for_database_authentication_with_rbase_lti_module(warden_conditions)
        conditions = warden_conditions.dup
        name = conditions.delete(:name)

        current_site_id = conditions.delete(:current_site_id)
        user = self
        if current_site_id
          user.joins(:admin_user_sites).where("admin_user_sites.site_id = ?", current_site_id)
        end
        name = conditions[:email]
        user = user.where(conditions).find_by("name = ? OR email = ?", name, name)
        user.current_site_id = user.site_ids.first if user
        user
      end
    end
  end
end