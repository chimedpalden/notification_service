# frozen_string_literal: true

module Vineti::Notifications
  class MailsController < Vineti::Notifications::ApplicationController
    before_action :fetch_event, :fetch_template_data, :fetch_delayed_time

    def send_event_notification
      render jsonapi: Vineti::Notifications::Subscriber::EmailService.new(topic: @event,
                                                                          template_data: @template_data,
                                                                          delayed_time: @delayed_time).send_notification,
             class: { 'Vineti::Notifications::Subscriber::EmailResponse': Vineti::Notifications::Subscriber::EmailResponseSerializer }
    rescue StandardError => e
      render jsonapi_errors: Vineti::Notifications::Subscriber::EmailErrorResponse.new(e),
             class: { 'Vineti::Notifications::Subscriber::EmailErrorResponse': Vineti::Notifications::Subscriber::EmailErrorResponseSerializer }
    end

    private

    def fetch_event
      event_name = params.require(:mail).permit(:event_name)[:event_name]
      @event = Vineti::Notifications::Event.find_by!(name: event_name)
    end

    def fetch_template_data
      @template_data = params.require(:mail).permit(template_data: {})[:template_data].to_h
    end

    def fetch_delayed_time
      @delayed_time = params.require(:mail).permit(:delayed_time)[:delayed_time]
    end
  end
end
