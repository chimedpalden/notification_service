module Vineti::Notifications
  class EventSubscriber < ApplicationRecord
    # NOTE:
    # this file/class will not be reloaded in development due to
    # explicit require in initializers/activemq

    belongs_to :event,
               class_name: 'Vineti::Notifications::Event',
               foreign_key: 'vineti_notifications_events_id'

    belongs_to :subscriber,
               class_name: 'Vineti::Notifications::Subscriber',
               foreign_key: 'vineti_notifications_subscribers_id'

    delegate :subscriber_id, to: :subscriber
    delegate :name, to: :event, prefix: true

    validates :event, :subscriber, presence: true
    validates :event, uniqueness: { scope: :subscriber }

    after_commit :amq_seed, on: [:create]

    private

    def amq_seed
      event_data = {
        event_name: event_name,
        subscriber_id: subscriber_id
      }
      ::EventServiceClient::Publish.to_topic('topic_subscription', event_data)
    end
  end
end
