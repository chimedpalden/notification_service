require 'rails_helper'

describe Vineti::Notifications::ConsumerSeeder do
  before do
    allow(::Vineti::Notifications::SubscriptionManager).to receive(:seed_default_subscribers)
    allow(::Vineti::Notifications::SubscriptionManager).to receive(:seed_custom_subscribers)
  end

  describe '#run' do
    subject { described_class.run }

    context 'when called' do
      it 'should seed default and custom subscribers' do
        subject
        expect(::Vineti::Notifications::SubscriptionManager).to have_received(:seed_default_subscribers).once
        expect(::Vineti::Notifications::SubscriptionManager).to have_received(:seed_custom_subscribers).once
      end
    end
  end
end
