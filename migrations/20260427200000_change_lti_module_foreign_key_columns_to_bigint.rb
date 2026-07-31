# frozen_string_literal: true

# rbase_lti_module 内の、他テーブル参照用 integer 型カラム（外部キー相当）を bigint に揃える
class ChangeLtiModuleForeignKeyColumnsToBigint < ActiveRecord::Migration[7.0]
  FKS = {
    lti_database_sites: %i[lti_database_id site_id],
    lms_user_sites: %i[lms_user_id site_id],
    lms_users: %i[lti_org_id inst_org_id dept_org_id course_org_id admin_user_id lms_user_id],
    lms_user_custom_fields: %i[lms_user_id custom_field_id],
    lms_user_import_attachments: %i[lms_user_import_id],
    lms_user_import_errors: %i[lms_user_import_id],
    lms_user_imports: %i[creator_id updater_id deleter_id],
    lti_import_histories: %i[target_id provider_job_id creator_id updater_id deleter_id],
    lti_operation_logs: %i[
      lms_user_id
      inst_org_id
      dept_org_id
      course_org_id
      operation_log_target_id
      creator_id
      updater_id
      deleter_id
    ],
    lti_orgs: %i[parent_org_id creator_id updater_id deleter_id],
    lti_usages: %i[creator_id updater_id deleter_id],
  }.freeze

  def up
    FKS.each do |table, columns|
      columns.each do |column|
        next unless column_exists?(table, column)
        # line_no, file_size 等の非外部キー integer には含めない
        change_column table, column, :bigint
      end
    end
  end

  def down
    FKS.each do |table, columns|
      columns.each do |column|
        next unless column_exists?(table, column)
        change_column table, column, :integer
      end
    end
  end
end
