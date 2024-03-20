class AddParentTransactionInEventTransaction < ActiveRecord::Migration[5.2]
  def change
    add_column :vineti_notifications_event_transactions, :parent_transaction_id, :integer
    add_index :vineti_notifications_event_transactions, :transaction_id
  end
end
