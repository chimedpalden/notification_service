require 'rails_helper'

describe SubscriptionResponse do
  let(:subscription) do
    OpenStruct.new(
      subscription_arn: 'subscription_arn',
      topic_arn: 'topic_arn',
      endpoint: 'localhost',
      protocol: 'smtp',
      owner: 'vineti'
    )
  end
  let(:response) do
    described_class.new(
      Struct.new(:arn, :subscriptions).new('1234', [subscription])
    )
  end

  describe '#arn' do
    subject { response.arn }

    it 'returns arn from response' do
      expect(subject).to eq('1234')
    end
  end

  describe '#list' do
    subject { response.list }

    let(:subscription_list) do
      [
        {
          subscription_arn: "subscription_arn",
          topic_arn: "topic_arn",
          endpoint: "localhost",
          protocol: "smtp",
          owner: "vineti",
        },
      ]
    end

    it 'returns list for subscriptions from response' do
      expect(subject).to eq(subscription_list)
    end
  end

  describe '#id' do
    subject { response.id }

    it 'returns id from response object' do
      expect(subject).to eq('current')
    end
  end
end
