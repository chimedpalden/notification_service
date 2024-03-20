class CreateVinetiNotificationsEmailTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :vineti_notifications_email_templates do |t|
      t.string :name
      t.string :subject
      t.string :text_body
      t.string :html_body

      t.timestamps
    end
  end
end
