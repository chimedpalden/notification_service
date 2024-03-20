require 'rails_helper'

module Vineti::Notifications
  RSpec.describe EventPublisher, type: :model do
    context 'Validations' do
      subject { event_publisher.valid? }

      let(:errors) { event_publisher.errors.full_messages.join(', ') }

      describe 'When event is empty' do
        let(:event_publisher) { FactoryBot.build(:event_publisher, :without_event) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(errors).to eq("Event must exist, Event can't be blank")
        end
      end

      describe 'When publisher is empty' do
        let(:event_publisher) { FactoryBot.build(:event_publisher, :without_publisher) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(errors).to eq("Publisher must exist, Publisher can't be blank")
        end
      end

      describe 'When duplicate subscriber is passed' do
        let(:first_publisher) { FactoryBot.create(:event_publisher) }
        let(:event_publisher) { FactoryBot.build(:event_publisher) }

        it 'Returns false for validation check' do
          event_publisher.event = first_publisher.event
          event_publisher.publisher = first_publisher.publisher

          expect(subject).to be false
          expect(errors).to eq("Event has already been taken")
        end
      end
    end
  end
end
