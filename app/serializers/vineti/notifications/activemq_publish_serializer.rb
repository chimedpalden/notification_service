# frozen_string_literal: true

module Vineti
  module Notifications
    class ActivemqPublishSerializer < JSONAPI::Serializable::Resource
      type 'activemq'

      attributes :result
    end
  end
end
