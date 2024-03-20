module Vineti::Notifications
  class Publisher < ApplicationRecord
    self.table_name = :vineti_notifications_publishers
    has_paper_trail

    has_many :event_publishers,
             class_name: 'Vineti::Notifications::EventPublisher',
             foreign_key: 'vineti_notifications_publisher_id',
             dependent: :destroy

    has_many :publisher_subscribers,
             class_name: 'Vineti::Notifications::PublisherSubscriber',
             foreign_key: 'vineti_notifications_publishers_id',
             dependent: :destroy

    belongs_to :template,
               class_name: 'Vineti::Notifications::Template',
               foreign_key: 'vineti_notifications_template_id'

    has_many :events,
             class_name: 'Vineti::Notifications::Event',
             through: :event_publishers

    has_many :subscribers,
             class_name: 'Vineti::Notifications::Subscriber',
             through: :publisher_subscribers

    has_many :email_subscribers,
             -> { where(type: 'Vineti::Notifications::Subscriber::EmailSubscriber') },
             class_name: 'Vineti::Notifications::Subscriber',
             through: :publisher_subscribers,
             source: :subscriber

    has_many :webhook_subscribers,
             -> { where(type: 'Vineti::Notifications::Subscriber::WebhookSubscriber') },
             class_name: 'Vineti::Notifications::Subscriber',
             through: :publisher_subscribers,
             source: :subscriber

    REQUIRED_DATA_ATTRIBUTES = ['token'].freeze
    enum payload_type: { :JSON => 0, :YML => 1 }

    validates :publisher_id, presence: true, uniqueness: true
    validate :valid_publisher_data?

    def valid_publisher_data?
      REQUIRED_DATA_ATTRIBUTES.each do |attribute|
        errors.add(:data, "Missing value for data #{attribute}") if data[attribute].blank?
        existing_publisher = Publisher.find_by("data->>'#{attribute}' = ?", data[attribute])
        next unless data[attribute] && existing_publisher.present? && publisher_id != existing_publisher.publisher_id

        errors.add(attribute.to_sym, "already associated with some other publisher")
      end
    end
  end
end
