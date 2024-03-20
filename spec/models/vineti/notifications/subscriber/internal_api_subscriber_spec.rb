require 'rails_helper'

module Vineti::Notifications
  RSpec.describe Subscriber::InternalApiSubscriber, type: :model do
    context 'Validation' do
      subject { internal_api_subscriber.valid? }

      describe 'When subscription id is missing' do
        let(:internal_api_subscriber) { FactoryBot.build(:internal_api_subscriber, subscriber_id: nil) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(internal_api_subscriber.errors.full_messages).to include("Subscriber can't be blank")
        end
      end

      describe 'When subscription id is duplicate' do
        let(:internal_api_subscriber) { FactoryBot.create(:internal_api_subscriber) }
        let(:internal_api_subscriber2) { FactoryBot.create(:internal_api_subscriber) }

        it 'Returns false for validation check' do
          internal_api_subscriber.subscriber_id = internal_api_subscriber2.subscriber_id
          expect(subject).to be false
          expect(internal_api_subscriber.errors.full_messages).to eq(["Subscriber has already been taken"])
        end
      end

      describe 'when subscription id does not starts with internal word' do
        it 'Returns false for validation check' do
          subscriber = FactoryBot.build(:internal_api_subscriber, subscriber_id: "sample")
          expect(subscriber.valid?).to be(false)
        end
      end
    end
  end
end
