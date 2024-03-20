require 'rails_helper'

module Vineti::Notifications
  describe Subscriber::EmailResponse do
    let(:response) do
      described_class.new(
        DummyError.new('Test msg', 'backtrace path'),
        Struct.new(:text, :subject).new('This is text', 'This is subject')
      )
    end

    describe '#message' do
      subject { response.message }

      it 'Returns message' do
        expect(subject).to eq('Test msg')
      end
    end

    describe '#message_id' do
      subject { response.message_id }

      it 'returns message id' do
        expect(subject).to eq('message_id')
      end
    end

    describe '#backtrace' do
      subject { response.backtrace }

      it 'returns backtrace from error response' do
        expect(subject).not_to be nil
        expect(subject).to eq(['backtrace path'])
      end
    end

    describe '#text' do
      subject { response.text }

      it 'returns text from message object' do
        expect(subject).to eq('This is text')
      end
    end

    describe '#subject' do
      subject { response.subject }

      it 'returns subject from message object' do
        expect(subject).to eq('This is subject')
      end
    end
  end
end
