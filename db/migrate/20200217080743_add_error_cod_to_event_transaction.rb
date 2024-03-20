class AddErrorCodToEventTransaction < ActiveRecord::Migration[5.2]
  def up
    add_column :vineti_notifications_event_transactions, :response_code, :string
  end

  def down
    remove_column :vineti_notifications_event_transactions, :response_code
  end
end
