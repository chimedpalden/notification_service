class RenameEmailTemplatesToTemplates < ActiveRecord::Migration[5.2]
  def up
    rename_table :vineti_notifications_email_templates, :vineti_notifications_templates
  end
end
