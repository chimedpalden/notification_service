module Vineti::Notifications::DefaultConsumers
  class ResponseQueue < Vineti::Notifications::DefaultConsumers::BaseConsumer
    def self.process(payload)
      process_queue_response('Response', payload)
    end
  end
end
