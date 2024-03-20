module Vineti::Notifications::DefaultConsumers
  class BaseConsumer
    REQUIRED_HEADERS = %w[X-transaction-id X-subscriber-id httpResponseCode].freeze

    def self.validate_param(headers)
      valid_headers = REQUIRED_HEADERS.all? { |header| headers[header].present? }
      raise "Invalid Headers, Required headers - #{REQUIRED_HEADERS}" unless valid_headers

      valid_headers
    end

    def self.process_queue_response(queue_name, response, send_mail = false)
      Rails.logger.info("Reading message from #{queue_name} Queue : #{response}")
      validate_param(response.headers)

      transaction_id = response.headers['X-transaction-id']
      subscriber_id = response.headers['X-subscriber-id']
      response_code = response.headers['httpResponseCode'].to_s

      status = response_code == '200' ? 'SUCCESS' : 'ERROR'
      retries = response.headers['X-JMSXDeliveryCount'].to_i
      event_transaction = Vineti::Notifications::EventTransaction.find_by(transaction_id: transaction_id)
      return if event_transaction.blank?

      Rails.logger.info("\n---------Update transaction status with id #{transaction_id} -----------\n")
      update_hash = { response: response.body, status: status, response_code: response_code }
      update_hash[:retries_count] = retries unless send_mail
      event_transaction.update!(update_hash)
      return unless send_mail

      event_params = {
        event_name: 'send_failed_notification',
        template_data: {
          transaction_id: transaction_id,
          subscriber_id: subscriber_id,
        },
      }
      EventService.new(event_params).notify_subscribers
    end
  end
end
