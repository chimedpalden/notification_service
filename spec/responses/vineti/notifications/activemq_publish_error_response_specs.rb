require 'rails_helper'

module Vineti::Notifications
  describe ActivemqPublishErrorResponse do
    let(:response) do
      described_class.new(
        DummyError.new('Test msg', 'backtrace path')
      )
    end

    describe '#message' do
      subject { response.message }

      it 'returns message from response' do
        expect(subject).to eq('Test msg')
      end
    end

    describe '#backtrace' do
      subject { response.backtrace }

      it 'returns backtrace from error response' do
        expect(subject).to eq(['backtrace path'])
        expect(subject).not_to be nil
      end
    end

    describe '#id' do
      subject { response.id }

      it 'returns id' do
        expect(subject).to eq('current')
      end
    end
  end
end
