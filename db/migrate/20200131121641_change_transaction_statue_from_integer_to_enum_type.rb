class ChangeTransactionStatueFromIntegerToEnumType < ActiveRecord::Migration[5.2]
  def change
    create_enum :transaction_status, %w(
      CREATED
      WSO_SUCCESS
      WSO_ERROR
      SUCCESS
      ERROR
    )
    remove_column :vineti_notifications_event_transactions, :status, :integer, default: 0

    change_table :vineti_notifications_event_transactions do |t|
      t.enum :status, enum_name: :transaction_status, null: true, default: nil
    end
  end
end
