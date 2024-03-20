class RenameNameToTemplateIdInTemplateTable < ActiveRecord::Migration[5.2]
  def change
    rename_column :vineti_notifications_email_templates, :name, :template_id
  end
end
