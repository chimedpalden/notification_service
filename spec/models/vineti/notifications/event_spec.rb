require 'rails_helper'

module Vineti::Notifications
  RSpec.describe Event, type: :model do
    let(:event) { FactoryBot.create(:event) }
    let(:event_without_name) { FactoryBot.build(:event, :without_name) }

    describe 'Checkes if object is validated' do
      it 'Passes validation if name is present' do
        expect(event.valid?).to be true
      end

      it 'Fails validation is name is empty' do
        expect(event_without_name.valid?).to be false
      end
    end

    describe '#email_subscribers' do
      subject { event.email_subscribers }

      let(:event) { FactoryBot.create(:event, :with_email_subscriber) }

      it 'returns all records with type email' do
        expect(subject.count).not_to eq(0)
        expect(subject.pluck(:type).uniq).to eq(['Vineti::Notifications::Subscriber::EmailSubscriber'])
      end
    end

    describe '#webhook_subscribers' do
      subject { event.webhook_subscribers }

      let(:event) { FactoryBot.create(:event, :with_webhook_subscriber) }

      it 'returns all webhook subscribers for event' do
        expect(subject.count).not_to eq(0)
        expect(subject.pluck(:type).uniq).to eq(['Vineti::Notifications::Subscriber::WebhookSubscriber'])
      end
    end
  end
end
