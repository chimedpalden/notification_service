# frozen_string_literal: true

module Vineti::Notifications
  class Subscriber::WebhookResponse
    attr_reader :response, :msg_obj

    delegate :body, :code, to: :response
    delegate :payload, to: :msg_obj

    def initialize(response, msg_obj = {})
      @response = response
      @msg_obj = msg_obj
    end

    def id
      'current'
    end
  end
end
