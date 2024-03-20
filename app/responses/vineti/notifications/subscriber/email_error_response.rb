# frozen_string_literal: true

module Vineti::Notifications
  class Subscriber::EmailErrorResponse
    attr_reader :response

    delegate :message, :backtrace, to: :response

    def initialize(response)
      @response = response
    end

    def id
      'current'
    end
  end
end
