class AddResponseToEventTransactions < ActiveRecord::Migration[5.2]
  def up
    add_column :vineti_notifications_event_transactions, :response, :jsonb, default: {}
  end

  def down
    remove_column :vineti_notifications_event_transactions, :response
  end
end
