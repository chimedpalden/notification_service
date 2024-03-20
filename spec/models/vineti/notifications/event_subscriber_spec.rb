require 'rails_helper'

module Vineti::Notifications
  RSpec.describe EventSubscriber, type: :model do
    context 'Validations' do
      subject { event_subscriber.valid? }

      let(:errors) { event_subscriber.errors.full_messages.join(', ') }

      describe 'When event is empty' do
        let(:event_subscriber) { FactoryBot.build(:event_subscriber, :without_event) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(errors).to eq("Event must exist, Event can't be blank")
        end
      end

      describe 'When subscriber is empty' do
        let(:event_subscriber) { FactoryBot.build(:event_subscriber, :without_subscriber) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(errors).to eq("Subscriber must exist, Subscriber can't be blank")
        end
      end

      describe 'When duplicate subscriber is passed' do
        let(:first_subscriber) { FactoryBot.create(:event_subscriber) }
        let(:event_subscriber) { FactoryBot.build(:event_subscriber) }

        it 'Returns false for validation check' do
          event_subscriber.event = first_subscriber.event
          event_subscriber.subscriber = first_subscriber.subscriber

          expect(subject).to be false
          expect(errors).to eq("Event has already been taken")
        end
      end
    end
  end
end
