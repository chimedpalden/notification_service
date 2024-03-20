class AddColumnToEventTransaction < ActiveRecord::Migration[5.2]
  def change
    add_column :vineti_notifications_event_transactions, :retries_count, :integer, default: 0
  end
end
