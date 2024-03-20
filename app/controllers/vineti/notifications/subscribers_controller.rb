# frozen_string_literal: true

require 'stomp'

NOTIFICATIONS_SUBSCRIBER_CLASS = {
  email: Vineti::Notifications::Subscriber::EmailSubscriber,
  webhook: Vineti::Notifications::Subscriber::WebhookSubscriber,
  internal_api: Vineti::Notifications::Subscriber::InternalApiSubscriber,
}.with_indifferent_access.freeze

module Vineti::Notifications
  class SubscribersController < Vineti::Notifications::ApplicationController
    before_action :fetch_subscriber!, only: %i[destroy show]
    before_action :fetch_template, :fetch_subscriber_data, only: %i[create]
    before_action :fetch_class, only: %i[create]

    def index
      render_result(Vineti::Notifications::Subscriber.all)
    end

    def show
      render_result(@subscriber)
    end

    def create
      ActiveRecord::Base.transaction do
        @subscriber = @subscriber_class.create!(@subscriber_data)
        create_event_subscriber_association!
      end
      render_result(@subscriber)
    end

    def destroy
      @event_names = @subscriber.events.pluck(:name)
      @subscriber.destroy!
      delete_activemq_subscriptions
      render_result(@subscriber)
    end

    private

    def delete_activemq_subscriptions
      @event_names.each do |event_name|
        event_data = {
          event_name: event_name,
          subscriber_id: @subscriber.subscriber_id
        }
        ::EventServiceClient::Publish.to_topic('topic_unsubscription', event_data)
      end
    end

    def fetch_subscriber!
      @subscriber = Vineti::Notifications::Subscriber.find_by!(params.permit(:subscriber_id))
    end

    def subscriber_params
      params.require(:subscriber).permit(:subscriber_id, :active, :delayed_time, data: {}).merge(template: @template)
    end

    def fetch_template
      @template = Vineti::Notifications::Template.find_by(template_id: params.require(:subscriber)[:template_id])
    end

    def create_event_subscriber_association!
      event_name = nil
      events = params.require(:subscriber).require(:event_names).map do |name|
        event_name = name
        Vineti::Notifications::Event.find_by!(name: name)
      end
      @subscriber.events << events
    rescue ActiveRecord::RecordNotFound => _e
      raise ActiveRecord::RecordNotFound,
            "Event with name #{event_name} is not present. Please use 'GET /events_list' to find out all events that can be used"
    end

    def fetch_class
      type = params.require(:subscriber).require(:type)
      @subscriber_class = begin
                            NOTIFICATIONS_SUBSCRIBER_CLASS.fetch(type)
                          rescue Exception => _e
                            nil
                          end
      return unless @subscriber_class.nil?

      render json: { status: 'Incorrect Subscriber Type, Did you mean \'webhook\', \'email\' or \'internal_api\'' }, status: 400
    end

    def render_result(result)
      render jsonapi: result,
             include: [subscriber: %i[template event]],
             class: {
               'Vineti::Notifications::Subscriber': SubscriberSerializer,
               'Vineti::Notifications::Subscriber::EmailSubscriber': SubscriberSerializer,
               'Vineti::Notifications::Subscriber::WebhookSubscriber': SubscriberSerializer,
               'Vineti::Notifications::Subscriber::InternalApiSubscriber': SubscriberSerializer,
             }
    end

    def fetch_subscriber_data
      @subscriber_data = subscriber_params.to_h
    end
  end
end
