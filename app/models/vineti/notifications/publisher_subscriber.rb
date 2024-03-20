module Vineti::Notifications
  class PublisherSubscriber < ApplicationRecord
    # NOTE:
    # this file/class will not be reloaded in development due to
    # explicit require in initializers/activemq

    belongs_to :publisher,
               class_name: 'Vineti::Notifications::Publisher',
               foreign_key: 'vineti_notifications_publishers_id'

    belongs_to :subscriber,
               class_name: 'Vineti::Notifications::Subscriber',
               foreign_key: 'vineti_notifications_subscribers_id'

    validates :publisher, :subscriber, presence: true
    validates :publisher, uniqueness: { scope: :subscriber }
  end
end
