module Vineti::Notifications
  class Events::Operation::PublishRetry < Trailblazer::Operation
    ERROR_CLASSES = [SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Net::ProtocolError, Timeout::Error, EOFError,
                     Errno::ECONNRESET].freeze
    step :init
    step :check_feature_flag_for_retry_enabled
    fail :feature_flag_disabled, fail_fast: true
    step :fetch_max_number_of_retries
    fail :handle_max_retries_count, fail_fast: true
    step :fetch_transactions
    fail :handle_transactions_not_found, fail_fast: true
    step Wrap(Vineti::Notifications::StepMacro::IterationWrapper) {
      step ->(options, _transactions:, index:, **) { options[:transaction] = options[:_transactions][index] }
      step :call_notification_retry_operation
      step :process_unsuccesful_response
      fail :handle_activemq_down, fail_fast: true
      step :update_count
      fail :handle_update_failed
      step :process_successful_response
    }

    def init(options, **)
      options[:errors] = []
    end

    def check_feature_flag_for_retry_enabled(options, **)
      options[:feature_flag_enabled] = Vineti::Notifications::Config.instance.fetch('vineti_activemq_retry_enable', true)
      options[:feature_flag_enabled] == true
    end

    def feature_flag_disabled(options, **)
      options[:status] = 501
      options[:errors] = { message: 'Feature Flag for retry is disabled' }
    end

    def fetch_max_number_of_retries(options, **)
      options[:max_retries] = Vineti::Notifications::Config.instance.fetch('vineti_failed_event_retry_max_count') || 5
      options[:max_retries].positive?
    end

    def handle_max_retries_count(options, **)
      options[:status] = 200
      options[:errors] = { message: "Max retries is set to #{options[:max_retries]}" }
    end

    def fetch_transactions(options, **)
      options[:_transactions] = Vineti::Notifications::EventTransaction.failed_publish_events(options[:max_retries])
      options[:count] = options[:_transactions].count
      options[:_transactions].present?
    end

    def handle_transactions_not_found(options, **)
      options[:status] = 422
      options[:errors] = { message: 'Failed Published transactions not found' }
    end

    def call_notification_retry_operation(options, transaction:, **)
      event_name = transaction&.event&.name
      retry_params = { transaction_id: transaction.transaction_id, event_name: event_name }
      options[:event_name] = event_name
      options[:op_response] = Vineti::Notifications::Events::Operation::NotificationRetry.call(
        params: retry_params
      )
    end

    def update_count(options, transaction:, **)
      retry_count = transaction.retries_count + 1
      options[:success] = transaction.update(retries_count: retry_count)
      options[:success]
    end

    def handle_update_failed(options, **)
      options[:status] = 500
      options[:errors] = { message: options[:success] }
    end

    def process_successful_response(options, transaction:, op_response:, **)
      return unless op_response.success?

      transaction&.update!(status: "SUCCESS")
    end

    def process_unsuccesful_response(options, transaction:, op_response:, **)
      active_mq_up = true
      if op_response[:errors].present? && op_response[:errors].any? { |error| ERROR_CLASSES.include?(error.class) }
        active_mq_up = false
      end
      active_mq_up
    end

    def handle_activemq_down(options, transaction:, op_response:, event_name:, **)
      options[:status] = 500
      Airbrake.notify(
        'Error occurred while publishing message to the topic in ActiveMQ while retrying. | ActiveMQ seems down!',
        error: op_response[:errors],
        transaction_id: transaction.transaction_id,
        event_name: event_name
      )
      options[:errors] << { message: 'ActiveMQ is down!' }
    end
  end
end
