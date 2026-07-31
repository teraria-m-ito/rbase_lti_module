
class PresenceWithCodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.present?
    code = options[:code]
    record.errors.add(attribute, :blank, code: code)
  end
end
