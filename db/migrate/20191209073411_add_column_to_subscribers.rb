class AddColumnToSubscribers < ActiveRecord::Migration[5.2]
  def change
    add_column :vineti_notifications_subscribers, :delayed_time, :integer
  end
end
