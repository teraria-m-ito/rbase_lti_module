module LTI
  module Orgs
    class SearchConditions
      include ActiveModel::Model
      include ::SelectableAttr::Base
    
      attr_accessor :page

      attr_accessor :org_cd
      attr_accessor :org_name
      attr_accessor :org_div
      attr_accessor :parent_org_id
      
      attr_accessor :sort_condition

      def search
        orgs = ::LTIOrg
        
        #組織CD
        orgs = orgs.where("org_cd like ?", "#{self.org_cd}%") if self.org_cd.present?

        #組織名
        orgs = orgs.where("org_name like ?", "%#{self.org_name}%") if self.org_name.present?

        #組織区分
        orgs = orgs.where(org_div: self.org_div) if self.org_div.present?
        
        #学科（親組織ID)
        orgs = orgs.where(parent_org_id: self.parent_org_id) if self.parent_org_id.present?

        # ソート設定
        if self.sort_condition.present?
          self.sort_condition.each do |k ,v|
            case k
            when :org_cd then
              field_name = "lti_orgs.org_cd"
            when :org_name then
              field_name = "lti_orgs.org_name"
            when :org_div then
              keys = ::LTIOrg.org_div_keys
              key1 = keys.shift
              join_sql = "LEFT JOIN (SELECT '#{::LTIOrg.org_div_id_by_key(key1)}' AS id, '#{::LTIOrg.org_div_name_by_key(key1)}' AS name "
              keys.each do |key|
                join_sql = join_sql + "UNION SELECT '#{::LTIOrg.org_div_id_by_key(key)}' AS id, '#{::LTIOrg.org_div_name_by_key(key)}' AS name "
              end
              join_sql = join_sql + ") org_divs ON org_divs.id = lti_orgs.org_div"
              orgs = orgs.joins(join_sql)
              field_name = "org_divs.name"
            when :parent_org then
              join_sql = "LEFT JOIN (SELECT id, org_name FROM lti_orgs WHERE deleted_at IS NULL) parent ON lti_orgs.parent_org_id = parent.id"
              orgs = orgs.joins(join_sql)
              field_name = "parent.org_name"
            else
              field_name = k
            end

            if v[:direction] == :desc
              orgs = orgs.order("#{field_name} desc")
            elsif v[:direction] == :asc
              orgs = orgs.order("#{field_name}")
            end
          end
        else
          orgs = orgs.display_order.all
        end
        
        orgs
      end
    end
  end
end