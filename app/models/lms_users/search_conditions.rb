module LmsUsers
  class SearchConditions
    include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
    include ActiveModel::Model
    attr_accessor :sites, :name, :username, :email
    attr_accessor :current_admin_user

    def search
      lms_users = ::LmsUser.joins(:lms_user_sites)
      # 指定サイトは操作者の所属サイトに限る（他サイトの ID を送られても検索しない）
      own_site_ids = Site.active.where(id: Array(self.current_admin_user&.site_ids)).pluck(:id)
      site_ids = self.sites.to_a.reject(&:blank?).map(&:to_i) & own_site_ids
      site_ids = own_site_ids if site_ids.empty?
      lms_users = lms_users.where("lms_user_sites.site_id in (?)", site_ids)
      lms_users = lms_users.where("lms_users.name like ?",  "#{self.name}%") unless self.name.blank?
      lms_users = lms_users.where("lms_users.username like ?",  "#{self.username}%") unless self.username.blank?
      lms_users = lms_users.where("lms_users.email like ?",  "#{self.email}%") unless self.email.blank?
      return lms_users.order(:username)
    end
  end
end