module Vineti::Notifications
  class Inbound::Operation::Create < Trailblazer::Operation
    LIQUID_ERROR = 'Liquid error'.freeze
    INBOUND_REQUEST = true

    step :params_present?
    fail :invalid_params, fail_fast: true
    step :init!
    step :build_params!
    step :fetch_publisher_by_token
    fail :handle_publisher_not_found, fail_fast: true
    step :fetch_event_by_name
    fail :handle_event_not_found, fail_fast: true
    step Rescue {
      step :fetch_publisher_subscriber
      fail :create_subscriber, Output(:success) => Track(:success)
    }
    fail :handle_subscriber_failure, fail_fast: true
    step Rescue {
      step :check_event_subscriber
      fail :create_event_subscriber, Output(:success) => Track(:success)
    }
    fail :handle_event_subscriber_failure, fail_fast: true
    step :fetch_and_parse_template!
    fail :handle_parse_error!, fail_fast: true
    step :persist_event_transaction_with_publisher
    fail :handle_transaction_error, fail_fast: true
    step :publish_to_activemq!
    fail :handle_publish_failure, fail_fast: true

    def params_present?(options, params:, publisher_token:, **)
      options[:errors] = []
      options[:errors] << { event_name: "parameter is required" } if params[:event_name].blank?
      options[:errors] << { orchestrator: "parameter is required" } if params[:orchestrator].blank?
      options[:errors] << { publisher_token: "header is required" } if publisher_token.blank?
      options[:errors].blank?
    end

    def invalid_params(options, **)
      options[:status] = 422
    end

    # Expected headers structure by EventServiceClient::Publish
    # {
    #   'X-transaction-id': 'xyz'
    # }

    def init!(options, current_user:, params:, **)
      options[:data] = {}
      options[:headers] = {}
      options[:data] = {}
    end

    def build_params!(options, current_user:, params:, **)
      options[:data][:inbound_request] = INBOUND_REQUEST
      options[:data][:uid] = current_user.uid
      options[:data][:orchestrator] = params[:orchestrator]
    end

    def fetch_publisher_by_token(options, data:, publisher_token:, **)
      options[:publisher] = Publisher.find_by("data->>'token' = ?", publisher_token)
      options[:data][:publisher_id] = options[:publisher].try(:publisher_id)
      options[:publisher].present?
    end

    def handle_publisher_not_found(options, **)
      options[:status] = 404
      options[:errors] << { publisher: 'Publisher not found' }
    end

    def fetch_event_by_name(options, publisher:, params:, **)
      options[:event] = publisher.events.find { |e| e.name == params[:event_name] }
      options[:event].present?
    end

    def handle_event_not_found(options, params:, **)
      options[:status] = 404
      options[:errors] << { event: "#{params[:event_name]} Event not found" }
    end

    def fetch_publisher_subscriber(options, publisher:, event:, **)
      options[:subscriber_id] = Vineti::Notifications::Subscriber.internal_api_subscriber_id(event.name)
      options[:subscriber] = Vineti::Notifications::Subscriber::InternalApiSubscriber.find_by(subscriber_id: options[:subscriber_id])
      options[:subscriber].present?
    end

    def create_subscriber(options, event:, subscriber_id:, **)
      options[:subscriber] = Vineti::Notifications::Subscriber::InternalApiSubscriber.create!(subscriber_id: subscriber_id)
      options[:subscriber].events << event
    rescue Exception => e
      options[:errors] << e.message
      false
    end

    def handle_subscriber_failure(options, **)
      options[:status] = 500
    end

    def check_event_subscriber(options, subscriber:, event:, **)
      subscriber.events.include?(event)
    end

    def create_event_subscriber(options, event:, subscriber:, **)
      options[:subscriber].events << event
    rescue Exception => e
      options[:errors] << e.message
      false
    end

    def handle_event_subscriber_failure(options, **)
      options[:status] = 500
    end

    def fetch_and_parse_template!(options, publisher:, params:, **)
      result = Inbound::Operation::ParseTemplate.call(
        publisher: publisher,
        template_data: params[:template_data]
      )
      result.success? ? options[:data][:template_data] = result[:parsed_data] : options[:errors].concat(result[:errors])
      options[:errors].empty?
    end

    def handle_parse_error!(options, **)
      options[:errors] << "Encountered parsing error"
      options[:status] = 500
    end

    def persist_event_transaction_with_publisher(options, publisher:, params:, subscriber:, **)
      transaction_id = SecureRandom.uuid
      transaction = Vineti::Notifications::EventTransaction.create!(
        transaction_id: transaction_id,
        payload: params,
        status: "CREATED",
        publisher: publisher,
        subscriber: subscriber,
        event: options[:event]
      )
      options[:transaction] = transaction
      options[:headers][:'X-transaction-id'] = transaction_id
      options[:headers][:persistent] = true
    rescue Exception => e
      options[:errors] << e.message
      false
    end

    def handle_transaction_error(options, **)
      options[:status] = 500
      options[:errors] << "Fail to create the event transaction record"
    end

    def publish_to_activemq!(options, data:, headers:, event:, transaction:, **)
      result = ::EventServiceClient::Publish.to_virtual_topic(event.name, data, headers)
      if result[:success]
        options[:message_id] = result
        options[:status] = 200
        transaction&.update!(status: "SUCCESS")
        true
      else
        options[:errors] << result[:error]
        transaction&.update!(status: "ERROR")
        false
      end
    end

    def handle_publish_failure(options, **)
      options[:status] = 500
    end
  end
end
