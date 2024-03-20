# frozen_string_literal: true

require 'stomp'

module Vineti::Notifications
  class InternalApiSubscription
    # NOTE:
    # this file/class will not be reloaded in development due to
    # explicit require in initializers/activemq

    attr_reader :host, :port, :ssl, :login, :password

    def self.create_active_subscriptions
      Vineti::Notifications::Subscriber::InternalApiSubscriber.all.each do |subscriber|
        subscriber.events.each do |event|
          ::EventServiceClient::Subscribe.to_virtual_topic(event.name, subscriber.subscriber_id) do |response|
            execute_on_publish(response)
          end
        end
      end
    end

    def self.create_subscription_for(subscriber)
      subscriber.events.each do |event|
        create_event_subscriber(event, subscriber)
      end
    end

    def self.create_event_subscriber(event, subscriber)
      ::EventServiceClient::Subscribe.to_virtual_topic(event.name, subscriber.subscriber_id) do |response|
        execute_on_publish(response)
      end
    end

    def self.execute_on_publish(response)
      headers = response.headers
      response_body = response.body
      for_redelivery = headers["redelivered"] == "true"
      return unless response_body['inbound_request']

      STDOUT.puts("======================Got Response from AMQ #{response}================")
      current_user = User.find_by!(uid: response_body['uid'])
      publisher = Publisher.find_by(publisher_id: response_body['publisher_id'])
      result = Orchestrator::Operation::Orchestrate.call(
        params: response_body["orchestrator"],
        current_user: current_user
      )
      transaction = Vineti::Notifications::EventTransaction.find_by!(transaction_id: headers['X-transaction-id'])

      if result[:status] == 200
        transaction.update!(status: "SUCCESS", response_code: result[:status], payload: result[:data])
      else
        transaction.update!(status: "ERROR", response_code: result[:status], payload: result[:data])
      end

      publisher.subscribers.each do |subscriber|
        if subscriber.email_subscriber?
          Vineti::Notifications::Subscriber::EmailService.new(
            topic: publisher,
            template_data: response_body["template_data"],
            delayed_time: response_body["delayed_time"],
            metadata: response_body["metadata"],
            for_redelivery: for_redelivery
          ).send_notification_to_subscriber(subscriber)
        elsif subscriber.webhook_subscriber?
          Vineti::Notifications::Subscriber::WebhookService.new(
            topic: publisher,
            payload: response_body['payload'],
            subscriber: subscriber,
            metadata: response_body['metadata'],
            for_redelivery: for_redelivery
          ).send_notification
        end
      end
    end
  end
end
