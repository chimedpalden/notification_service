# frozen_string_literal: true

require 'stomp'

module Vineti::Notifications
  class WebhookSubscription
    # NOTE:
    # this file/class will not be reloaded in development due to
    # explicit require in initializers/activemq

    attr_reader :host, :port, :ssl, :login, :password

    def self.create_active_subscriptions
      Vineti::Notifications::Subscriber::WebhookSubscriber.all.each do |subscriber|
        create_subscription_for(subscriber)
      end
    end

    def self.create_subscription_for(subscriber)
      subscriber.events.each do |event|
        create_event_subscriber(event, subscriber)
      end
    end

    def self.create_event_subscriber(event, subscriber)
      ::EventServiceClient::Subscribe.to_virtual_topic(event.name, subscriber.subscriber_id) do |res|
        process_message(res, event, subscriber)
      end
    end

    def self.process_message(res, event, subscriber)
      STDOUT.puts("======================Got Response from AMQ #{res}================")
      response_body = res.body
      response = Vineti::Notifications::Subscriber::WebhookService.new(
        topic: event,
        payload: response_body['payload'],
        subscriber: subscriber,
        metadata: response_body['metadata'],
        parent_transaction_id: response_body["parent_transaction_id"],
        for_redelivery: res.headers["redelivered"] == "true"
      ).send_notification
      return unless response.class == Vineti::Notifications::Subscriber::WebhookErrorResponse

      raise response.message.to_s
    end
  end
end
