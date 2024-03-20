module Vineti::Notifications
  class SubscriptionManager
    attr_accessor :subscriber, :event

    def initialize(subscriber, event = nil)
      @subscriber = subscriber
      @event = event
    end

    def self.create_for(subscriber_id)
      subscriber = Vineti::Notifications::Subscriber.find_by(subscriber_id: subscriber_id)
      if subscriber.present?
        new(subscriber).create_subscriptions
      else
        STDOUT.puts "No subscriber found with id: #{subscriber_id}"
      end
    end

    def self.create_event_subscriber(event_name, subscriber_id)
      event_subscriber = Vineti::Notifications::EventSubscriber.find do |event_sub|
        event_name == event_sub.event_name && subscriber_id == event_sub.subscriber_id
      end

      if event_subscriber.present?
        new(event_subscriber.subscriber, event_subscriber.event).create_event_subscriptions
      else
        STDOUT.puts "No event_subscriber found with event_name: #{event_name} and subscriber_id #{subscriber_id}"
      end
    end

    def self.seed_custom_subscribers
      Vineti::Notifications::EmailSubscription.create_active_subscriptions
      Vineti::Notifications::WebhookSubscription.create_active_subscriptions
      Vineti::Notifications::InternalApiSubscription.create_active_subscriptions
    end

    def self.seed_default_subscribers
      ::EventServiceClient::Configuration.seed
    end

    def create_subscriptions
      if subscriber&.email_subscriber?
        Vineti::Notifications::EmailSubscription.create_subscription_for(subscriber)
      elsif subscriber&.webhook_subscriber?
        Vineti::Notifications::WebhookSubscription.create_subscription_for(subscriber)
      elsif subscriber&.internal_api_subscriber?
        Vineti::Notifications::InternalApiSubscription.create_subscription_for(subscriber)
      else
        STDOUT.puts "Not an email/webhook subscriber."
      end
    end

    def create_event_subscriptions
      if subscriber&.email_subscriber?
        Vineti::Notifications::EmailSubscription.create_event_subscriber(event, subscriber)
      elsif subscriber&.webhook_subscriber?
        Vineti::Notifications::WebhookSubscription.create_event_subscriber(event, subscriber)
      elsif subscriber&.internal_api_subscriber?
        Vineti::Notifications::InternalApiSubscription.create_event_subscriber(event, subscriber)
      else
        STDOUT.puts "Not an email/webhook subscriber."
      end
    end
  end
end
