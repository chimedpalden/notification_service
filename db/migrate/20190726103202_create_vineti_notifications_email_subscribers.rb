class CreateVinetiNotificationsEmailSubscribers < ActiveRecord::Migration[5.2]
  def change
    create_table :vineti_notifications_email_subscribers do |t|
      t.references :vineti_notifications_notification_events, index: { name: 'index_email_subscribers_on_notification_events_id' }
      t.references :vineti_notifications_email_templates, index: { name: 'index_email_subscribers_on_email_templates_id' }
      t.string :subscriber_id
      t.string :from_address
      t.json :to_addresses
      t.json :cc_addresses
      t.json :bcc_addresses
      t.timestamps
    end
  end
end
