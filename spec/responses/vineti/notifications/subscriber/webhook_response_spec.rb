require 'rails_helper'

module Vineti::Notifications
  describe Subscriber::WebhookResponse do
    subject { described_class.new(response, msg) }

    let(:response) do
      OpenStruct.new(body: 'This is dummy response body', code: 200)
    end
    let(:msg) do
      OpenStruct.new(payload: 'This is dummy payload')
    end

    describe 'initialize' do
      it 'Creates object with instance variables' do
        expect(subject.response).to eq(response)
        expect(subject.msg_obj).to eq(msg)
      end
    end

    describe '#body' do
      it 'returns a response body' do
        expect(subject.body).to eq(response.body)
      end
    end

    describe '#code' do
      it 'returns a response code' do
        expect(subject.code).to eq(response.code)
      end
    end

    describe '#payload' do
      it 'returns payload from message' do
        expect(subject.payload).to eq(msg.payload)
      end
    end

    describe '#id' do
      it 'returns hard coded id as current' do
        expect(subject.id).to eq('current')
      end
    end
  end
end
