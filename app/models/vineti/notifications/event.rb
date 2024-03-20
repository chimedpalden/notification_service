module Vineti::Notifications
  class Event < ApplicationRecord
    # NOTE:
    # this file/class will not be reloaded in development due to
    # explicit require in initializers/activemq

    has_paper_trail
    has_many :event_subscribers,
             class_name: 'Vineti::Notifications::EventSubscriber',
             foreign_key: 'vineti_notifications_events_id',
             dependent: :destroy

    has_many :subscribers,
             class_name: 'Vineti::Notifications::Subscriber',
             through: :event_subscribers

    has_many :email_subscribers,
             -> { where(type: 'Vineti::Notifications::Subscriber::EmailSubscriber') },
             class_name: 'Vineti::Notifications::Subscriber',
             through: :event_subscribers,
             source: :subscriber

    has_many :webhook_subscribers,
             -> { where(type: 'Vineti::Notifications::Subscriber::WebhookSubscriber') },
             class_name: 'Vineti::Notifications::Subscriber',
             through: :event_subscribers,
             source: :subscriber

    has_many :internal_api_subscribers,
             -> { where(type: 'Vineti::Notifications::Subscriber::InternalApiSubscriber') },
             class_name: 'Vineti::Notifications::Subscriber',
             through: :event_subscribers,
             source: :subscriber

    has_many :event_publishers,
             class_name: 'Vineti::Notifications::EventPublisher',
             foreign_key: 'vineti_notifications_event_id',
             dependent: :destroy

    has_many :publishers,
             class_name: 'Vineti::Notifications::Publisher',
             through: :event_publishers

    validates :name, presence: true, uniqueness: true

    after_update :delete_activemq_subscriptions, :create_new_amq_subscriptions, if: :name_previously_changed?

    def delete_activemq_subscriptions
      old_event_name = previous_changes['name'][0]
      subscriber_ids = subscribers.pluck(:subscriber_id)
      subscriber_ids.each do |subscriber_id|
        event_data = {
          event_name: old_event_name,
          subscriber_id: subscriber_id
        }
        ::EventServiceClient::Publish.to_topic('topic_unsubscription', event_data)
      end
    end

    def create_new_amq_subscriptions
      subscriber_ids = subscribers.pluck(:subscriber_id)
      subscriber_ids.each do |subscriber_id|
        event_data = {
          event_name: name,
          subscriber_id: subscriber_id
        }
        ::EventServiceClient::Publish.to_topic('topic_subscription', event_data)
      end
    end
  end
end
