require 'rails_helper'

module Vineti::Notifications::DefaultConsumers
  RSpec.describe ResponseQueue do
    describe '#process' do
      subject { described_class.process(payload) }

      before do
        allow(Vineti::Notifications::DefaultConsumers::BaseConsumer)
          .to receive(:process_queue_response)
          .with('Response', payload)
      end

      let(:payload) { {} }

      it 'calls process_queue_response with correct params' do
        subject
        expect(::Vineti::Notifications::DefaultConsumers::BaseConsumer).to have_received(:process_queue_response).once
      end
    end
  end
end
