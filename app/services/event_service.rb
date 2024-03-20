class EventService
  attr_reader :event,
              :template_data,
              :payload,
              :delayed_time,
              :event_name,
              :metadata

  def initialize(params)
    @event_name = params[:event_name] || params.dig(:payload, :events).first[:event_name]
    @template_data = params[:template_data]
    @payload = params[:payload]
    @delayed_time = params[:delayed_time].nil? ? nil : Integer(params[:delayed_time])
    @metadata = params[:metadata]
    @enable_virtual_topic = EventServiceClient::Config.instance.feature('enable_virtual_topics')
  end

  def self.build(params)
    params[:payload][:events].map { |data| new(data.merge(params)) }
  end

  def notify_subscribers
    fetch_event_from_db

    event_data = {
      payload: payload,
      template_data: template_data,
      delayed_time: delayed_time,
      metadata: metadata,
    }

    # TODO: vineti_notification: rename method params
    # first parameter here is data that we need to publish to the ActiveMQ topic
    # Second parameter is boolean whether we want to send it to virtual topic. Default is false.
    type = @enable_virtual_topic ? 'virtual_topic' : 'topic'
    Vineti::Notifications::Publish.to_event(event.name, type, event_data)
  end

  def self.republish_failed_events
    Vineti::Notifications::Events::Operation::PublishRetry.call
  end

  private

  def fetch_event_from_db
    @event = Vineti::Notifications::Event.find_or_create_by(name: event_name)
  end
end
