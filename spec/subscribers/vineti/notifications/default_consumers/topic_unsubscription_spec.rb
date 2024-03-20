require 'rails_helper'

module Vineti::Notifications::DefaultConsumers
  RSpec.describe TopicUnsubscription do
    describe '#process' do
      subject { described_class.process(payload) }

      before do
        allow(::EventServiceClient::Manage)
          .to receive(:delete_subscriber)
          .with(event_name, subscriber_id)
      end

      let(:payload) do
        double(
          'Stomp::Message',
          body: {
            event_name: event_name,
            subscriber_id: subscriber_id
          }.with_indifferent_access
        )
      end
      let(:event_name) { 'test_event' }
      let(:subscriber_id) { 'test_subscriber' }

      it 'calls process_queue_response with correct params' do
        subject
        expect(::EventServiceClient::Manage).to have_received(:delete_subscriber).once
      end
    end
  end
end
