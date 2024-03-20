# frozen_string_literal: true

module Vineti::Notifications
  class EventsController < Vineti::Notifications::ApplicationController
    before_action :fetch_event!, only: %i[show update destroy]
    before_action :fetch_subscriber_ids, only: %i[destroy]

    # List all registered events
    def index
      render_result(Vineti::Notifications::Event.all)
    end

    # List Event name and its subscribers
    def show
      render_result(@event)
    end

    # Create an event
    def create
      # no need to create a topic on AMQ with no subscription
      event = Vineti::Notifications::Event.create!(event_params)
      render_result(event)
    end

    # rename event and re-create subscribers connection in amq
    def update
      @event.update!(event_params)
      render_result(@event)
    end

    # delete the event and subscribers from db and amq
    def destroy
      @event.destroy!
      delete_activemq_subscriptions
      render_result(@event)
    end

    def list
      render json: { events: Vineti::Notifications::Event.pluck(:name) }
    end

    private

    def delete_activemq_subscriptions
      @subscriber_ids.each do |subscriber_id|
        event_data = {
          event_name: @event.name,
          subscriber_id: subscriber_id
        }
        ::EventServiceClient::Publish.to_topic('topic_unsubscription', event_data)
      end
    end

    def fetch_event!
      @event = Vineti::Notifications::Event.find_by!(event_name)
    end

    def fetch_subscriber_ids
      @subscriber_ids = @event.subscribers.pluck(:subscriber_id)
    end

    def event_params
      params.require(:event).permit(:name)
    end

    def event_name
      params.permit(:name)
    end

    def render_result(result)
      render jsonapi: result,
             include: [event: :subscribers],
             class: { 'Vineti::Notifications::Event': EventSerializer }
    end
  end
end
