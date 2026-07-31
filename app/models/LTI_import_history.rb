class LTIImportHistory < ApplicationRecord
  include ::SelectableAttr::Base

  before_create :created_userstamp
  before_update :updated_userstamp
  after_destroy :destroyed_userstamp

  belongs_to :target, polymorphic: true, optional: true

  has_one :delayed_job, class_name: "::Delayed::Job", primary_key: "provider_job_id", foreign_key: "id"

  attr_accessor :current_admin_user

  selectable_attr :target_type do
    entry 'LmsUserImport', :lms_user_imports, 'LMSユーザ'
    entry 'LTIReflectionParticipantImport', :lti_reflection_participant_imports, '振り返り参加者'
    entry 'LTIShowcaseParticipantImport', :lti_showcase_participant_imports, 'ショーケース参加者'
  end

  def import_type_name
    self.target_type_name
  end


  def file_name
    result = ""
    case self.target_type_key
    when :lms_user_imports
      result = self.target.lms_user_import_attachments.first.try(:filename)
    when :lti_reflection_participant_imports
      result = self.target.lti_reflection_participant_import_attachments.first.try(:filename)
    when :lti_showcase_participant_imports
      result = self.target.lti_showcase_participant_import_attachments.first.try(:filename)
    end

    result
  end

  def user_name
    admin_user = AdminUser.where(id: self.creator_id).first
    lms_user = LmsUser.where(admin_user_id: admin_user.id).first if admin_user
    lms_user.try(:name)
  end
  def status_message
    import_errors = self.import_errors
    if self.delayed_job.blank? && import_errors.blank?
      result = I18n.t(:"activerecord.attributes.lti_import_history.message.finished")
    else
      result = import_errors.present? ? I18n.t(:"activerecord.attributes.lti_import_history.message.error") : I18n.t(:"activerecord.attributes.lti_import_history.message.processing")
    end
    result
  end

  def import_errors
    result = []
    case self.target_type_key
    when :lms_user_imports
      result = self.target.lms_user_import_errors
    when :lti_reflection_participant_imports
      result = self.target.lti_reflection_participant_import_errors
    when :lti_showcase_participant_imports
      result = self.target.lti_showcase_participant_import_errors
    end
    result
  end
end
