# frozen_string_literal: true

module Vineti::Notifications
  class ActivemqPublishErrorResponse
    attr_reader :error

    delegate :message, :backtrace, to: :error, allow_nil: true

    def initialize(error)
      @error = error
    end

    def id
      'current'
    end
  end
end
