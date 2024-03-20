require 'rails_helper'
require 'amq_connection_pool_monitor'
require 'activemq_monitor'

describe EventServiceClient::AmqConnectionPoolMonitor do
  subject { EventServiceClient::AmqConnectionPoolMonitor.new }

  let!(:email_subscriber) { FactoryBot.create(:email_subscriber) }

  describe '#db_clients' do
    it 'returns event subscribers in the desired format' do
      clients = "#{email_subscriber.events.first.name}/#{email_subscriber.subscriber_id}"
      expect(subject.db_clients).to include(clients)
    end
  end

  describe '#sync_client_pool' do
    before do
      allow(Vineti::Notifications::SubscriptionManager).to receive(:create_event_subscriber)
    end

    it 'creates event subscriber in activemq' do
      expect(Vineti::Notifications::SubscriptionManager).to receive(:create_event_subscriber).with(email_subscriber.events.first.name, email_subscriber.subscriber_id)
      subject.sync_client_pool([])
    end
  end
end
