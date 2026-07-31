class NumericalityWithCodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    code = options[:code]

    num =
      begin
        Float(value)
      rescue ArgumentError, TypeError
        nil
      end

    if num.nil?
      record.errors.add(attribute, :not_a_number, code: code)
      return
    end

    if options.key?(:greater_than) && !(num > options[:greater_than])
      record.errors.add(attribute, :greater_than, count: options[:greater_than], code: code)
    end

    if options.key?(:less_than) && !(num < options[:less_than])
      record.errors.add(attribute, :less_than, count: options[:less_than], code: code)
    end

    if options[:only_integer] && (num % 1 != 0)
      record.errors.add(attribute, :not_an_integer, code: code)
    end
  end
end
