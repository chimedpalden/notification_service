require 'rails_helper'

module Vineti::Notifications::DefaultConsumers
  RSpec.describe TopicSubscription do
    describe '#process' do
      subject { described_class.process(payload) }

      before do
        allow(Vineti::Notifications::SubscriptionManager)
          .to receive(:create_for)
          .with(subscriber_id)
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
        expect(::Vineti::Notifications::SubscriptionManager).to have_received(:create_for).once
      end
    end
  end
end
