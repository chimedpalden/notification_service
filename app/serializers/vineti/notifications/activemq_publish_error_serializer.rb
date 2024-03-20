# frozen_string_literal: true

module Vineti
  module Notifications
    class ActivemqPublishErrorSerializer < JSONAPI::Serializable::Resource
      type 'activemq_error'

      attributes :message, :backtrace
    end
  end
end
