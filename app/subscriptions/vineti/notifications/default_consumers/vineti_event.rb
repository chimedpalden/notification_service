module Vineti::Notifications::DefaultConsumers
  class VinetiEvent
    # TODO: System event should not be configurable by sally
    SYSTEM_NOTIFICATION_TOPIC = 'system_notifications'.freeze # System Event

    def self.process(payload)
      headers = payload.headers
      body = payload.body

      validate_event_params(headers, body)
      event_class = body['type'].constantize
      event_attr = vineti_event_attr(headers, body)
      # TODO: vineti_notifications: This code created dependency on platform
      event_class.create!(event_attr)
    rescue StandardError => e
      Rails.logger.error("Error: #{e.inspect}")
      if Vineti::Notifications::Event.find_by(name: SYSTEM_NOTIFICATION_TOPIC).present?
        ::EventServiceClient::Publish.to_virtual_topic(SYSTEM_NOTIFICATION_TOPIC, template_data: { errors: e.message })
      end
    end

    def self.vineti_event_attr(headers, body)
      {
        transaction_id: headers['X-transaction-id'],
        type: body[:type],
        target_model_name: body[:target_model_name],
        performed_by: body[:performed_by],
        created_at: body[:created_at],
        event_details: body[:event_details],
        target_model_id_number: body[:target_model_id_number],
      }
    end

    def self.validate_event_params(headers, body)
      raise "X-transaction-id can't be blank" if headers['X-transaction-id'].nil?

      required_body_keys = %i[type target_model_name performed_by created_at]
      body_keys_present = required_body_keys.all? { |k| body&.key? k }

      return if body_keys_present

      missing_keys = required_body_keys.reject { |k| body&.key? k }
      raise "Following keys are missing #{missing_keys}"
    end
  end
end
