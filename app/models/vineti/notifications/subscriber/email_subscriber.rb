# frozen_string_literal: true

module Vineti::Notifications
  class Subscriber::EmailSubscriber < Vineti::Notifications::Subscriber
    # NOTE:
    # this file/class will not be reloaded in development due to
    # explicit require in initializers/activemq

    validate :valid_email_data?
    validate :validate_template?
    validate :subscriberId

    belongs_to :template,
               class_name: 'Vineti::Notifications::Template',
               foreign_key: 'vineti_notifications_templates_id'

    private

    def validate_template?
      errors.add(:template, 'is invalid') if template.nil?
    end

    def subscriberId
      errors.add(:subscriber_id, 'email type subscriber_id should not start with internal-') if subscriber_id =~ /^internal-subscriber/
    end

    def valid_email_data?
      unless data
        add_error('Missing json data for email subscription')
        return
      end

      %w[to_addresses from_address].each do |key|
        add_error("Missing #{key} from json data") if data[key].blank?
      end

      add_error("#{data['from_address']} in from_address is not a valid email address") if data['from_address'].present? && !data['from_address']&.match?(URI::MailTo::EMAIL_REGEXP)

      %w[to_addresses cc_addresses bcc_addresses].each do |key|
        data[key]&.each do |address|
          if invalid_email?(address) && invalid_user_role?(address)
            add_error("#{address} in #{key} is neither a valid email address nor a valid user role")
          end
        end
      end
    end

    def invalid_email?(address)
      !address&.match?(URI::MailTo::EMAIL_REGEXP)
    end

    def invalid_user_role?(address)
      # TODO: More coupling to the vineti-platform
      UserRole.where(name: address).blank?
    end

    def add_error(msg)
      errors.add(:data, msg)
    end
  end
end
