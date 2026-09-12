class LTIOrgImportRow
  include ::SelectableAttr::Base
  include ActiveModel::Model
  include LTIOrgImportRowCustomFieldAccessors

  attr_accessor :parent_org_cd
  attr_accessor :parent_org_id
  attr_accessor :org_div_name
  attr_accessor :org_div
  attr_accessor :org_cd
  attr_accessor :org_id
  attr_accessor :org_name
  attr_accessor :import_rows

  selectable_attr :edit_div do
    entry 'ADD', :add, '追加'
    entry 'EDIT', :edit, '編集'
    entry 'DEL', :del, '削除'
  end

  validates :edit_div, presence: true
  validates :edit_div, inclusion: {in: ::LTIOrgImportRow.edit_div_ids}

  validates :org_cd, presence: true
  validates :org_name, presence: true, if: Proc.new { |x| [:add, :edit].include?(x.edit_div_key) }
  validates :org_div_name, presence: true, if: Proc.new { |x| [:add, :edit].include?(x.edit_div_key) }
  validates :parent_org_cd, presence: true, if: Proc.new { |x| [:add, :edit].include?(x.edit_div_key) }

  validate :validate_csv

  def self.org_div_from_value(value)
    raw = value.to_s.strip
    return nil if raw.blank?
    return raw if ::LTIOrg.org_div_ids.include?(raw)

    entry = ::LTIOrg.org_div_entries.find do |e|
      e.name == raw || e.key.to_s.casecmp?(raw)
    end
    entry.try(:id)
  end

  def self.org_div_sort_order(org_div)
    case org_div
    when ::LTIOrg.org_div_id_by_key(:root) then 0
    when ::LTIOrg.org_div_id_by_key(:institution) then 1
    when ::LTIOrg.org_div_id_by_key(:department) then 2
    when ::LTIOrg.org_div_id_by_key(:course) then 3
    else
      99
    end
  end

  def validate_csv
    if self.edit_div_key == :add
      if ::LTIOrg.where(org_cd: self.org_cd).first
        self.errors.add(:org_cd, I18n.t(:"views.lti_org_imports.messages.already_exists"))
      end
    elsif [:edit, :del].include?(self.edit_div_key)
      unless ::LTIOrg.where(org_cd: self.org_cd).first
        self.errors.add(:org_cd, I18n.t(:"views.lti_org_imports.messages.no_exists_org_cd"))
      end
    end

    if self.org_cd.present? && Array(self.import_rows).count { |row| row.org_cd == self.org_cd } > 1
      self.errors.add(:org_cd, I18n.t(:"views.lti_org_imports.messages.duplicate_org_cd"))
    end

    if [:add, :edit].include?(self.edit_div_key)
      if self.org_div.blank?
        self.errors.add(:org_div_name, I18n.t(:"views.lti_org_imports.messages.invalid_org_div"))
      end

      if self.org_cd.present? && self.parent_org_cd.present? && self.org_cd == self.parent_org_cd
        self.errors.add(:parent_org_cd, I18n.t(:"views.lti_org_imports.messages.cannot_parent_self"))
      elsif self.parent_org_cd.present? && self.parent_org_id.blank?
        parent_in_file = Array(self.import_rows).any? do |row|
          row.object_id != self.object_id &&
            row.org_cd == self.parent_org_cd &&
            row.edit_div_key == :add
        end
        unless parent_in_file
          self.errors.add(:parent_org_cd, I18n.t(:"views.lti_org_imports.messages.no_exists_parent_org_cd"))
        end
      end
    end

    if self.class.database_ready_for_lti_org_import_row_custom_fields?
      self.class.lti_org_import_row_custom_field_definitions.each do |cf|
        next if cf.format_regexp.blank?

        value = send(cf.field_name)
        next if value.blank?

        unless value.to_s =~ /#{cf.format_regexp}/
          self.errors.add(cf.display_name.to_sym, I18n.t(:"activerecord.errors.messages.format_invalid"))
        end
      end
    end

    if self.errors.size > 0
      false
    else
      true
    end
  end
end
