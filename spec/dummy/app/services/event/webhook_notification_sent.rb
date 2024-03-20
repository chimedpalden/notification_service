class Event::WebhookNotificationSent
  def self.record(details, event_transaction_id)
    # No operation
    # TODO: vineti_notifications: remove this class after we seperate out notification as service
    true
  end
end
