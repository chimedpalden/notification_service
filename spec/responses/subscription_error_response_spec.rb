require 'rails_helper'

describe SubscriptionErrorResponse do
  let(:response) do
    described_class.new(
      DummyError.new('Test msg', 'backtrace path')
    )
  end

  describe '#message' do
    subject { response.message }

    it 'returns the message from error object' do
      expect(subject).to eq('Test msg')
    end
  end

  describe '#backtrace' do
    subject { response.backtrace }

    it 'returns backtrace from error object' do
      expect(subject).not_to be nil
      expect(subject).to eq(['backtrace path'])
    end
  end

  describe '#id' do
    subject { response.id }

    it 'returns id' do
      expect(subject).to eq('current')
    end
  end
end
