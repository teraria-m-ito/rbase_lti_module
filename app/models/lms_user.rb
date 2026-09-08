class LmsUser < ApplicationRecord
  include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
  include ::SelectableAttr::Base
  include CustomFieldDynamicAccessors

  has_many :lms_user_sites, dependent: :destroy, autosave: true
  has_many :sites, :through => :lms_user_sites

  belongs_to :admin_user, class_name: '::AdminUser', optional: true

  # AdminUser のパスワード変更用（lms_users には保存しない）
  attr_accessor :password, :password_confirmation

  belongs_to :lti_org, class_name: '::LTIOrg', foreign_key: 'lti_org_id', optional: true
  belongs_to :inst_lti_org, class_name: '::LTIOrg', foreign_key: 'inst_org_id', optional: true
  belongs_to :dept_lti_org, class_name: '::LTIOrg', foreign_key: 'dept_org_id', optional: true
  belongs_to :course_lti_org, class_name: '::LTIOrg', foreign_key: 'course_org_id', optional: true

  scope :my_self, ->(lms_user) { where(id: lms_user.id).first}

  has_many :lms_user_custom_fields, dependent: :destroy, autosave: true, inverse_of: :lms_user

  has_many :custom_fields,
           -> { order('custom_fields.display_order ASC') },
           through: :lms_user_custom_fields

  accepts_nested_attributes_for :lms_user_custom_fields, reject_if: :all_blank
  validates_associated :lms_user_custom_fields

  custom_field_dynamic_accessors!(
    association: :lms_user_custom_fields,
    data_source: :lms_user_custom_fields,
    custom_field_scope: lambda {
      if ::CustomField.respond_to?(:lms_users)
        ::CustomField.lms_users
      else
        ::CustomField.where(custom_field_type: "lms_user").order(:display_order)
      end
    }
  )

  validates :site_ids, presence: true
  validates :username, presence: true, uniqueness: true
  validates :name, presence: true
  validates :email, presence: true
  validates :role, presence: true

  selectable_attr :role do
    entry 'SYSADMIN', "http://purl.imsglobal.org/vocab/lis/v2/system/person#SysAdmin", 'SysAdmin', role_name: "admin", role_div: "admin", prio: 10001
    entry 'ADMIN', "http://purl.imsglobal.org/vocab/lis/v2/system/person#Administrator", 'Admin', role_name: "admin", role_div: "admin", prio: 10002

    entry 'FACULTY', "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Faculty", 'Faculty', role_name: "member", role_div: "admin", prio: 1001
    entry 'MANAGER', "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator", 'Manager', role_name: "MANAGER", role_div: "admin", prio: 1002

    #教職員系
    entry 'MEMTOR', "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Mentor", 'Mentor', role_name: "member", role_div: "teacher", prio: 101
    entry 'MEMBER', "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Member", 'Member', role_name: "member", role_div: "teacher", prio: 102
    entry 'STAFF', "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Staff", 'Staff', role_name: "member", role_div: "teacher", prio: 103
    entry 'INSTRUCTOR', "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Instructor", 'Instructor', role_name: "member", role_div: "teacher", prio: 104
    entry 'TEACHER', "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor", 'Teacher', role_name: "TEACHER", role_div: "teacher", prio: 105

    #学生系
    entry 'NONE', "http://purl.imsglobal.org/vocab/lis/v2/institution/person#None", 'None', role_name: "member", role_div: "student", prio: 1
    entry 'GUEST', "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Guest", 'Guest', role_name: "member", role_div: "student", prio: 2
    entry 'OTHER', "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Other", 'Other', role_name: "member", role_div: "student", prio: 3
    entry 'PROSPECTIVESTUDENT', "http://purl.imsglobal.org/vocab/lis/v2/institution/person#ProspectiveStudent", 'ProspectiveStudent', role_name: "member", role_div: "student", prio: 4 #受験生
    entry 'OBSERVER', "http://purl.imsglobal.org/vocab/lis/v2/system/person#Observer", 'Observer', role_name: "member", role_div: "student", prio: 5
    entry 'USER', "http://purl.imsglobal.org/vocab/lis/v2/system/person#User", 'User', role_name: "member", role_div: "student", prio: 6
    entry 'ALUMNI', "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Alumni", 'Alumni', role_name: "ALUMNI", role_div: "almuni", prio: 7 #卒業生
    entry 'STUDENT', "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student", 'Student', role_name: "STUDENT", role_div: "student", prio: 8
    entry 'LEARNER', "http://purl.imsglobal.org/vocab/lis/v2/membership#Learner", 'Learner', role_name: "STUDENT", role_div: "student", prio: 9
  end

  def self.normalize_lti_role_uri(uri)
    uri.to_s.strip.sub(/\Ahttp:/i, "https:")
  end

  def self.select_lti_role(roles)
    return nil if roles.blank?

    prio = 0
    result = nil
    roles.each do |role|
      normalized = normalize_lti_role_uri(role)
      target = ::LmsUser.role_enum.find { |x| normalize_lti_role_uri(x.key) == normalized }
      next if target.nil?

      if prio < target[:prio]
        result = target
        prio = target[:prio]
      end
    end
    result
  end

  def admin_role_id_for_lti(default_role_div)
    candidates = []
    entry = self.role_entry
    if entry.present?
      candidates << entry[:role_name].to_s if entry[:role_name].present?
      case entry[:role_div].to_s
      when "student"
        candidates << "STUDENT"
      when "teacher", "admin"
        candidates << "TEACHER"
      end
    end
    candidates << default_role_div.to_s if default_role_div.present?
    candidates.concat(%w[STUDENT TEACHER member])
    candidates.map(&:strip).reject(&:blank?).uniq.each do |short_name|
      role = ::Role.find_by(role_short_name: short_name)
      return role.id if role
    end

    raise "Role not found for LMS user (role=#{self.role.inspect})"
  end

  def create_admin_user(role_update = false)
    admin_user = ::AdminUser.where(email: self.email).first
    admin_user = admin_user || ::AdminUser.where(name: self.username).first

    unless admin_user
      admin_user = ::AdminUser.new(email: self.email, name: self.username)
    end
    admin_user.site_ids =self.site_ids

    role_divs = admin_user.site_ids.inject([]){|arry, site_id| arry << ::SystemSetting.get_setting(:default_role_div, site_id)}
    if role_divs.size != 1
      raise "Must one type role_div each sites."
    end

    role_div = ::SystemSetting.get_setting(:default_role_div,admin_user.site_ids.first)
    if role_update
      admin_user.role_id = admin_role_id_for_lti(role_div)
    elsif admin_user.role.blank?
      admin_user.role_id = admin_role_id_for_lti(role_div)
    end

    admin_user.status_div_key = :accepted
    admin_user.password = SecureRandom.urlsafe_base64 if admin_user.new_record?

    admin_user.valid?
    if admin_user.errors.size > 0
      ::Rails.logger.error("admin_user error:#{admin_user.errors.full_messages}")
    end
    admin_user.save!
    
    admin_user
  end

  def create_admin_user_for_import
    admin_user = ::AdminUser.where(email: self.email).first || ::AdminUser.new(email: self.email)
    admin_user.name = self.name
    admin_user.site_ids =self.site_ids

    role_name = role_entry[:role_name]
    admin_user.role = ::Role.find_by!(role_short_name: role_name)
    admin_user.status_div_key = :accepted
    admin_user.password = SecureRandom.urlsafe_base64 if admin_user.new_record?

    admin_user.save!

    admin_user
  end

  def destroy_lms_user
    if self.admin_user
      if self.admin_user.destroy
        self.destroy
      else
        false
      end
    end
  end

  def is_student?
    ["LEARNER", "STUDENT", "ALUMNI"].include?(self.role)
  end

  def is_almuni?
    ["ALUMNI"].include?(self.role)
  end

  def is_teacher?
    ["TEACHER"].include?(self.role)
  end

  def is_admin?
    ["ADMIN"].include?(self.role)
  end

  def get_lms_type
    ::Logic::MoodleLogic.get_lms_type(self.lms)
  end
end
