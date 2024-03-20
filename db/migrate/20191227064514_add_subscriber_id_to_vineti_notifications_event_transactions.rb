class AddSubscriberIdToVinetiNotificationsEventTransactions < ActiveRecord::Migration[5.2]
  def change
    add_reference :vineti_notifications_event_transactions,
                  :vineti_notifications_subscribers,
                  foreign_key: true,
                  index: { name: 'index_event_transactions_on_subscribers_id' }
  end
end
