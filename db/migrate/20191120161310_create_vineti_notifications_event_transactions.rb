class CreateVinetiNotificationsEventTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :vineti_notifications_event_transactions do |t|
      t.string :event_id
      t.boolean :status_success, default: false
      t.jsonb :payload, default: {}
      t.timestamps
    end
  end
end
