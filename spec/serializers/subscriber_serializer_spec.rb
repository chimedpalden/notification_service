require 'rails_helper'

describe SubscriberSerializer do
  subject { described_class.new(object: subscriber).as_jsonapi[:attributes] }

  let(:subscriber) { FactoryBot.create(:email_subscriber) }

  it 'returns serialized atrributes from record passed' do
    expect(subject.keys).to eq(%i[subscriber_id data type active delayed_time events template])
  end
end
