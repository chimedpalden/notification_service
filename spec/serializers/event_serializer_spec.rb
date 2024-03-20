require 'rails_helper'

describe EventSerializer do
  subject { described_class.new(object: event).as_jsonapi[:attributes] }

  let(:event) { FactoryBot.create(:event) }
  let(:serialized_response) do
    {
      name: event.name,
      subscribers: [],
    }
  end

  it 'returns serialized atrributes from record passed' do
    expect(subject).to eq(serialized_response)
  end
end
