module Vineti::Notifications::DefaultConsumers
  class DropQueue < Vineti::Notifications::DefaultConsumers::BaseConsumer
    def self.process(payload)
      process_queue_response('DLQ', payload, true)
    end
  end
end
