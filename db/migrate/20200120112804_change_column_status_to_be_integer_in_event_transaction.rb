class ChangeColumnStatusToBeIntegerInEventTransaction < ActiveRecord::Migration[5.2]
  def change
    remove_column :vineti_notifications_event_transactions, :status, enum_name: :transaction_status, null: true, default: nil
    change_table :vineti_notifications_event_transactions do |t|
      t.integer :status, default: 0
    end
    drop_enum :transaction_status
  end
end
