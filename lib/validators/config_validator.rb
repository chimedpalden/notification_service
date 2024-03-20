# frozen_string_literal: true

module Validators
  class ConfigValidator
    def call
      validate_template_config
      validate_subscriber_config
    end

    private

    def validate_template_config
      yml_data = YAML.safe_load(File.read("#{Config::Bundle.bundle_path}/fixtures/notifications/email_templates.yml"))
      yml_data['templates'].each do |template_details|
        template_details['template_id'] = SecureRandom.hex(4)
        template = Vineti::Notifications::Template.new(template_details)
        next if template.valid?

        raise StandardError, template.errors.full_messages.join(', ')
      end
    end

    # rubocop:disable Lint/NonLocalExitFromIterator
    def validate_subscriber_config
      yml_data = YAML.safe_load(File.read("#{Config::Bundle.bundle_path}/fixtures/notifications/notification_event_config.yml"))
      yml_data['events'].each do |config|
        raise StandardError, "Missing event name" unless config['event_name']
        raise StandardError, "Missing template id for event #{config['event_name']}" unless config['email_template_id']

        config['email_subscribers'].each do |subscriber_group|
          raise StandardError, "Missing template id for event #{config['event_name']}" unless subscriber_group['template']

          attributes = subscriber_group.merge(
            'vineti_notifications_templates_id' => 1,
            'subscriber_id' => SecureRandom.hex(4)
          )
          subscriber = "Vineti::Notifications::Subscriber::#{subscriber_group['type'].titleize}Subscriber"
                       .constantize.new(attributes.except('type', 'template'))
          return if subscriber.valid?

          raise StandardError, subscriber.errors.full_messages.join(', ')
        end
      end
    end
    # rubocop:enable Lint/NonLocalExitFromIterator
  end
end
