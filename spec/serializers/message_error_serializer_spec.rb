require 'rails_helper'

describe MessageErrorSerializer do
  subject { described_class.new(object: message_error).as_jsonapi[:attributes] }

  before do
    message_error.set_backtrace 'backtrace path'
  end

  let(:message_error) { ActiveRecord::RecordNotFound.new('Test message') }
  let(:serialized_response) do
    {
      message: 'Test message',
      backtrace: ['backtrace path'],
    }
  end

  it 'returns serialized atrributes from record passed' do
    expect(subject).to eq(serialized_response)
  end
end
