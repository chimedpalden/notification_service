module Vineti::Notifications
  class EventTransaction < ApplicationRecord
    has_paper_trail

    belongs_to :subscriber,
               class_name: 'Vineti::Notifications::Subscriber',
               foreign_key: 'vineti_notifications_subscribers_id',
               optional: true

    belongs_to :publisher,
               class_name: 'Vineti::Notifications::Publisher',
               foreign_key: 'vineti_notifications_publishers_id',
               optional: true

    belongs_to :event,
               class_name: 'Vineti::Notifications::Event',
               foreign_key: 'vineti_notifications_events_id',
               optional: true

    has_many :child_transactions,
             :class_name => "Vineti::Notifications::EventTransaction",
             :foreign_key => "parent_transaction_id"

    belongs_to :parent_transaction,
               :class_name => "Vineti::Notifications::EventTransaction",
               :foreign_key => "parent_transaction_id", optional: true

    validates :transaction_id, presence: true, uniqueness: true

    scope :failed_publish_events, ->(retry_count) { where(status: 'ERROR', parent_transaction_id: nil).where("retries_count < ?", retry_count).order(id: :asc) }
  end
end
