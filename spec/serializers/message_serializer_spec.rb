require 'rails_helper'

describe MessageSerializer do
  subject { described_class.new(object: message).as_jsonapi[:attributes] }

  let(:message) { MessageResponse.new(response, msg_object) }
  let(:response) { Struct.new(:message_id).new('123') }
  let(:msg_object) { Struct.new(:text, :subject).new('Message Text', 'Message subject') }
  let(:serialized_response) do
    {
      message_id: '123',
      text: 'Message Text',
      subject: 'Message subject',
    }
  end

  it 'returns serialized atrributes from record passed' do
    expect(subject).to eq(serialized_response)
  end
end
