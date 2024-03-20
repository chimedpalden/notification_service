module Vineti::Notifications
  class Events::Operation::NotificationRetry < Trailblazer::Operation
    FAILED_TRANSACTION_STATUS = %w[WSO_ERROR ERROR].freeze

    step :init
    step :fetch_transaction
    fail :handle_transaction_not_found, fail_fast: true
    step :fetch_event
    fail :handle_event_not_found, fail_fast: true
    step :failed_transaction?
    fail :handle_transaction_not_failed, fail_fast: true
    step :publish_to_activemq!
    fail :handle_publish_failure, fail_fast: true

    def init(options, **)
      options[:errors] = []
    end

    def fetch_transaction(options, params:, **)
      options[:transaction] = Vineti::Notifications::EventTransaction.find_by(transaction_id: params[:transaction_id])
      options[:transaction].present?
    end

    def handle_transaction_not_found(options, **)
      options[:status] = 422
      options[:errors] << { transaction: 'Transaction not found' }
    end

    def fetch_event(options, transaction:, params:, **)
      options[:event] = transaction.event || Vineti::Notifications::Event.find_by(name: params[:event_name])
      options[:event].present?
    end

    def handle_event_not_found(options, params:, **)
      options[:status] = 422
      options[:errors] << { event: "Event not found" }
    end

    def failed_transaction?(options, transaction:, **)
      FAILED_TRANSACTION_STATUS.include? transaction.status
    end

    def handle_transaction_not_failed(options, **)
      options[:status] = 422
      options[:errors] << { transaction: 'Transaction does not have a failed status' }
    end

    def publish_to_activemq!(options, event:, transaction:, **)
      is_parent_transaction = transaction.parent_transaction_id.nil?
      event_data = is_parent_transaction ? transaction.payload : transaction.parent_transaction.payload
      subscriber = transaction.subscriber

      if subscriber.nil?
        headers = { 'X-transaction-id': transaction.transaction_id, persistent: true }
        event_data[:parent_transaction_id] = transaction.id
        result = ::EventServiceClient::Publish.to_virtual_topic(event.name, event_data, headers)

        if result[:success]
          transaction&.update!(status: "SUCCESS") if is_parent_transaction
          options[:result] = result
          options[:status] = 200
          true
        else
          options[:errors] << result[:error]
          transaction&.update!(status: "ERROR") if is_parent_transaction
          false
        end
      else

        result = execute_subscriber_service(subscriber, event, event_data, transaction)
        if result.class.to_s.end_with?("ErrorResponse")
          options[:errors] << result.message
          false
        else
          options[:result] = result
          options[:status] = 200
          true
        end
      end
    end

    def handle_publish_failure(options, **)
      options[:status] = 500
    end

    private

    def execute_subscriber_service(subscriber, event, event_data, transaction)
      if subscriber.email_subscriber?
        Vineti::Notifications::Subscriber::EmailService.new(
          topic: event,
          template_data: event_data["template_data"],
          delayed_time: event_data["delayed_time"],
          metadata: event_data["metadata"],
          retry_transaction_id: transaction.transaction_id
        ).send_notification_to_subscriber(subscriber)
      elsif subscriber.webhook_subscriber?
        Vineti::Notifications::Subscriber::WebhookService.new(
          topic: event,
          payload: event_data['payload'],
          subscriber: subscriber,
          metadata: event_data['metadata'],
          retry_transaction_id: transaction.transaction_id
        ).send_notification
      end
    end
  end
end
