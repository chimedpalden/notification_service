class ChangeColumnsInTemplates < ActiveRecord::Migration[5.2]
  def up
    remove_column :vineti_notifications_templates, :subject
    remove_column :vineti_notifications_templates, :text_body
    remove_column :vineti_notifications_templates, :html_body

    add_column :vineti_notifications_templates, :data, :json
  end
end
