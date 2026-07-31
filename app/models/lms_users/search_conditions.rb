module LmsUsers
  class SearchConditions
    include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
    include ActiveModel::Model
    attr_accessor :sites, :name, :username, :email
    attr_accessor :current_admin_user

    def search
      lms_users = ::LmsUser.joins(:lms_user_sites)
      admin_user_sites = self.sites.to_a.empty? ? Site.active.where(id: self.current_admin_user.sites.map(&:id)).all.to_a : self.sites
      lms_users = lms_users.where("lms_user_sites.site_id in (?)", admin_user_sites)
      lms_users = lms_users.where("lms_users.name like ?",  "#{self.name}%") unless self.name.blank?
      lms_users = lms_users.where("lms_users.username like ?",  "#{self.username}%") unless self.username.blank?
      lms_users = lms_users.where("lms_users.email like ?",  "#{self.email}%") unless self.email.blank?
      return lms_users.order(:username)
    end
  end
end