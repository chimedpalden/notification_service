require 'rails_helper'

module Vineti::Notifications
  RSpec.describe Subscriber::WebhookSubscriber, type: :model do
    context 'Validation' do
      subject { webhook_subscriber.valid? }

      describe 'When subscription id is missing' do
        let(:webhook_subscriber) { FactoryBot.build(:webhook_subscriber, :without_subscriber_id) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(webhook_subscriber.errors.full_messages).to eq(["Subscriber can't be blank"])
        end
      end

      describe 'When subscription id is duplicate' do
        let(:webhook_subscriber) { FactoryBot.create(:webhook_subscriber) }
        let(:webhook_subscriber2) { FactoryBot.create(:webhook_subscriber) }

        it 'Returns false for validation check' do
          webhook_subscriber.subscriber_id = webhook_subscriber2.subscriber_id
          expect(subject).to be false
          expect(webhook_subscriber.errors.full_messages).to eq(["Subscriber has already been taken"])
        end
      end

      describe 'when subscription id starts with internal word' do
        it 'Returns false for validation check' do
          subscriber = FactoryBot.build(:webhook_subscriber, subscriber_id: "internal-subscriber-sample")
          expect(subscriber.valid?).to be(false)
        end
      end

      describe 'When webhook url is missing from json data' do
        let(:webhook_subscriber) { FactoryBot.build(:webhook_subscriber, :without_webhook_url) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(webhook_subscriber.errors.full_messages).to eq(["Data Missing webhook url in json data"])
        end
      end

      describe 'When vault_key is missing from json data' do
        let(:webhook_subscriber) { FactoryBot.build(:webhook_subscriber, :without_vault_key) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(webhook_subscriber.errors.full_messages).to eq(["Data Missing vault_key in json data"])
        end
      end

      describe 'When token_url is missing from json data' do
        let(:webhook_subscriber) { FactoryBot.build(:webhook_subscriber, :without_token_url) }

        it 'Returns true for validation check' do
          expect(subject).to be true
          expect(webhook_subscriber.errors.full_messages).to eq([])
        end
      end

      describe 'When webhook url is blank in json data' do
        let(:webhook_subscriber) { FactoryBot.build(:webhook_subscriber, :with_blank_webhook_url) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(webhook_subscriber.errors.full_messages).to eq(["Data Missing webhook url in json data"])
        end
      end

      describe 'When vault_key is nil in json data' do
        let(:webhook_subscriber) { FactoryBot.build(:webhook_subscriber, :with_blank_vault_key) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(webhook_subscriber.errors.full_messages).to eq(["Data Missing vault_key in json data"])
        end
      end

      describe 'When token_url is nil in json data' do
        let(:webhook_subscriber) { FactoryBot.build(:webhook_subscriber, :with_blank_token_url) }

        it 'Returns true for validation check' do
          expect(subject).to be true
          expect(webhook_subscriber.errors.full_messages).to eq([])
        end
      end

      describe 'When data is not present' do
        let(:webhook_subscriber) { FactoryBot.build(:webhook_subscriber, :without_data) }
        let(:error_message) { 'Data Missing json information for subscription' }

        it 'returns nil response with error message' do
          expect(subject).to be false
          expect(webhook_subscriber.errors.full_messages).to eq([error_message])
        end
      end
    end
  end
end
