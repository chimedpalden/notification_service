# frozen_string_literal: true

module Vineti::Notifications
  class Subscriber::InternalApiSubscriber < Vineti::Notifications::Subscriber
    # NOTE:
    # this file/class will not be reloaded in development due to
    # explicit require in initializers/activemq

    validate :subscriberId

    def subscriberId
      errors.add(:subscriber_id, 'internalApi type subscriber should start with internal-') unless subscriber_id =~ /^internal-subscriber/
    end
  end
end
