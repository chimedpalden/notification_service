class RemoveColumnsFromSubscribers < ActiveRecord::Migration[5.2]
  def up
    remove_column :vineti_notifications_subscribers, :from_address
    remove_column :vineti_notifications_subscribers, :to_addresses
    remove_column :vineti_notifications_subscribers, :cc_addresses
    remove_column :vineti_notifications_subscribers, :bcc_addresses
    remove_column :vineti_notifications_subscribers, :vineti_notifications_notification_events_id

    add_column :vineti_notifications_subscribers, :data, :json
    add_column :vineti_notifications_subscribers, :type, :string
    add_column :vineti_notifications_subscribers, :active, :boolean, default: true

    rename_column :vineti_notifications_subscribers,
                  :vineti_notifications_email_templates_id,
                  :vineti_notifications_templates_id
  end
end
