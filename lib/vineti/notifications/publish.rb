module Vineti
  module Notifications
    class Publish
      class << self
        def to_event(event_name, publish_type, event_data, headers = {}, persist_transaction = true)
          Vineti::Notifications::PublishService.new(event_name, publish_type, event_data, headers, persist_transaction).process
        end
      end
    end
  end
end
