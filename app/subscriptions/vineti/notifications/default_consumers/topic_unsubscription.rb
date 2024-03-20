module Vineti::Notifications::DefaultConsumers
  class TopicUnsubscription
    def self.process(payload)
      response = payload.body
      Rails.logger.info("====== Deleting subscription with subscriber_id : #{response['subscriber_id']}; for event #{response['event_name']}")
      ::EventServiceClient::Manage.delete_subscriber(response['event_name'], response['subscriber_id'])
    end
  end
end
