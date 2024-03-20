class CreatePublisherTables < ActiveRecord::Migration[5.2]
  def change
    create_table :vineti_notifications_publishers do |t|
      t.string :publisher_id
      t.references :vineti_notifications_template, index: { name: "index_vineti_notifications_publishers_on_template" }
      t.integer :payload_type, default: 0
      t.boolean :active, default: false
      t.jsonb :data, default: {}
      t.timestamps
    end

    create_table :vineti_notifications_event_publishers do |t|
      t.references :vineti_notifications_publisher, index: { name: "index_vineti_notifications_event_publishers_on_publisher" }
      t.references :vineti_notifications_event, index: { name: "index_vineti_notifications_event_publishers_on_event" }
      t.timestamps
    end
  end
end
