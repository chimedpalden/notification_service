module NotificationControllerHelper
  RSpec.shared_examples_for 'notification controller successful publish' do
    it 'publishes event to all the respective subscribers' do
      response = JSON.parse(subject.body)
      expect(response['data']['type']).to eq("activemq")
      expect(response['data']['attributes']['result']['success']).to eq(true)
      expect(response['data']['attributes']).to eq("result" => {
                                                     "message" => "Published to topic #{event.name}",
                                                     "success" => true,
                                                     "transaction_id" => transaction_id
                                                   })
    end
  end

  RSpec.shared_examples_for 'notification controller unsuccessful publish' do
    it 'publishes event to all the respective subscribers' do
      response = JSON.parse(subject.body)
      expect(response['data']['attributes']['result']['success']).to eq(false)
      expect(response['data']['type']).to eq("activemq_error")
    end
  end

  # TODO: implement feature flagging
  RSpec.shared_examples_for 'notification controller send notification' do
    context 'When valid params are passed' do
      context 'when enabled' do
        context 'when the publish is success' do
          context 'When virtual topics are enabled' do
            let(:destination) { "/topic/VirtualTopic.#{event.name}" }

            it_behaves_like 'notification controller successful publish'
          end

          # context 'When virtual topics are disabled', enable_virtual_topics: :disabled do
          #   let(:enable_virtual_topics) { false }
          #   let(:destination) { "/topic/#{event.name}" }

          #   it_behaves_like 'notification controller successful publish'
          # end
        end

        # context 'when the publish is not success' do
        #   before do
        #     allow(stomp_connection).to receive(:publish).and_raise('Stomp publish error')
        #   end

        #   context 'When virtual topics are enabled', enable_virtual_topics: :enabled do
        #     let(:destination) { "/topic/VirtualTopic.#{event.name}" }

        #     it_behaves_like 'notification controller unsuccessful publish'
        #   end

        #   context 'When virtual topics are disabled', enable_virtual_topics: :disabled do
        #     let(:enable_virtual_topics) { false }
        #     let(:destination) { "/topic/#{event.name}" }

        #     it_behaves_like 'notification controller unsuccessful publish'
        #   end
        # end
      end

      # context 'when disabled', vineti_activemq_enable: :disabled, enable_virtual_topics: :enabled do
      #   it 'does not initialize activemq service' do
      #     expect(stomp_connection).not_to receive(:publish).with("/topic/#{event.name}", event_data.to_json, 'JMSCorrelationID' => 'abcd1234')
      #     expect(stomp_connection).not_to receive(:close)
      #     response = JSON.parse(subject.body)
      #     expect(response['data']['attributes']['correlation_id']).to be nil
      #   end
      # end
    end
  end
end
