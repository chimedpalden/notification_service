module Vineti::Notifications::DefaultConsumers
  class TopicSubscription
    def self.process(payload)
      response = payload.body
      Rails.logger.info("Creating subscriber client #{response['event_name']}/#{response['subscriber_id']}")
      Vineti::Notifications::SubscriptionManager.create_for(response['subscriber_id'])
    end
  end
end
