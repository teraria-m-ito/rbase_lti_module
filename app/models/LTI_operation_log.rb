class LTIOperationLog < ApplicationRecord
  include ::Rbase::PluginModule::Extendable # 継承を許可する宣言（必須）
  self.table_name = "lti_operation_logs"

  before_create :created_userstamp

  include ::SelectableAttr::Base

  belongs_to :lms_user, optional: true
  belongs_to :inst_lti_org, class_name: '::LTIOrg', foreign_key: 'inst_org_id', optional: true
  belongs_to :dept_lti_org, class_name: '::LTIOrg', foreign_key: 'dept_org_id', optional: true
  belongs_to :course_lti_org, class_name: '::LTIOrg', foreign_key: 'course_org_id', optional: true

  belongs_to :input_category, optional: true

  belongs_to :operation_log_target, polymorphic: true, optional: true

  attr_accessor :current_admin_user

  selectable_attr :form_type do
    entry 'common', :common, '共通'
    update_with_plugins(:LTIOperationLog, :added_entries_for_form_type)
  end

  private
  def self.added_entries_for_form_type(mod); end
  public

  selectable_attr :operation_div do
    entry 'view', :view, '参照'
    entry 'created_or_updated', :created_or_updated, '登録/更新'
    entry 'deleted', :deleted, '削除'
    update_with_plugins(:LTIOperationLog, :added_entries_for_operation_div)
  end

  private
  def self.added_entries_for_operation_div(mod); end
  public

  def create_view_operation(form_type, instance, screen_name, description = nil)
    self.operation_div_key = :view
    create_operation(form_type, instance, screen_name, description)
  end

  def create_saved_operation(form_type, instance, screen_name, description = nil)
    self.operation_div_key = :created_or_updated
    create_operation(form_type, instance, screen_name, description)
  end

  def create_deleted_operation(form_type, instance, screen_name, description = nil)
    self.operation_div_key = :deleted
    create_operation(form_type, instance, screen_name, description)
  end

  private
  def create_operation(form_type, instance, screen_name, description)
    self.operated_at = Time.now
    self.form_type = ::LTIOperationLog.form_type_id_by_key(form_type) || form_type

    admin = get_current_admin_user
    self.current_admin_user = admin

    # LMSユーザ関連（ローカル管理ログイン等で current_lms_user が無い場合は管理ユーザで代用）
    target_lms_user = get_current_lms_user
    self.lms_user = target_lms_user

    if target_lms_user
      self.user_id = target_lms_user.username
      self.user_name = target_lms_user.name

      self.inst_lti_org = target_lms_user.inst_lti_org
      self.institution = target_lms_user.inst_lti_org.try(:org_name)

      self.dept_lti_org = target_lms_user.dept_lti_org
      self.department = target_lms_user.dept_lti_org.try(:org_name)
    elsif admin
      self.user_id = admin.email.to_s
      self.user_name = admin.try(:name).presence || admin.email.to_s
      self.inst_lti_org = nil
      self.institution = nil
      self.dept_lti_org = nil
      self.department = nil
    else
      self.user_id = "unknown"
      self.user_name = "unknown"
      self.inst_lti_org = nil
      self.institution = nil
      self.dept_lti_org = nil
      self.department = nil
    end

    # フォーム関連
    unless instance.nil?
      self.operation_log_target = instance
      self.operation_log_target_type = instance.class.name

      set_create_operation_log_target(instance)
    end

    self.screen_name = screen_name
    self.description = description

    self.save!
  end

  def set_create_operation_log_target(instance);end

end

