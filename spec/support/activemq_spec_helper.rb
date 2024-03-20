module ActiveMQHelper
  def config_hash_json(topic_id, subscriber_id = nil)
    {
      :hosts => [{
        :login => ENV['VINETI_ACTIVEMQ_USER'] || 'admin',
        :passcode => ENV['VINETI_ACTIVEMQ_PASS'] || 'admin',
        :host => ENV['VINETI_ACTIVEMQ_HOST'] || 'activemq',
        :port => ENV['VINETI_ACTIVEMQ_PORT'].to_i || 61_613,
        :ssl => false,
      }],
      :reliable => false,
      :closed_check => false,
      :connect_headers => { :"client-id" => "#{topic_id}_#{subscriber_id}" },
      :max_reconnect_attempts => 5,
    }
  end

  def activemq_response(transaction_id: '', response_code: '', subscriber_id: Faker::Lorem.word, event_name: Faker::Lorem.word)
    OpenStruct.new(
      headers: {
        'X-transaction-id' => transaction_id,
        'X-subscriber-id' => '123456',
        'httpResponseCode' => response_code,
        'X-JMSXDeliveryCount' => 1,
      },
      body: {
        'subscriber_id': subscriber_id,
        'event_name': event_name
      }.to_json
    )
  end

  def topic_subscription_headers(subscription_name)
    {
      'ack' => 'client',
      'activemq.prefetchSize' => 1,
      'activemq.subscriptionName' => subscription_name
    }
  end

  RSpec.shared_examples_for 'activemq service initialization' do
    it 'Checks for the feature flags and destination to be present' do
      expect(subject.instance_variable_get(:@perform_amq_operation)).to eq(amq_flag)
      expect(subject.instance_variable_get(:@enable_virtual_topic)).to eq(virtual_topic_flag)
    end
  end

  RSpec.shared_examples_for 'activemq pool subscription' do
    let(:client_pool) { Vineti::Notifications::ActivemqService.class_variable_get(:@@client_pool) }

    it 'checks is subscriber client is preset in the client pool' do
      expect(client_pool[topic][subscriber_id]['client']).to eq(mock_client)
    end
  end

  RSpec.shared_examples_for 'activemq delete subscription' do
    context 'When amq is enabled', vineti_activemq_enable: :enabled do
      before do
        expect(mock_client).to receive(:subscribe)
        expect(mock_client).to receive(:unsubscribe).with("/topic/#{topic}")
        expect(mock_client).to receive(:close)
        activemq_service.subscribe_to_topic(subscriber_id) { |msg| }
      end

      let(:activemq_service) { Vineti::Notifications::ActivemqService.new(topic) }
      let(:topic) { Faker::Lorem.word }

      it 'deletes the active subscription' do
        expect(client_pool[topic][subscriber_id]['client']).to eq(mock_client)
        expect(subject).to eq(response)
      end
    end

    context 'When amq is disabled', vineti_activemq_enable: :disabled do
      before do
        expect(mock_client).not_to receive(:subscribe)
        expect(mock_client).not_to receive(:unsubscribe).with("/topic/#{topic}")
        expect(mock_client).not_to receive(:close)
        activemq_service.subscribe_to_topic(subscriber_id) { |msg| }
      end

      let(:activemq_service) { Vineti::Notifications::ActivemqService.new(topic) }
      let(:topic) { Faker::Lorem.word }

      it 'returns nil as subscription is not active' do
        expect(client_pool[topic][subscriber_id]).to be nil
        expect(subject).to be nil
      end
    end
  end

  RSpec.shared_examples_for 'activemq publish service' do
    context 'When amq is enabled', vineti_activemq_enable: :enabled do
      before do
        expect(mock_client).to receive(:publish).with(destination, data, 'JMSCorrelationID' => 'abcd_1234')
        expect(mock_client).to receive(:close)
      end

      context 'When virtual topics are enabled', enable_virtual_topics: :enabled do
        it 'publishes to destination and returns the correlation id' do
          expect(subject).to eq('abcd_1234')
        end
      end

      context 'When virtual topics are disabled', enable_virtual_topics: :disabled do
        it 'pubished to the destination and returns correlation id' do
          expect(subject).to eq('abcd_1234')
        end
      end
    end

    context 'When amq is disabled', vineti_activemq_enable: :disabled do
      context 'When virtual topics are enabled', enable_virtual_topics: :enabled do
        it 'returns nil' do
          expect(subject).to be nil
        end
      end

      context 'When virtual topics are disabled', enable_virtual_topics: :disabled do
        it 'returns nil' do
          expect(subject).to be nil
        end
      end
    end
  end

  RSpec.shared_examples_for 'activemq subscribe service' do
    context 'When amq is enabled', vineti_activemq_enable: :enabled do
      before do
        allow(mock_client).to receive(:subscribe).and_yield OpenStruct.new(nil)
        expect(mock_client).to receive(:subscribe).with(destination, headers)
      end

      context 'When virtual topics are enabled', enable_virtual_topics: :enabled do
        let(:topic) { Faker::Lorem.word }
        let(:subscriber_id) { Faker::Lorem.word }
        let(:subscription_name) { "#{subscriber_id}++#{SecureRandom.uuid}" }

        it 'susbcribes to the topic with headers' do
          expect(subject['type']).to eq(type)
        end
      end

      context 'When virtual topics are disabled', enable_virtual_topics: :disabled do
        let(:topic) { Faker::Lorem.word }
        let(:subscriber_id) { Faker::Lorem.word }
        let(:subscription_name) { subscriber_id }

        it 'subscribes to topic with headers and returns client' do
          expect(subject['type']).to eq(type)
        end
      end
    end

    context 'When amq is disabled', vineti_activemq_enable: :disabled do
      before do
        expect(mock_client).not_to receive(:subscribe).with("/#{type}/#{topic}", headers)
      end

      context 'When virtual topics are enabled', enable_virtual_topics: :enabled do
        let(:topic) { Faker::Lorem.word }
        let(:subscriber_id) { Faker::Lorem.word }
        let(:subscription_name) { 'subscriber' }

        it 'returns nil' do
          expect(subject).to be nil
        end
      end

      context 'When virtual topics are disabled', enable_virtual_topics: :disabled do
        let(:topic) { Faker::Lorem.word }
        let(:subscriber_id) { Faker::Lorem.word }
        let(:subscription_name) { 'subscriber' }

        it 'returns nil' do
          expect(subject).to be nil
        end
      end
    end
  end

  RSpec.shared_examples_for 'activemq config hash' do
    let(:config_hash_data) { config_hash_json('topic', subscriber_id) }

    it 'returns hash with host and client id for durable subscriber' do
      expect(subject).to eq(config_hash_data)
    end
  end

  RSpec.shared_examples_for 'activemq topic subscription and unsubscription' do
    context 'When activmq is enabled', vineti_activemq_enable: :enabled do
      before do
        expect(mock_client).to receive(:subscribe).with("/topic/#{topic}", headers)
        expect(Rails.logger).to receive(:info).with("\n---- Connecting ActiveMQ...... -----\n")
        expect(Rails.logger).to receive(:info).with("\n---- Subscribe to topic #{topic} -----\n")
        allow(mock_client).to receive(:subscribe).and_yield activemq_response(subscriber_id: subscriber_id, event_name: event_name)
        expect(Rails.logger).to receive(:info).with(logger)
      end

      let(:subscriber_id) { Faker::Lorem.word }
      let(:event_name) { Faker::Lorem.word }
      let(:headers) do
        {
          'ack' => 'client',
          'activemq.prefetchSize' => 1,
          'activemq.subscriptionName' => "#{topic}++#{SecureRandom.hex}"
        }
      end

      it 'subscribes to the topic creation' do
        expect(subject['type']).to eq('topic')
      end
    end

    context 'When activemq is disabled', vineti_activemq_enable: :disabled do
      it 'returns nil as activemq is disabled' do
        expect(subject).to be nil
      end
    end
  end

  RSpec.shared_examples_for 'activemq queue subscription service' do
    let(:response) do
      {
        body: {
          'subscriber_id': Faker::Lorem.word,
          'event_name': Faker::Lorem.word
        }.to_json
      }
    end

    context 'When activemq is enabled', vineti_activemq_enable: :enabled do
      before do
        expect(mock_client).to receive(:subscribe).with("/queue/#{queue_name}", headers)
        allow(mock_client).to receive(:subscribe).and_yield response
        expect(Vineti::Notifications::ActivemqService).to receive(:process_queue_response).with(queue_type, response, send_email)
      end

      it 'subscribes to drop queue' do
        expect(subject['type']).to eq('queue')
      end
    end

    context 'When activemq is disabed', vineti_activemq_enable: :disabled do
      before do
        expect(mock_client).not_to receive(:subscribe).with("/queue/#{queue_name}", headers)
        allow(mock_client).to receive(:subscribe).and_yield response
        expect(Vineti::Notifications::ActivemqService).not_to receive(:process_queue_response).with(queue_type, response, send_email)
      end

      it 'does not subscribe to drop queue and returns nil' do
        expect(subject).to eq nil
      end
    end
  end

  RSpec.shared_examples_for 'activemq queue response process service' do
    before do
      expect(mock_client).to receive(:publish).with("/topic/VirtualTopic.send_failed_notification", payload, publish_header)
      expect(mock_client).to receive(:close)
    end

    let(:payload) do
      {
        payload: nil,
        template_data: {
          transaction_id: response.headers['X-transaction-id'],
          subscriber_id: response.headers['X-subscriber-id'],
        },
        delayed_time: nil,
        metadata: nil
      }.to_json
    end
    let(:publish_header) do
      { 'JMSCorrelationID' => SecureRandom.hex }
    end

    it 'updates event transaction record and sends out an email' do
      expect(subject.response[:correlation_id]).to eq(SecureRandom.hex)
      event_transaction.reload
      expect(event_transaction.status).to eq(status)
      expect(event_transaction.response_code).to eq(response_code)
      expect(event_transaction.response).to eq(JSON.parse(response.body))
    end
  end
end
