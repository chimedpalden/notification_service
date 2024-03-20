# frozen_string_literal: true

require 'oauth2'

module Vineti::Notifications
  class Subscriber::WebhookService
    include Vineti::Notifications::ServiceHelper
    attr_accessor :payload, :topic, :subscriber, :metadata, :parent_transaction_id, :retry_transaction_id, :for_redelivery

    def initialize(topic:, payload:, subscriber:, metadata:, parent_transaction_id: nil, retry_transaction_id: nil, for_redelivery: false)
      @payload = (payload || {}).try(:with_indifferent_access)
      @topic = topic
      @subscriber = subscriber.reload
      @metadata = (metadata || {}).try(:with_indifferent_access)
      @parent_transaction_id = parent_transaction_id
      @retry_transaction_id = retry_transaction_id
      @for_redelivery = for_redelivery
    end

    def send_notification
      @transaction = for_redelivery ? get_transaction_and_update_redelivery_count(payload) : get_retry_transaction(payload)
      @wso_payload = create_wso_payload
      @payload = create_payload
      create_webhook_notification_event
      @target_url = subscriber.data['webhook_url']
      @token_url = subscriber.data["token_url"]
      @vault_key = subscriber.data["vault_key"]
      send_data_to_wso_service
    end

    private

    def create_payload
      if event?
        { events: [payload[:events]&.first], id: @transaction.transaction_id }
      else
        { publisher: payload&.merge(id: @transaction.transaction_id) }
      end
    end

    def create_wso_payload
      if event?
        { event: payload[:events]&.first }
      else
        { publisher: payload&.merge(id: @transaction.transaction_id) }
      end
    end

    def send_data_to_wso_service
      Rails.logger.info("\n------ Sending data to WSO server -----\n")

      data = @wso_payload.deep_transform_keys do |key|
        if %w[event_name data_changes].include?(key.to_s)
          key.to_s.camelize(:lower)
        else
          key
        end
      end&.to_json

      response = RestClient::Request.execute(
        method: wso2.wso_service_http_method,
        url: wso2.wso2_service_url,
        payload: data,
        headers: wso_service_headers
      )
      @transaction.update!(status: "WSO_SUCCESS")
      Rails.logger.info "Successfully delivered event payload to WSO."
      msg_obj = Struct.new(:payload).new(@payload)
      Vineti::Notifications::Subscriber::WebhookResponse.new(response, msg_obj)
    rescue StandardError => e
      Rails.logger.error "Failed to deliver event payload to WSO. Error# #{e.message} \n\tat #{e.backtrace.join("\n\tat ")}"
      Airbrake.notify(e, subscriber_id: subscriber.subscriber_id, created_at: Time.now.utc, transaction_id: @transaction.transaction_id) if defined?(Airbrake)
      @transaction.update!(status: "WSO_ERROR")
      Vineti::Notifications::Subscriber::WebhookErrorResponse.new(e)
    end

    def wso_service_headers
      common_headers = {
        'Content-Type' => 'application/json',
        'X-target-url' => @target_url,
        'X-transaction-id' => @transaction.transaction_id,
        'X-subscriber-id' => @subscriber.subscriber_id,
      }.merge(wso2.oauth_token)

      return common_headers.merge(oauth_outbound_headers) if @token_url.present?
      return common_headers.merge(basic_outbound_headers) if @token_url.blank?
    end

    def oauth_outbound_headers
      {
        'X-Authorization-Event' => "Bearer #{@vault_key}",
        'X-token-url' => @token_url
      }
    end

    def basic_outbound_headers
      {
        'X-Authorization-Event' => "Basic #{@vault_key}"
      }
    end

    def wso2
      @_wso2 ||= Wso2.new
    end

    def create_webhook_notification_event
      # TODO: vineti_notifications: This code created dependency on platform
      # When removing notification as separate service, handle this logic as well.
      # We can add this logic in `prepare_event_notifications` but then we won't be able to capture the status
      # So adding this here for now as we do get status for operation which we need in coi report
      keys = %i[treatment_id procedure_name step_name order_status]
      return unless keys.all? { |k| metadata.key? k }

      metadata.merge!(subscriber_id: subscriber.subscriber_id, event_name: topic.try(:name) || topic.try(:publisher_id))
      ::Event::WebhookNotificationSent.record(metadata, @transaction.id)
    end
  end
end
