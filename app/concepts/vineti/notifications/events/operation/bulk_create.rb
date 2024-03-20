module Vineti::Notifications
  class Events::Operation::BulkCreate
    extend Vineti::Notifications::PubSubUpsertHelper

    VALID_TEMPLATE_KEYS = %w[event_name subscribers publishers].freeze
    VALID_SUBSCRIBER_KEYS = %w[subscriber_id delayed_time template type active data].freeze
    VALID_PUBLISHER_KEYS = %w[publisher_id template payload_type active data subscribers].freeze

    def self.call(events:)
      if valid_params?(events)
        begin
          events = render_config(events)
          upsert_events(events)
          { status: 201 }
        rescue Exception => e
          { errors: [{ message: e.message }], status: 422 }
        end
      else
        { errors: [{ message: 'content is invalid' }], status: 422 }
      end
    end

    private_class_method def self.valid_params?(event_configs)
      event_configs.is_a?(Array) && event_configs.all? do |config|
        valid_keys = config&.keys&.all? { |key| VALID_TEMPLATE_KEYS.include? key }
        valid_event_subscribers = config['subscribers']&.all? do |subscriber|
          subscriber&.keys&.all? { |key| VALID_SUBSCRIBER_KEYS.include? key }
        end

        valid_publishers = config['publishers']&.all? do |publisher|
          publisher&.keys&.all? { |key| VALID_PUBLISHER_KEYS.include? key }
        end

        valid_publisher_subscribers = true
        config['publishers']&.each do |publisher|
          next unless publisher['subscribers']

          valid_publisher_subscribers = publisher['subscribers']&.all? do |subscriber|
            subscriber&.keys&.all? { |key| VALID_SUBSCRIBER_KEYS.include? key }
          end
          break unless valid_publisher_subscribers
        end
        valid_event_subscribers = true if config['subscribers'].blank?
        ## publishers are optional for any event, there are events that come directly from pattern
        ## publishers are defined only for inbound events from external systems as of now
        valid_publishers = true if config['publishers'].blank?
        valid_keys && valid_event_subscribers && valid_publishers && valid_publisher_subscribers
      end
    end

    private_class_method def self.upsert_events(event_configs)
      event_configs.each do |config|
        event = Vineti::Notifications::Event.find_or_create_by!(name: config['event_name'])
        if config['subscribers'].present?
          upsert_subscribers(
            subscribers: config['subscribers'],
            topic: event
          )
        end

        upsert_publishers(publishers: config['publishers'], event: event) if config['publishers'].present?
      end
    end

    private_class_method def self.render_config(event_configs)
      config_data = event_configs.to_json
      rendered_content = Vineti::Templates::Render.call(config_data)
      JSON.parse(rendered_content)
    end
  end
end
