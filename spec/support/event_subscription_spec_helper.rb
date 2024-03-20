module EventSubscriptionSpecHelper
  RSpec.shared_examples_for 'event subscription' do
    it 'calls amq with correct params' do
      expect(stomp_connection).to receive(:subscribe).with(destination, anything)
      expect(subject.first[:subscriber_id]).to include(subscriber_id)
    end
  end
end
