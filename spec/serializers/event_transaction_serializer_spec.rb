require 'rails_helper'

describe EventTransactionSerializer do
  subject { described_class.new(object: event_transaction).as_jsonapi[:attributes] }

  let(:event_transaction) { FactoryBot.create(:event_transaction) }

  it 'returns serialized atrributes from record passed' do
    expect(subject.keys).to eq(%i[transaction_id payload status response_code response subscriber])
  end
end
