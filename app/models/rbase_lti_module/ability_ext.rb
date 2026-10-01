# -*- coding: utf-8 -*-
module RbaseLtiModule
  module AbilityExt
    # admin_user_roles が2件以上あるときは、所持ロールのいずれかで許可すれば通す。
    # 1件以下は従来どおり user.role（選択中ロール）で判定する。
    def initialize_with_rbase_lti_module(user, controller_name, action_name, force = false)
      if !force && user.present? && !Thread.current[:ability_skip_held_roles]
        admin_user_id = user.try(:id)
        if admin_user_id.present?
          roles = ::Role.joins(:admin_user_roles).where(admin_user_roles: {admin_user_id: admin_user_id}).distinct.to_a
          if roles.size >= 2
            Thread.current[:ability_skip_held_roles] = true
            begin
              allowed = roles.any? do |role|
                dummy = user.dup
                dummy.role = role
                self.class.new(dummy, controller_name, action_name).is_enable?
              end
            ensure
              Thread.current[:ability_skip_held_roles] = nil
            end
            if allowed
              can :manage, :all
              return
            end
          end
        end
      end
      initialize_without_rbase_lti_module(user, controller_name, action_name, force)
    end
  end
end
