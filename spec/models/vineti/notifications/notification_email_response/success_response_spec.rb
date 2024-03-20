require 'rails_helper'

RSpec.describe Vineti::Notifications::NotificationEmailResponse::SuccessResponse, type: :model do
  describe 'When message_id is missing from response json' do
    subject { response.save! }

    let(:response) { FactoryBot.create(:success_response, :without_message_id) }

    it 'Raises an error' do
      expect { subject }.to raise_error(ArgumentError)
    end
  end

  describe '.record' do
    subject { Vineti::Notifications::NotificationEmailResponse::SuccessResponse.record(response, log) }

    let(:response) { { 'message_id' => 'abc_123', 'mail_body' => { 'subject' => 'test', 'body' => {} } } }
    let(:log) { FactoryBot.create(:notification_email_log) }

    context 'When reference for log is not passed' do
      let(:log) { nil }

      it 'Raises an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'When valid params are passed' do
      it 'Creates a success response object' do
        expect(subject.email_log).to eq(log)
        expect(subject.response).to eq(response)
      end
    end
  end
end
