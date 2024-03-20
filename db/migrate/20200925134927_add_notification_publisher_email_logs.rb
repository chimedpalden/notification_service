class AddNotificationPublisherEmailLogs < ActiveRecord::Migration[6.0]
  def change
  	add_reference :vineti_notifications_notification_email_logs, :vineti_notifications_publishers, index: { name: 'index_email_logs_on_notification_publisher_id' }
  end
end
