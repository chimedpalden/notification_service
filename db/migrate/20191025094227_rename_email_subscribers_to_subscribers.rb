class RenameEmailSubscribersToSubscribers < ActiveRecord::Migration[5.2]
  def up
    rename_table :vineti_notifications_email_subscribers, :vineti_notifications_subscribers
  end
end
