class CreateVinetiNotificationsNotificationEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :vineti_notifications_notification_events do |t|
      t.string :name
      t.timestamps
    end
  end
end
