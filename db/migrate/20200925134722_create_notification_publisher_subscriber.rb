class CreateNotificationPublisherSubscriber < ActiveRecord::Migration[6.0]
  def change
    create_table :vineti_notifications_publisher_subscribers do |t|
      t.references :vineti_notifications_publishers, foreign_key: true, index: { name: 'index_publisher_subscribers_on_publishers_id' }
      t.references :vineti_notifications_subscribers, foreign_key: true, index: { name: 'index_publisher_subscribers_on_subscribers_id' }
      t.timestamps
    end
  end
end
