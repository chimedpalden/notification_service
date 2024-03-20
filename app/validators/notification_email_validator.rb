# frozen_string_literal: true

class NotificationEmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if options[:optional]&.include?(attribute) && value.blank?

    record.errors.add(attribute, "Can't be blank, please specify valid value") if value.blank?
    if value.is_a?(Array)
      value&.each do |email|
        next if email&.to_s&.match?(URI::MailTo::EMAIL_REGEXP)

        record.errors.add(attribute, "#{email} in #{attribute} is not valid")
      end
    else
      return if value&.match?(URI::MailTo::EMAIL_REGEXP)

      record.errors.add(attribute, 'please add correct email address')
    end
  end
end
