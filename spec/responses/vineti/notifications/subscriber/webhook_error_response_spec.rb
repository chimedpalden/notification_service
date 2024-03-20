require 'rails_helper'

module Vineti::Notifications
  describe Subscriber::WebhookErrorResponse do
    let(:error) { DummyError.new('Runtime Error', 'backtrace') }
    let(:response) { described_class.new(error) }

    describe '#initialize' do
      it 'returns initialized object with error passed' do
        expect(response.error).to eq(error)
      end
    end

    describe '#message' do
      subject { response.message }

      it 'returns error message' do
        expect(subject).to eq('Runtime Error')
      end
    end

    describe '#backtrace' do
      subject { response.backtrace }

      it 'returns backtrace from error class if any' do
        expect(subject).not_to be nil
        expect(subject).to eq(['backtrace'])
      end
    end

    describe 'id' do
      subject { response.id }

      it 'returns id of current object' do
        expect(subject).to eq('current')
      end
    end
  end
end
