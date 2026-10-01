# -*- coding: utf-8 -*-
module RbaseLtiModule
  module RoleExt
    extend ActiveSupport::Concern

    def self.included(mod)
      mod.module_eval do
        has_many :admin_user_roles, dependent: :destroy
        has_many :admin_users, through: :admin_user_roles
      end
    end
  end
end
