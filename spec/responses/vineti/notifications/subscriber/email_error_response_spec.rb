require 'rails_helper'

module Vineti::Notifications
  describe Subscriber::EmailErrorResponse do
    let(:error) { DummyError.new(error_message, 'backtrace path') }
    let(:error_message) { 'Runtime error for testing' }
    let(:response) { described_class.new error }

    describe '#initialize' do
      it 'returns initialized object with error object' do
        expect(response.response).to eq(error)
      end
    end

    describe '#message' do
      subject { response.message }

      it 'returns message from error object' do
        expect(subject).to eq(error_message)
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
end
