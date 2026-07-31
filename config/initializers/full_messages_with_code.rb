
module ErrorsWithCode
  def full_messages_with_code
    attribute_names.flat_map do |attr|
      details_list  = details[attr]  || []
      messages_list = messages[attr] || []

      details_list.zip(messages_list).map do |detail, msg|
        code = detail && detail[:code]
        code.present? ? "#{code}:#{attr} #{msg}" : full_message(attr, msg)
      end
    end
  end
end

Rails.application.config.to_prepare do
  klass = ActiveModel::Errors
  unless klass.ancestors.include?(ErrorsWithCode)
    klass.prepend(ErrorsWithCode)
  end
end
