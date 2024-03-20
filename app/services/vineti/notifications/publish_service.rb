# frozen_string_literal: true

module Vineti::Notifications
  class PublishService
    attr_accessor :event_name,
                  :publish_type,
                  :event_data,
                  :headers,
                  :persist_transaction

    def initialize(event_name, publish_type, event_data, headers, persist_transaction)
      @event_name = event_name
      @publish_type = publish_type
      @event_data = event_data
      @persist_transaction = persist_transaction
      @headers = headers
    end

    def process
      if persist_transaction
        event_transaction = persist_event_notification_transaction
        @event_data[:parent_transaction_id] = event_transaction.id
        headers['X-transaction-id'] = event_transaction.transaction_id
      end

      headers[:persistent] = true
      publishing_method = "to_#{publish_type}"
      result = ::EventServiceClient::Publish.send(publishing_method, event_name, event_data, headers)

      if result[:success]
        event_transaction&.update!(status: "SUCCESS")
        Vineti::Notifications::ActivemqPublishSuccessResponse.new(result: result)
      else
        event_transaction&.update!(status: "ERROR")
        error_message = "Error occurred while publishing message to the topic in ActiveMQ"
        retrying_message = ' Will retry automatically in few minutes as the message is persistent'
        retrying_message = ' Will not retry as the message is set as persistent=false' if persist_transaction == false
        Airbrake.notify("#{error_message} #{retrying_message}", error: result[:error], transaction_id: event_transaction&.transaction_id, event_name: event_name)
        Rails.logger.error("#{error_message} - #{result[:error]} #{retrying_message}")
        Vineti::Notifications::ActivemqPublishErrorResponse.new(result[:error])
      end
    end

    private

    def persist_event_notification_transaction
      event = Vineti::Notifications::Event.find_or_create_by(name: event_name)
      transaction_id = headers['X-transaction-id'] || SecureRandom.uuid

      Vineti::Notifications::EventTransaction.create!(
        transaction_id: transaction_id,
        payload: event_data,
        event: event,
        status: "CREATED"
      )
    end
  end
end
