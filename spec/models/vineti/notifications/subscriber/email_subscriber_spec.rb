require 'rails_helper'

class UserRole end

module Vineti::Notifications
  RSpec.describe Subscriber::EmailSubscriber, type: :model do
    before do
      allow(UserRole).to receive_message_chain(:where, :blank?).and_return(true)
    end

    context 'Validation' do
      subject { email_subscriber.valid? }

      describe 'When subscription id is missing' do
        let(:email_subscriber) { FactoryBot.build(:email_subscriber, :without_subscriber_id) }

        it 'Raises a validation error' do
          expect(subject).to be false
          expect(email_subscriber.errors.full_messages).to eq(["Subscriber can't be blank"])
        end
      end

      describe 'When subscription id is duplicate' do
        let(:email_subscriber) { FactoryBot.create(:email_subscriber) }
        let(:email_subscriber_dup) { FactoryBot.create(:email_subscriber) }

        it 'Returns false for validation check' do
          email_subscriber.subscriber_id = email_subscriber_dup.subscriber_id
          expect(subject).to be false
          expect(email_subscriber.errors.full_messages).to eq(["Subscriber has already been taken"])
        end
      end

      describe 'when subscription id starts with internal word' do
        it 'Returns false for validation check' do
          subscriber = FactoryBot.build(:email_subscriber, subscriber_id: "internal-subscriber-sample")
          expect(subscriber.valid?).to be(false)
        end
      end

      describe 'When template is invalid' do
        let(:email_subscriber) { FactoryBot.build(:email_subscriber, :with_invalid_template) }

        it 'Raises a validation error' do
          expect(subject).to be false
          expect(email_subscriber.errors.full_messages).to eq(["Template is invalid", "Template must exist"])
        end
      end

      describe 'When from_address is missing from json data' do
        let(:email_subscriber) { FactoryBot.build(:email_subscriber, :without_from_address) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(email_subscriber.errors.full_messages.join(', ')).to eq(
            "Data Missing from_address from json data"
          )
        end
      end

      describe 'When from_address is invalid' do
        let(:email_subscriber) { FactoryBot.build(:email_subscriber, :with_invalid_from_address) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(email_subscriber.errors.full_messages).to eq(["Data #{email_subscriber.data['from_address']} in from_address is not a valid email address"])
        end
      end

      describe 'When to_addresses are missing from json data' do
        let(:email_subscriber) { FactoryBot.build(:email_subscriber, :without_to_addresses) }

        it 'Returns the false for validation check' do
          expect(subject).to be false
          expect(email_subscriber.errors.full_messages).to eq(["Data Missing to_addresses from json data"])
        end
      end

      describe 'When to_addresses are invalid' do
        let(:email_subscriber) { FactoryBot.build(:email_subscriber, :with_invalid_to_addresses) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(email_subscriber.errors.full_messages.join(', ')).to eq(
            "Data  in to_addresses is neither a valid email address nor a valid user role, Data test@ in to_addresses is neither a valid email address nor a valid user role"
          )
        end
      end

      describe 'When to addresses are blank' do
        let(:email_subscriber) { FactoryBot.build(:email_subscriber, :with_to_addresses_as_empty_array) }

        it 'Returns the false for validation check' do
          expect(subject).to be false
          expect(email_subscriber.errors.full_messages).to eq(["Data Missing to_addresses from json data"])
        end
      end

      describe 'When CC addresses are present and invalid' do
        let(:email_subscriber) { FactoryBot.build(:email_subscriber, :with_invalid_cc_addresses) }

        it 'Returns the false for validation check' do
          expect(subject).to be false
          expect(email_subscriber.errors.full_messages.join(', ')).to eq(
            "Data  in cc_addresses is neither a valid email address nor a valid user role, Data test@ in cc_addresses is neither a valid email address nor a valid user role"
          )
        end
      end
    end

    describe '#email_subscriber?' do
      subject { subscriber.email_subscriber? }

      context 'When called for email type subscriber' do
        let(:subscriber) { FactoryBot.create(:email_subscriber) }

        it 'returns true' do
          expect(subject).to be true
        end
      end

      context 'When called on webhook type subscriber' do
        let(:subscriber) { FactoryBot.create(:webhook_subscriber) }

        it 'returns false' do
          expect(subject).to be false
        end
      end
    end
  end
end
