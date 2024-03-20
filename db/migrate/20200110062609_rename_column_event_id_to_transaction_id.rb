class RenameColumnEventIdToTransactionId < ActiveRecord::Migration[5.2]
  def change
    rename_column :vineti_notifications_event_transactions, :event_id, :transaction_id
  end
end
