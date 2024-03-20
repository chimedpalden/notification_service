require 'rails_helper'

module Vineti::Notifications
  describe Publish do
    describe "to_event" do
      subject { described_class.to_event(event_name, publish_type, payload, headers) }

      let(:event_name) { "test_event" }
      let(:publish_type) { "topic" }
      let(:headers) { {} }
      let(:payload) do
        {
          metadata: {}
        }
      end
      let(:result) do
        {
          message: "Published to topic",
          success: true,
          transaction_id: SecureRandom.hex
        }
      end

      before do
        allow(::EventServiceClient::Publish).to receive(:to_topic).and_return(result)
      end

      context 'should publish to event' do
        it 'should publish to event' do
          expect(subject.result[:success]).to eq(true)
          expect(subject).to be_instance_of(Vineti::Notifications::ActivemqPublishSuccessResponse)
          expect(subject.result).to eq(result)
        end
      end

      context 'persist_event_notification_transaction' do
        it 'Creates event transacation' do
          expect { described_class.to_event(event_name, publish_type, payload) }.to change { Vineti::Notifications::EventTransaction.count }
        end
      end
    end
  end
end
