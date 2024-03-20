class ChangeColumnNamesInNotificationLogs < ActiveRecord::Migration[5.2]
  def up
    rename_column :vineti_notifications_notification_email_logs,
                  :vineti_notifications_notification_events_id,
                  :vineti_notifications_events_id

    rename_column :vineti_notifications_notification_email_logs,
                  :vineti_notifications_email_subscribers_id,
                  :vineti_notifications_subscribers_id

    rename_column :vineti_notifications_notification_email_logs,
                  :vineti_notifications_email_templates_id,
                  :vineti_notifications_templates_id
  end
end
