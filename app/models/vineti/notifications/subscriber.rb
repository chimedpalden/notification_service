module Vineti::Notifications
  class Subscriber < ApplicationRecord
    # NOTE:
    # this file/class will not be reloaded in development due to
    # explicit require in initializers/activemq

    self.table_name = :vineti_notifications_subscribers

    has_paper_trail

    has_many :event_subscribers,
             class_name: 'Vineti::Notifications::EventSubscriber',
             foreign_key: 'vineti_notifications_subscribers_id',
             dependent: :destroy

    belongs_to :template,
               class_name: 'Vineti::Notifications::Template',
               foreign_key: 'vineti_notifications_templates_id',
               optional: true

    has_many :events,
             class_name: 'Vineti::Notifications::Event',
             through: :event_subscribers

    has_many :publisher_subscribers,
             class_name: 'Vineti::Notifications::PublisherSubscriber',
             foreign_key: 'vineti_notifications_subscribers_id',
             dependent: :destroy

    has_many :publishers,
             class_name: 'Vineti::Notifications::Publisher',
             through: :publisher_subscribers

    has_many :event_transactions,
             class_name: 'Vineti::Notifications::EventTransaction',
             foreign_key: 'vineti_notifications_subscribers_id',
             dependent: :destroy

    validates :subscriber_id, presence: true, uniqueness: true
    validates :delayed_time, :numericality => { :only_integer => true }, allow_nil: true

    def self.internal_api_subscriber_id(event_name)
      "internal-subscriber-#{event_name}"
    end

    def email_subscriber?
      type == "Vineti::Notifications::Subscriber::EmailSubscriber"
    end

    def webhook_subscriber?
      type == "Vineti::Notifications::Subscriber::WebhookSubscriber"
    end

    def internal_api_subscriber?
      type == "Vineti::Notifications::Subscriber::InternalApiSubscriber"
    end
  end
end
