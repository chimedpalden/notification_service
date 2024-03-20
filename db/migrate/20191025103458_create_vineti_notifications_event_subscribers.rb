class CreateVinetiNotificationsEventSubscribers < ActiveRecord::Migration[5.2]
  def change
    create_table :vineti_notifications_event_subscribers do |t|
      t.references :vineti_notifications_events, foreign_key: true, index: { name: 'index_event_subscribers_on_events_id' }
      t.references :vineti_notifications_subscribers, foreign_key: true, index: { name: 'index_event_susbcribers_on_subscribers_id' }
      t.timestamps
    end
  end
end
