class AddNotificationsEventIdToEventTransactions < ActiveRecord::Migration[6.0]
  def change
    add_reference :vineti_notifications_event_transactions,
                  :vineti_notifications_events,
                  foreign_key: true,
                  index: { name: 'index_event_transactions_on_events_id' }
  end
end
