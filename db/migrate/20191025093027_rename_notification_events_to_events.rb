class RenameNotificationEventsToEvents < ActiveRecord::Migration[5.2]
  def up
    rename_table :vineti_notifications_notification_events, :vineti_notifications_events
  end

  def down
    rename_table :vineti_notifications_events, :vineti_notifications_notification_events
  end
end
