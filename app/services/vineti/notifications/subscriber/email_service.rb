# frozen_string_literal: true

module Vineti::Notifications
  class Subscriber::EmailService
    include ActiveModel::Validations
    include Vineti::Notifications::ServiceHelper

    attr_accessor :client,
                  :data,
                  :delayed_time,
                  :destination,
                  :error,
                  :topic, # event or publisher
                  :template_render,
                  :source,
                  :subscriber,
                  :template_data,
                  :template,
                  :metadata,
                  :parent_transaction_id,
                  :retry_transaction_id,
                  :for_redelivery

    validate :template_variables

    def initialize(topic:, template_data:, metadata: {}, parent_transaction_id: nil, delayed_time: nil, retry_transaction_id: nil, for_redelivery: false)
      @client = ::Ses.new
      @template_render = Vineti::Templates::Render
      @template_data = get_template_data(template_data)
      @topic = topic
      @delayed_time = Integer(delayed_time) if delayed_time.present?
      @metadata = (metadata || {}).try(:with_indifferent_access)
      @parent_transaction_id = parent_transaction_id
      @retry_transaction_id = retry_transaction_id
      @for_redelivery = for_redelivery
    end

    def send_notification
      topic.email_subscribers.map { |email_subscriber| send_notification_to_subscriber(email_subscriber) }
    end

    def send_notification_to_subscriber(subscriber)
      @subscriber = subscriber.reload
      @transaction = for_redelivery ? get_transaction_and_update_redelivery_count(template_data) : get_retry_transaction(template_data)
      @delayed_time = @delayed_time&.to_i || @subscriber&.delayed_time&.to_i
      fetch_data_from_group
      replace_step_link_in_template if procedure_data_available?
      generate_body(@template)
      create_email_notification_event
      msg_obj = Struct.new(:text, :subject).new(@data[:body], @data[:subject])
      @resp = create_email

      unless delay_email_job?
        log_mail_response(@data)
        @transaction.update!(status: "SUCCESS")
      end
      Vineti::Notifications::Subscriber::EmailResponse.new(@resp, msg_obj)
    rescue StandardError => e
      Rails.logger.error("Error: #{e} \n\tat #{e.backtrace.join("\n\tat ")}")
      log_mail_response(@data, e)
      @transaction.update!(status: "ERROR") if @transaction.present?
      Vineti::Notifications::Subscriber::EmailErrorResponse.new(e)
    end

    private

    # Ideally `template_data` is always a hash but if it isn't `with_indifferent_access` will throw an error.
    def get_template_data(template_data)
      template_data.is_a?(Hash) ? template_data.with_indifferent_access : {}
    end

    def procedure_data_available?
      template_data.dig('meta', 'procedure') && template_data.dig('meta', 'procedure_step')
    end

    def replace_step_link_in_template
      procedure_id = template_data.dig('meta', 'procedure', 'data', 'id')
      return unless @template.deeplinks && procedure_id

      step_name_keys = @template.deeplinks.keys.select { |k| k.match(/^deep_link_for_step/) }
      step_name_keys.each do |step_name_key|
        step_name = current_step?(step_name_key) ? current_step_name : @template.deeplinks[step_name_key]
        deeplink_service = DeeplinkService.new(procedure_id, step_name)
        template_data.merge!("#{step_name_key}": deeplink_service.get_deeplink)
      end
    end

    def current_step?(step_name_key)
      template.deeplinks[step_name_key] == "current"
    end

    def current_step_name
      template_data.dig('meta', 'procedure_step', 'data', 'attributes', 'name')
    end

    def create_email_notification_event
      keys = %i[treatment_id procedure_name step_name]
      return unless keys.all? { |k| metadata.key? k }

      event_details = metadata.slice(*keys).merge(
        from_address: source,
        to_addresses: destination[:to_addresses],
        cc_addresses: destination[:cc_addresses],
        event_transaction_id: @transaction.id,
        template_name: template.template_id,
        subscriber_id: subscriber.id
      )

      ::Event::EmailNotificationSent.record(event_details: event_details)
    end

    def fetch_data_from_group
      @template = @subscriber.template
      @source = @subscriber.data['from_address']
      email_addresses = Vineti::Notifications::UserRoleProcessor.fetch_users_from_role(@subscriber.data)

      @destination = {
        to_addresses: email_addresses['to_addresses'],
        cc_addresses: email_addresses['cc_addresses'],
        bcc_addresses: email_addresses['bcc_addresses'],
      }
    end

    def generate_body(template)
      @data = {
        subject: {
          data: render_template(template, 'subject'),
        },
        body: {
          text: {
            data: render_template(template, 'text_body'),
          },
          html: {
            data: render_template(template, 'html_body'),
          },
        },
      }
    end

    def render_template(template, key)
      default_variables = template.default_variables || {}
      replacement = default_variables.merge(template_data)
      template_render.factory(template.data[key]).call!(replacement)
    end

    def log_mail_response(mail_body, error = nil)
      log = create_log_if_not_present

      if @resp&.successful?
        response = { message_id: @resp.message_id, mail_body: mail_body }
        Vineti::Notifications::NotificationEmailResponse::SuccessResponse.record(response, log)
      else
        response = { error: error&.message, backtrace: error&.backtrace, mail_body: mail_body }
        Vineti::Notifications::NotificationEmailResponse::ErrorResponse.record(response, log)
        Airbrake.notify(error, user: source, created_at: Time.now.utc, transaction_id: @transaction&.transaction_id) if defined?(Airbrake)
      end
    end

    def topic_type
      event? ? 'event' : 'publisher'
    end

    def create_log_if_not_present
      return unless event? || publisher?

      Vineti::Notifications::NotificationEmailLog.create!(email_log_attributes)
    end

    def email_log_attributes
      mail_options = {
        source: source,
        destination: destination,
        topic_type: topic_type,
        topic: topic.try(:name) || topic.try(:publisher_id),
      }

      log_attributes = {
        template: template,
        subscriber: subscriber,
        email_message: mail_options
      }

      if event?
        log_attributes.merge!(event: topic)
      elsif publisher?
        log_attributes.merge!(publisher: topic)
      end
    end

    def template_variables
      return errors.add(:template_data, 'should be of type hash') unless template_data.is_a?(Hash)

      errors.add(:template_data, 'missing JSONAPI key "meta"') unless template_data.key?('meta')
      errors.add(:template_data, 'missing JSONAPI key "data"') unless template_data.key?('data')
    end

    def create_email
      return delayed_email_job if delay_email_job?

      # WHY: We need to create a task to investigate with product team
      # why we need to send emails immediately.
      immediate_email!
    end

    def immediate_email!
      response = client.send_email(
        source: source,
        destination: destination,
        message: data
      )
      OpenStruct.new(
        message_id: response.message_id,
        successful?: true,
        message: "Email immediately sent"
      )
    rescue Exception => _e
      # Set the resp to be unsuccessful so that it can get logged
      @resp = OpenStruct.new(successful?: false)
      raise
    end

    def delay_email_job?
      delayed_time.present? && delayed_time != 0
    end

    def delayed_email_job
      Vineti::Notifications::NotificationMailJob
        .set(wait: delayed_time.minutes)
        .perform_later(
          source: source,
          destination: destination,
          message: data,
          transaction_id: @transaction&.transaction_id,
          email_log_attributes: email_log_attributes,
          log_email?: event? || publisher?
        )
      OpenStruct.new(
        message_id: nil,
        message: "Notifications scheduled after #{delayed_time.minutes} minutes.",
        successful?: true
      )
    end
  end
end
