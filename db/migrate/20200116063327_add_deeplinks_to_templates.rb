class AddDeeplinksToTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :vineti_notifications_templates, :deeplinks, :json
  end
end
