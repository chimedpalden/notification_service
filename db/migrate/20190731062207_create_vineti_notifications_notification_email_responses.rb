class CreateVinetiNotificationsNotificationEmailResponses < ActiveRecord::Migration[5.2]
  def change
    create_table :vineti_notifications_notification_email_responses do |t|
      t.string :type
      t.json :response
      t.references :vineti_notifications_notification_email_logs, index: { name: 'index_email_responses_on_email_logs_id' }
      t.timestamps
    end
  end
end
