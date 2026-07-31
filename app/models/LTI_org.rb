class LTIOrg < ApplicationRecord
  self.table_name = "lti_orgs"

  before_create :created_userstamp
  before_update :updated_userstamp
  after_destroy :destroyed_userstamp
  
  has_ancestry
  
  include ::SelectableAttr::Base
    
  belongs_to :parent_org, class_name: 'LTIOrg', foreign_key: 'parent_org_id', optional: true
    
  has_many :lti_input_category_lti_orgs, class_name: '::LTIInputCategoryLtiOrg', foreign_key: 'lti_org_id', dependent: :destroy
  has_many :lti_input_categories, class_name: '::LTIInputCategory', through: :lti_input_category_lti_orgs

  scope :display_order, -> { order(:org_cd) }

  attr_accessor :current_admin_user

  validates :org_cd, presence: true
  validates :org_name, presence: true
  validates :org_div, presence: true
  validates :parent_org_id, presence: true

  selectable_attr :org_div do
    entry 'ROOT', :root, '大学'
    entry 'INSTITUTION', :institution, '学部'
    entry 'DEPARTMENT', :department, '学科'
    entry 'COURSE', :course, 'コース'
  end
  
  #親属性一覧を取得
  def self.parent_list
    parents = []
    ::LTIOrg.all.each do |org|
      parents << org.id if org.has_children?
    end
    ::LTIOrg.where("id in (?)", parents).display_order
  end
  
  def self.dependents_list
    ::LTIOrg.where("org_div NOT IN (?)", [:course]).display_order
  end  
  
  #所属学部の取得
  def parent_institution
    depends_org = self
    while depends_org.present?
      if depends_org.org_div_key == :institution or depends_org.org_div_key == :root
        break
      end
      #親を取得
      depends_org = ::LTIOrg.where(id: depends_org.parent_org_id).first || nil
    end
    depends_org
  end
  
  #所属学科の取得
  def parent_department
    depends_org = self
    while depends_org.present?
      if depends_org.org_div_key == :department or depends_org.org_div_key == :root
        break
      end
      #親を取得
      depends_org = ::LTIOrg.where(id: depends_org.parent_org_id).first || nil
    end
    depends_org
  end
  
  #学部学科名からlti_orgを取得
  def self.get_lti_org(institution_name, department_name)
    return nil if institution_name.blank? || department_name.blank?
    result = nil
    depts = ::LTIOrg.where(org_name: department_name).where(org_div: ::LTIOrg.org_div_id_by_key(:department)).all
    depts.each do |dept|
      if dept.parent_institution.org_name == institution_name
        result = dept 
        break
      end
    end
    result
  end
  
  def save_org
    self.ancestry = self.self_parent_ids.join("/")
    self.save
  end

  def has_children?
    ::LTIOrg.where(parent_org_id: self.id).present?
  end
  
  private
  def self_parent_ids
    result = []
    target = self
    while target.parent_org_id != nil
      result << target.parent_org_id
      target = target.parent_org
    end
    result.reverse
  end
end
