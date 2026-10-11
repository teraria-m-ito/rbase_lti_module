module LTIDatabases
  class SearchConditions
    include ActiveModel::Model
    attr_accessor :sites, :name, :iss
    attr_accessor :current_admin_user

    def search
      lti_databases = LTIDatabase.joins(:lti_database_sites)
      # 指定サイトは操作者の所属サイトに限る（他サイトの ID を送られても検索しない）
      own_site_ids = Site.active.where(id: Array(self.current_admin_user&.site_ids)).pluck(:id)
      site_ids = self.sites.to_a.reject(&:blank?).map(&:to_i) & own_site_ids
      site_ids = own_site_ids if site_ids.empty?
      lti_databases = lti_databases.where("lti_database_sites.site_id in (?)", site_ids)
      lti_databases = lti_databases.where("lti_databases.name like ?", "%#{self.name}%") unless self.name.blank?
      lti_databases = lti_databases.where("lti_databases.iss like ?", "%#{self.iss}%") unless self.iss.blank?
      return lti_databases.order(:name)
    end
  end
end