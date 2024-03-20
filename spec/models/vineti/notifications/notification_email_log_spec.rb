require 'rails_helper'

module Vineti::Notifications
  RSpec.describe NotificationEmailLog, type: :model do
    describe '.record' do
      subject { Vineti::Notifications::NotificationEmailLog.record(event, subscriber, template, message) }

      let(:subscriber) { FactoryBot.create(:email_subscriber) }
      let(:event) { subscriber.events.first }
      let(:template) { subscriber.template }
      let(:message) do
        {
          source: 'admin@vineti.com',
          destination: {
            to_addresses: ['user@vineti.com'],
          },
          mail_body: {},
          error: nil,
        }
      end

      it 'Creates a new record for log' do
        expect(subject.event).to eq(event)
        expect(subject.template).to eq(template)
        expect(subject.subscriber).to eq(subscriber)
      end
    end
  end
end
