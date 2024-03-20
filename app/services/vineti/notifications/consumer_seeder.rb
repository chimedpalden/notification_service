# frozen_string_literal: true

module Vineti::Notifications
  class ConsumerSeeder
    def self.run
      # Subscribe to drop and response queue for error and success status of webhook notifications
      # Subscribe to vineti_event queue for System Event
      # Subscribe to the changes in subscriptions (create new subscribers/delete susbcribers)
      Vineti::Notifications::SubscriptionManager.seed_default_subscribers

      # create subscriptions for Webhook and Email channel
      Vineti::Notifications::SubscriptionManager.seed_custom_subscribers
    end
  end
end
