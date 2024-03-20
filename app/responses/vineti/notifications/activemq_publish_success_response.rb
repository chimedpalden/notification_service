# frozen_string_literal: true

module Vineti::Notifications
  class ActivemqPublishSuccessResponse
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def id
      'current'
    end

    def result
      response[:result]
    end
  end
end
