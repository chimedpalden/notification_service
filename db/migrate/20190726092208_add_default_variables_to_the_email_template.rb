class AddDefaultVariablesToTheEmailTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :vineti_notifications_email_templates, :default_variables, :json
  end
end
