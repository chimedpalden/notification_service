module EventServiceSpecHelper
  RSpec.shared_examples_for 'event service successful publish' do
    it 'returns success response' do
      expect(subject.result[:success]).to eq(true)
      expect(subject).to be_instance_of(Vineti::Notifications::ActivemqPublishSuccessResponse)
    end
  end

  RSpec.shared_examples_for 'event service unsuccessful publish' do
    it 'returns error response' do
      expect(subject).to be_instance_of(Vineti::Notifications::ActivemqPublishErrorResponse)
    end
  end

  RSpec.shared_examples_for 'event service publish' do
    context 'when disabled', vineti_activemq_enable: :disabled, enable_virtual_topics: :disabled do
      it 'does not initialize activemq service' do
        expect(stomp_connection).not_to receive(:publish).with("/topic/VirtualTopic.#{event_name}", event_data.to_json, 'JMSCorrelationID' => transaction_id, "transaction_id" => transaction_id)
        expect(stomp_connection).not_to receive(:close)
      end
    end

    context 'when enabled', vineti_activemq_enable: :enabled, enable_virtual_topics: :enabled do
      context 'when the activemq publish is success' do
        context 'When virtual topics are enabled' do
          let(:destination) { "/topic/VirtualTopic.#{event.name}" }

          it_behaves_like 'event service successful publish'
        end
      end

      context 'when the activemq publish is not success' do
        context 'When virtual topics are enabled' do
          let(:destination) { "/topic/VirtualTopic.#{event_name}" }
          let(:success) { false }

          it_behaves_like 'event service unsuccessful publish'
        end
      end
    end
  end
end
