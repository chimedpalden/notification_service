# frozen_string_literal: true

require 'rails_helper'

describe Vineti::Notifications::PublishService do
  let(:event_name) { "test_event" }
  let(:publish_type) { "topic" }
  let(:event_data) do
    {
      payload: {}
    }
  end
  let(:headers) { {} }
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

  let(:publish_service) do
    Vineti::Notifications::PublishService.new(event_name, publish_type, event_data, headers, true)
  end

  describe '#process_publish_service' do
    subject { publish_service.send(:process) }

    context 'should publish to event' do
      it 'should publish to event' do
        expect(subject.result[:success]).to eq(true)
        expect(subject).to be_instance_of(Vineti::Notifications::ActivemqPublishSuccessResponse)
        expect(subject.result).to eq(result)
      end
    end
  end

  describe '#persist_event_notification_transaction' do
    it 'Creates event transaction' do
      expect { publish_service.send(:persist_event_notification_transaction) }.to change { Vineti::Notifications::EventTransaction.count }
    end

    it 'Returns event transactions' do
      expect(publish_service.send(:persist_event_notification_transaction)).to be_instance_of(Vineti::Notifications::EventTransaction)
    end

    it 'Creates event transaction with created status' do
      transacation = publish_service.send(:persist_event_notification_transaction)
      expect(transacation.status).to eq('CREATED')
    end

    it 'Creates event transaction with CREATED status' do
      transaction = publish_service.send(:persist_event_notification_transaction)
      expect(transaction.status).to eq('CREATED')
    end
  end

  describe '#do_not_persist_event_notification_transaction' do
    let(:publish_without_transaction) do
      Vineti::Notifications::PublishService.new(event_name, publish_type, event_data, headers, false)
    end

    it 'does not persist event transaction' do
      expect { publish_without_transaction.send(:process) }.to change { Vineti::Notifications::EventTransaction.count }.by(0)
    end
  end
end
