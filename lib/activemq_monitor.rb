module ActivemqMonitor; end

EventServiceClient::AmqConnectionPoolMonitor.class_eval do
  # we're overriding the event-service-client methods
  def seed_custom_subs
    Vineti::Notifications::SubscriptionManager.seed_custom_subscribers
  end

  def db_clients
    Vineti::Notifications::EventSubscriber.all.includes(:event, :subscriber).map do |event_subscriber|
      "#{event_subscriber.event_name}/#{event_subscriber.subscriber_id}"
    end
  end

  def sync_client_pool(client_pool_ids)
    Vineti::Notifications::EventSubscriber.all.includes(:event, :subscriber).each do |event_subscriber|
      client_id = "#{event_subscriber.event_name}/#{event_subscriber.subscriber_id}"
      if client_pool_ids.exclude? client_id
        Vineti::Notifications::SubscriptionManager.create_event_subscriber(event_subscriber.event_name, event_subscriber.subscriber_id)
      end
    end
  end
end
