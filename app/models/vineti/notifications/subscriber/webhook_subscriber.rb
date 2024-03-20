# frozen_string_literal: true

module Vineti::Notifications
  class Subscriber::WebhookSubscriber < Vineti::Notifications::Subscriber
    # NOTE:
    # this file/class will not be reloaded in development due to
    # explicit require in initializers/activemq

    validate :data_json
    validate :subscriberId

    private

    def subscriberId
      errors.add(:subscriber_id, 'webhook type subscriber_id should not start with internal-') if subscriber_id =~ /^internal-subscriber/
    end

    def data_json
      unless data
        errors.add(:data, 'Missing json information for subscription')
        return
      end
      errors.add(:data, 'Missing webhook url in json data') if data['webhook_url'].blank?
      errors.add(:data, 'Missing vault_key in json data') if data['vault_key'].blank?
    end
  end
end
