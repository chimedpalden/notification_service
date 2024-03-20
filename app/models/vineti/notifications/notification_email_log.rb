module Vineti::Notifications
  class NotificationEmailLog < ApplicationRecord
    belongs_to :event,
               class_name: 'Vineti::Notifications::Event',
               foreign_key: 'vineti_notifications_events_id',
               optional: true

    belongs_to :publisher,
               class_name: 'Vineti::Notifications::Publisher',
               foreign_key: 'vineti_notifications_publishers_id',
               optional: true

    belongs_to :subscriber,
               class_name: 'Vineti::Notifications::Subscriber',
               foreign_key: 'vineti_notifications_subscribers_id',
               optional: true

    belongs_to :template,
               class_name: 'Vineti::Notifications::Template',
               foreign_key: 'vineti_notifications_templates_id',
               optional: true

    has_many :email_responses,
             class_name: 'Vineti::Notifications::NotificationEmailResponse::Base',
             foreign_key: 'vineti_notifications_notification_email_logs_id'

    def self.record(event, subscriber, template, message)
      Vineti::Notifications::NotificationEmailLog.create!(
        event: event,
        subscriber: subscriber,
        template: template,
        email_message: message
      )
    end
  end
end
