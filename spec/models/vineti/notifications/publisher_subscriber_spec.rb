require 'rails_helper'

module Vineti::Notifications
  RSpec.describe PublisherSubscriber, type: :model do
    context 'Validations' do
      subject { publisher_subscriber.valid? }

      let(:errors) { publisher_subscriber.errors.full_messages.join(', ') }

      describe 'When publisher is empty' do
        let(:publisher_subscriber) { FactoryBot.build(:publisher_subscriber, :without_publisher) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(errors).to eq("Publisher must exist, Publisher can't be blank")
        end
      end

      describe 'When subscriber is empty' do
        let(:publisher_subscriber) { FactoryBot.build(:publisher_subscriber, :without_subscriber) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(errors).to eq("Subscriber must exist, Subscriber can't be blank")
        end
      end

      describe 'When duplicate subscriber is passed' do
        let(:first_subscriber) { FactoryBot.create(:publisher_subscriber) }
        let(:publisher_subscriber) { FactoryBot.build(:publisher_subscriber) }

        it 'Returns false for validation check' do
          publisher_subscriber.publisher = first_subscriber.publisher
          publisher_subscriber.subscriber = first_subscriber.subscriber

          expect(subject).to be false
          expect(errors).to eq("Publisher has already been taken")
        end
      end
    end
  end
end
