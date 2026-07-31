module LTIDatabases
  class SearchConditions
    include ActiveModel::Model
    attr_accessor :sites, :name, :iss
    attr_accessor :current_admin_user

    def search
      lti_databases = LTIDatabase.joins(:lti_database_sites)
      admin_user_sites = self.sites.to_a.empty? ? Site.active.where(id: self.current_admin_user.sites.map(&:id)).all.to_a : self.sites
      lti_databases = lti_databases.where("lti_database_sites.site_id in (?)", admin_user_sites)
      lti_databases = lti_databases.where("lti_databases.name like ?", "%#{self.name}%") unless self.name.blank?
      lti_databases = lti_databases.where("lti_databases.iss like ?", "%#{self.iss}%") unless self.iss.blank?
      return lti_databases.order(:name)
    end
  end
end