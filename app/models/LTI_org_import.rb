require 'csv'
require 'roo'

class LTIOrgImport < ApplicationRecord
  self.table_name = "lti_org_imports"
  include ApplicationConcern

  before_create :created_userstamp
  before_update :updated_userstamp
  after_destroy :destroyed_userstamp

  include ::SelectableAttr::Base

  has_many :lti_org_import_attachments, class_name: '::LTIOrgImportAttachment', dependent: :destroy
  accepts_nested_attributes_for :lti_org_import_attachments

  has_many :lti_org_import_errors, class_name: '::LTIOrgImportError', dependent: :destroy

  has_one :import_history, as: :target, class_name: '::LTIImportHistory', dependent: :destroy

  attr_accessor :uuid
  attr_accessor :filename
  attr_accessor :current_admin_user

  validates :lti_org_import_attachments, presence: true

  def set_unique_key
    self.uuid = SecureRandom.hex
  end

  def self.lti_org_custom_fields
    if ::CustomField.respond_to?(:lti_orgs)
      ::CustomField.lti_orgs
    elsif ::CustomField.respond_to?(:custom_field_type_id_by_key)
      type_id = (::CustomField.custom_field_type_id_by_key(:lti_org) rescue nil)
      return ::CustomField.none if type_id.blank?

      ::CustomField.where(custom_field_type: type_id).order(:display_order)
    else
      ::CustomField.none
    end
  end

  def self.build_data(condition)
    result = []
    lti_orgs = condition.search.where.not(org_div: ::LTIOrg.org_div_id_by_key(:root))

    header = %w(
        編集区分 親組織CD 組織区分 組織CD 組織名
    )

    custom_fields = lti_org_custom_fields
    header = header + custom_fields.map { |custom_field| custom_field.display_name }
    result << header

    lti_orgs.each do |lti_org|
      form_column_value = [
        LTIOrgImportRow.edit_div_id_by_key(:edit),       #1:編集区分
        lti_org.parent_org.try(:org_cd),                 #2:親組織CD
        lti_org.org_div_name,                            #3:組織区分
        lti_org.org_cd,                                  #4:組織CD
        lti_org.org_name,                                #5:組織名
      ]
      custom_fields.each do |custom_field|
        form_column_value << (lti_org.respond_to?(custom_field.field_name) ? lti_org.send(custom_field.field_name) : nil)
      end

      result << form_column_value
    end
    result
  end

  def self.build_csv(data)
    bom = %w[EF BB BF].map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom, col_sep: ',', force_quotes: true, quote_char: '"') do |csv|
      data.each do |d|
        csv << d
      end
    end
    csv_data
  end

  def self.generate_xlsx(data)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet do |sheet|
        linebreak_style = sheet.styles.add_style(alignment: {wrap_text: true})
        data.each do |row|
          sheet.add_row row, types: Array.new(row.size, :string), style: linebreak_style
        end
        sheet.column_widths(*[20]*data.size)
      end
    end
  end

  def import_csv
    @lti_org_import_rows = []
    filepath = self.lti_org_import_attachments[0].document.path
    xlsx = Roo::Excelx.new(filepath)
    xlsx.default_sheet = xlsx.sheets[0]
    custom_fields = self.class.lti_org_custom_fields
    to_cell = lambda do |value|
      return nil if value.nil?
      if value.is_a?(Numeric) && value == value.to_i
        value.to_i.to_s
      else
        value.to_s.strip
      end
    end
    2.upto(xlsx.last_row) do |r_num|
      row = xlsx.row(r_num)
      lti_org_import_row = ::LTIOrgImportRow.new
      lti_org_import_row.edit_div = to_cell.call(row[0])
      lti_org_import_row.parent_org_cd = to_cell.call(row[1])
      lti_org_import_row.org_div_name = to_cell.call(row[2])
      lti_org_import_row.org_cd = to_cell.call(row[3])
      lti_org_import_row.org_name = to_cell.call(row[4])
      lti_org_import_row.org_div = ::LTIOrgImportRow.org_div_from_value(lti_org_import_row.org_div_name)

      if lti_org_import_row.parent_org_cd.present?
        parent_org = ::LTIOrg.where(org_cd: lti_org_import_row.parent_org_cd).first
        lti_org_import_row.parent_org_id = parent_org.id unless parent_org.nil?
      end

      if lti_org_import_row.org_cd.present?
        lti_org = ::LTIOrg.where(org_cd: lti_org_import_row.org_cd).first
        lti_org_import_row.org_id = lti_org.id unless lti_org.nil?
      end

      custom_fields.each_with_index do |custom_field, i|
        cell = row[5 + i]
        lti_org_import_row.send("#{custom_field.field_name}=", cell.nil? ? nil : to_cell.call(cell))
      end

      ::Rails.logger.info("[組織インポート]load #{lti_org_import_row.edit_div} / #{lti_org_import_row.org_cd}")

      @lti_org_import_rows << lti_org_import_row
    end

    @lti_org_import_rows.each { |lti_org_import_row| lti_org_import_row.import_rows = @lti_org_import_rows }

    @lti_org_import_rows.each_with_index do |lti_org_import_row, index|
      ::Rails.logger.info("[組織インポート](#{index+1}/#{@lti_org_import_rows.size})valid #{lti_org_import_row.edit_div} / #{lti_org_import_row.org_cd}")
      unless lti_org_import_row.valid?
        lti_org_import_error = ::LTIOrgImportError.new({line_no: index+2, error_message: lti_org_import_row.errors.full_messages.join("\n")})
        self.lti_org_import_errors << lti_org_import_error unless lti_org_import_error.nil?
      end
    end

    if self.lti_org_import_errors.empty?
      if self.save
        save_lti_orgs
        return true
      else
        self.errors.add(:base, I18n.t(:"activerecord.errors.messages.fail_import"))
      end
    end
    false
  end

  def self.apply_lti_org_custom_fields_from_import_row(lti_org, import_row)
    lti_org_custom_fields.each do |cf|
      next unless lti_org.respond_to?("#{cf.field_name}=")

      lti_org.send("#{cf.field_name}=", import_row.send(cf.field_name))
    end
  end

  private

  def save_lti_orgs
    ::Rails.logger.info("[組織インポート]開始")

    ::LTIOrg.transaction do
      indexed_rows = @lti_org_import_rows.each_with_index.to_a
      add_edit_rows = indexed_rows.select { |lti_org_import_row, _index| [:add, :edit].include?(lti_org_import_row.edit_div_key) }
      add_edit_rows = add_edit_rows.sort_by { |lti_org_import_row, index| [::LTIOrgImportRow.org_div_sort_order(lti_org_import_row.org_div), index] }
      del_rows = indexed_rows.select { |lti_org_import_row, _index| lti_org_import_row.edit_div_key == :del }.reverse

      (add_edit_rows + del_rows).each do |lti_org_import_row, index|
        case lti_org_import_row.edit_div_key
        when :add, :edit
          operation = lti_org_import_row.edit_div_key.to_s.upcase
          ::Rails.logger.info("[組織インポート](#{index+1}/#{@lti_org_import_rows.size})#{operation}:#{lti_org_import_row.org_cd}")
          lti_org =
            if lti_org_import_row.edit_div_key == :add
              ::LTIOrg.new
            else
              ::LTIOrg.find_by!(org_cd: lti_org_import_row.org_cd)
            end

          if lti_org_import_row.parent_org_cd.present?
            parent_org = ::LTIOrg.where(org_cd: lti_org_import_row.parent_org_cd).first
            lti_org_import_row.parent_org_id = parent_org.try(:id)
          end

          lti_org.org_cd = lti_org_import_row.org_cd
          lti_org.org_name = lti_org_import_row.org_name
          lti_org.org_div = lti_org_import_row.org_div
          lti_org.parent_org_id = lti_org_import_row.parent_org_id
          lti_org.current_admin_user = current_admin_user
          self.class.apply_lti_org_custom_fields_from_import_row(lti_org, lti_org_import_row)

          raise "fail save #{lti_org_import_row.org_cd}" unless lti_org.save_org
        when :del
          ::Rails.logger.info("[組織インポート](#{index+1}/#{@lti_org_import_rows.size})DEL:#{lti_org_import_row.org_cd}")
          lti_org = ::LTIOrg.find_by!(org_cd: lti_org_import_row.org_cd)
          lti_org.current_admin_user = current_admin_user
          raise "fail destroy #{lti_org.org_cd}" unless lti_org.destroy
        end
      end
    end
    ::Rails.logger.info("[組織インポート]終了")
  end

  def self.import_lti_orgs(file_name, site_id)
    site_id = ::Site.first.id if site_id.nil?
    logging_task_log("[オフライン組織インポート]開始 file_name:#{file_name} site_id:#{site_id}")

    admin_role = Role.where(role_short_name: "admin").first
    admin_user = AdminUser.where(role_id: admin_role.id).first

    ActiveRecord::Base.transaction do
      lti_org_import = LTIOrgImport.new

      filepath = "#{::SystemSetting.get_setting(:offline_import_dir, site_id)}/#{file_name}"
      logging_task_log("[オフライン組織インポート]filepath:#{filepath}")
      f = File.open(filepath, "r")
      lti_org_import_attachment = LTIOrgImportAttachment.new
      lti_org_import_attachment.filename = file_name
      lti_org_import_attachment.save!
      lti_org_import_attachment.reload
      lti_org_import_attachment.document.store!(f)

      lti_org_import.current_admin_user = admin_user

      lti_org_import.save!(validate: false)

      lti_org_import_attachment.lti_org_import_id = lti_org_import.id
      lti_org_import_attachment.save!

      import_history = LTIImportHistory.new
      import_history.target = lti_org_import
      import_history.current_admin_user = admin_user
      import_history.save!

      result = ::LTI::LtiOrgImportJob.perform_later(lti_org_import.id)

      import_history.provider_job_id = result.instance_of?(Integer) ? result : result.provider_job_id
      import_history.save!

      FileUtils.rm_f(filepath)
      logging_task_log("[オフライン組織インポート]終了")
    end
  end
end
