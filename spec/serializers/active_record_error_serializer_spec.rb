require 'rails_helper'

describe ActiveRecordErrorSerializer do
  subject { described_class.new(object: error).as_jsonapi[:attributes] }

  before do
    error.set_backtrace 'backtrace path'
  end

  let(:error) { ActiveRecord::RecordNotFound.new('Test message') }
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
