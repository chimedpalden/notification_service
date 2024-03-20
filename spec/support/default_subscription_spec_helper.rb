module DefaultSubscriptionSpecHelper
  RSpec.shared_examples_for 'default_subscriptions_list' do
    it 'returns default subscription list' do
      expect(subject[drop_queue.to_s]).to eq('drop_queue')
      expect(subject[response_queue.to_s]).to eq('response_queue')
      expect(subject['topic_subscription']).to eq('topic_subscription')
      expect(subject['topic_unsubscription']).to eq('topic_unsubscription')
      expect(subject['vineti_event']).to eq('vineti_event')
    end
  end
end
