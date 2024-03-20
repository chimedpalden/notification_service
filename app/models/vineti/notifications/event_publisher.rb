module Vineti::Notifications
  class EventPublisher < ApplicationRecord
    belongs_to :event,
               class_name: 'Vineti::Notifications::Event',
               foreign_key: 'vineti_notifications_event_id'

    belongs_to :publisher,
               class_name: 'Vineti::Notifications::Publisher',
               foreign_key: 'vineti_notifications_publisher_id'

    validates :event, :publisher, presence: true
    validates :event, uniqueness: { scope: :publisher }
  end
end
