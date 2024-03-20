class CreateVinetiNotificationsNotificationEmailLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :vineti_notifications_notification_email_logs do |t|
      t.json :email_message
      t.references :vineti_notifications_notification_events, index: { name: 'index_email_logs_on_notification_event_id' }
      t.references :vineti_notifications_email_subscribers, index: { name: 'index_email_logs_on_email_subscriber_id' }
      t.references :vineti_notifications_email_templates, index: { name: 'index_email_logs_on_email_template_id' }
      t.timestamps
    end
  end
end
