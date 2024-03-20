require 'rails_helper'

RSpec.describe Vineti::Notifications::NotificationEmailResponse::ErrorResponse, type: :model do
  describe 'When error key is missing from response' do
    subject { FactoryBot.create(:error_response, :without_error) }

    it 'Raises an error' do
      expect { subject }.to raise_error(ArgumentError)
    end
  end

  describe '.record' do
    subject { Vineti::Notifications::NotificationEmailResponse::ErrorResponse.record(response, log) }

    let(:response) { { 'error' => 'Message Rejected', 'backtrace' => [] } }
    let(:log) { FactoryBot.create(:notification_email_log) }

    context 'When log reference is not present' do
      let(:log) { nil }

      it 'Raises error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'When valid params are passed' do
      it 'Creates the object' do
        expect(subject.email_log).to eq(log)
        expect(subject.response).to eq(response)
      end
    end
  end
end
