module Vineti
  module Notifications
    module PubSubUpsertHelper
      private

      def upsert_subscribers(subscribers:, topic:)
        subscribers.each do |subscriber_group|
          template = Vineti::Notifications::Template.find_by(template_id: subscriber_group['template'])
          subscriber = Vineti::Notifications::Subscriber.find_by(subscriber_id: subscriber_group['subscriber_id'])
          attributes = subscriber_group.merge('template' => template)

          if subscriber.present?
            subscriber.update!(attributes.except('subscriber_id', 'type'))
            if topic.is_a? Vineti::Notifications::Event
              Vineti::Notifications::EventSubscriber.find_or_create_by!(event: topic, subscriber: subscriber)
            elsif topic.is_a? Vineti::Notifications::Publisher
              Vineti::Notifications::PublisherSubscriber.find_or_create_by!(publisher: topic, subscriber: subscriber)
            end
            Rails.logger.info "Updated email susbcriber group for #{topic.try(:name) || topic.try(:publisher_id)} with id #{subscriber_group['subscriber_id']}"
            next
          end

          subscriber_class = begin
                                "Vineti::Notifications::Subscriber::#{subscriber_group['type']&.titleize}Subscriber".constantize
                             rescue Exception => _e
                               nil
                              end

          raise "Undefined Subscriber Type" if subscriber_class.nil?

          subscriber = subscriber_class.create!(attributes.except('type'))
          if topic.is_a? Vineti::Notifications::Event
            subscriber.events << topic
          elsif topic.is_a? Vineti::Notifications::Publisher
            subscriber.publishers << topic
          end
          Rails.logger.info "Created subscriber group for #{topic.try(:name) || topic.try(:publisher_id)} with id #{subscriber.subscriber_id}"
        end
      rescue StandardError => e
        Rails.logger.error("Got error #{e.message} while creating/updating subscriber group for #{topic.try(:name) || topic.try(:publisher_id)}!!!")
        raise e
      end

      def upsert_publishers(publishers:, event:)
        publishers.each do |publisher_definition|
          template = Vineti::Notifications::Template.find_by(template_id: publisher_definition['template'])
          publisher = Vineti::Notifications::Publisher.find_by(publisher_id: publisher_definition['publisher_id'])
          attributes = publisher_definition.merge('template' => template)

          if publisher.present?
            publisher.update!(attributes.except('publisher_id', 'template_id', 'subscribers'))
            Vineti::Notifications::EventPublisher.find_or_create_by!(event: event, publisher: publisher)
            Rails.logger.info "Updated publisher group with id #{publisher_definition['publisher_id']}"
          else
            publisher = Vineti::Notifications::Publisher.create!(attributes.except('subscribers'))
            Vineti::Notifications::EventPublisher.find_or_create_by!(event: event, publisher: publisher)
            Rails.logger.info "Created publisher group for event #{event.name} with id #{publisher.publisher_id}"
          end

          upsert_subscribers(subscribers: publisher_definition['subscribers'], topic: publisher) if publisher_definition['subscribers'].present?
        end
        subscriber_id = Vineti::Notifications::Subscriber.internal_api_subscriber_id(event.name)
        subscriber = Vineti::Notifications::Subscriber::InternalApiSubscriber.find_or_create_by!(subscriber_id: subscriber_id)
        Vineti::Notifications::EventSubscriber.find_or_create_by!(event: event, subscriber: subscriber)
      rescue StandardError => e
        Rails.logger.error("Got error #{e.message} while creating/updating publisher group for event #{event.name}!!!")
        raise e
      end
    end
  end
end
