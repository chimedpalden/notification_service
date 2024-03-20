# This file needs some major refactoring and testing.
# So much could wrong here and it's an *essential* part of our build pipeline.
module Fixtures
  class NotificationConfigFixture
    include Vineti::Notifications::PubSubUpsertHelper

    def call
      seed_email_templates
      seed_notification_config
    end

    def fixture_file(filename)
      # NOOOO: Config::Bundle is a part of vineti-platform and
      # creates a coupling between notifications and platform.
      path = "#{Config::Bundle.bundle_path}/fixtures/#{filename}"
      File.read(path) if File.exist?(path)
    end

    def get_yml_data(filename, key)
      file = fixture_file(filename)
      return nil if file.nil?

      yml_data = YAML.safe_load(file)
      yml_data&.fetch(key, nil)
    end

    def seed_email_templates(templates_data = nil)
      templates_data ||= get_yml_data('notifications/email_templates.yml', 'templates')

      return if templates_data.blank?

      valid = ::Vineti::Notifications::Templates::Operation::BulkCreate.valid_params?(templates_data)
      raise "Invalid template configuration" unless valid

      template_name = nil
      templates_data.each do |template_details|
        template_name = template_details['template_id']
        template = Vineti::Notifications::Template.find_by(template_id: template_details['template_id'])
        if template.present?
          template.update!(template_details.except('template_id'))
          Rails.logger.info "Updated email template with name #{template_details['template_id']}"
          next
        end
        template = Vineti::Notifications::Template.create!(template_details)
        Rails.logger.info "Created an email template with name #{template.template_id} and email_body #{template_details}..."
      end

      templates_data
    rescue StandardError => e
      Rails.logger.fatal "Got error #{e.message} while creating/updating an template with name #{template_name}!!!"
      raise e
    end

    # rubocop:disable Style/Next
    def seed_notification_config(events_data = nil)
      events_data ||= get_yml_data('notifications/notification_event_config.yml', 'events')

      return if events_data.blank?

      event_name = nil
      events_data.each do |config|
        event_name = config['event_name']
        event = Vineti::Notifications::Event.find_or_create_by!(name: event_name)

        upsert_subscribers(
          subscribers: config['subscribers'],
          topic: event
        )
        if config['publishers'].present?
          upsert_publishers(
            publishers: config['publishers'],
            event: event
          )
        end
      end

      events_data
    rescue StandardError => e
      Rails.logger.fatal "Got error #{e.message} while creating/updating event '#{event_name}'!!!"
      raise e
    end
    # rubocop:enable Style/Next
  end
end
