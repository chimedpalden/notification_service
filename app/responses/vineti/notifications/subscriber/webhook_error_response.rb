# frozen_string_literal: true

module Vineti::Notifications
  class Subscriber::WebhookErrorResponse
    attr_reader :error

    delegate :message, :backtrace, to: :error

    def initialize(error)
      @error = error
    end

    def id
      'current'
    end
  end
end
