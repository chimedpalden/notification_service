require 'rails_helper'

module Orchestrator
  module Operation
    class Orchestrate
      def self.call(params:, current_user:)
        { status: 200 }
      end
    end
  end
end

module Vineti::Notifications
  describe Inbound::Operation::Create do
    subject do
      Inbound::Operation::Create.call(
        params: ActionController::Parameters.new(params),
        publisher_token: publisher_token,
        current_user: user
      )
    end

    let(:user) { FactoryBot.create(:system_user) }
    let(:publisher_token) { publisher.data['token'] }
    let(:event) { FactoryBot.create(:event) }
    let!(:publisher) { FactoryBot.create(:publisher) }
    let(:mock_service) { double('activemq_service') }
    let(:json_file_name) { 'inbound-amq-response.json' }
    let(:amq_response_template) { File.read(Rails.root.join('..', '..', 'spec', 'fixtures', 'files', json_file_name)) }
    let(:stomp_message) { double('Stomp::Message', body: JSON.parse(@amq_response_body), headers: amq_response_header) }
    let(:process_params) do
      {
        event_name: event.name,
        orchestrator: { a: 'b' }.with_indifferent_access,
      }
    end
    let(:params) { process_params }
    let!(:event_transaction) { FactoryBot.create(:event_transaction) }
    let!(:publisher_subscriber) { FactoryBot.create(:publisher_subscriber, publisher: publisher) }
    let(:subscriber_id) { Vineti::Notifications::Subscriber.internal_api_subscriber_id(event.name) }
    let(:amq_response_header) do
      {
        'X-transaction-id' => event_transaction.transaction_id
      }
    end
    let(:amq_response_body_data) do
      {
        uid: user.uid,
        publisher_id: publisher.publisher_id,
      }.with_indifferent_access
    end
    let(:success_result) do
      {
        message: "Published to virtual topic",
        success: true,
        transaction_id: SecureRandom.hex
      }
    end

    let(:error_result) do
      {
        success: false,
        transaction_id: SecureRandom.hex,
        error: "Failed to Publish to topic #{event.name}"
      }
    end
    before do
      allow(::EventServiceClient::Adapters::Activemq).to receive(:new).and_return(mock_service)
      allow(::EventServiceClient::Publish).to receive(:to_topic)
      allow(mock_service).to receive(:publish_to_virtual_topic).and_return(success_result)
      allow(mock_service).to receive(:create_client)
      allow(mock_service).to receive(:subscribe_to_virtual_topic) do |_instance, _subscriber_id, &handler|
        handler.call(stomp_message)
      end
      allow(mock_service).to receive(:subscribe_to_topic) do |_instance, _subscriber_id, &handler|
        handler.call(stomp_message)
      end

      event.publishers << publisher
      renderer = Vineti::Templates::Render.factory(amq_response_template)
      @amq_response_body = renderer.call!(amq_response_body_data)

      allow_any_instance_of(Vineti::Notifications::Subscriber::EmailService).to receive(:send_notification_to_subscriber).and_return(true)
      allow_any_instance_of(Vineti::Notifications::Subscriber::WebhookService).to receive(:send_notification).and_return(true)
    end

    after do
      ::EventServiceClient::ClientPool.class_variable_set("@@clients", nil)
    end

    context 'when params are valid and no internal server issue happens' do
      it 'returns 200' do
        expect(subject[:status]).to eq(200)
      end
    end

    describe '#validate_params' do
      context 'when event_name params is missing' do
        let(:params) { process_params.except(:event_name) }

        it 'results in failure' do
          expect(subject.success?).to eq(false)
          expect(subject[:errors]).to include(event_name: "parameter is required")
        end
      end

      context 'when publisher token params is missing' do
        let(:publisher_token) { nil }

        it 'results in failure' do
          expect(subject.success?).to eq(false)
          expect(subject[:errors]).to include(publisher_token: "header is required")
        end
      end

      context 'when orchestrator params is missing' do
        let(:params) { process_params.except(:orchestrator) }

        it 'results in failure' do
          expect(subject.success?).to eq(false)
          expect(subject[:errors]).to include(orchestrator: "parameter is required")
        end
      end

      context 'when publisher does not exist' do
        let(:publisher_token) { SecureRandom.hex }

        it 'results in failure' do
          expect(subject.success?).to eq(false)
          expect(subject[:errors]).to include(publisher: 'Publisher not found')
        end
      end

      context 'when event does not exist' do
        before { event.publishers = [] }

        it 'results in failure' do
          expect(subject.success?).to eq(false)
          expect(subject[:errors]).to include(event: "#{event.name} Event not found")
        end
      end
    end

    describe '#fetch_publisher_subscriber' do
      context 'when internalApi subscriber is not present' do
        it 'creates the subscriber for the publisher' do
          expect { subject }.to change(Vineti::Notifications::Subscriber::InternalApiSubscriber, :count).by(1)
          new_subscriber = Vineti::Notifications::Subscriber::InternalApiSubscriber.find_by(subscriber_id: subscriber_id)
          expect(new_subscriber).to be_present
          expect(new_subscriber.events).to include(event)
        end

        it 'and subscriber to the amq topic' do
          expect(::EventServiceClient::Publish).to receive(:to_topic).with('topic_subscription', anything)
          subject
        end

        context 'when amq throws an error' do
          before do
            allow(::EventServiceClient::Publish).to receive(:to_topic)
              .with('topic_subscription', anything)
              .and_raise('AMQ Error')
          end

          it 'returns 500 status' do
            expect(subject[:status]).to eq(500)
            expect(subject[:errors]).to include("AMQ Error")
          end
        end
      end

      context 'when event_subscriber is not present' do
        let!(:subscriber) { FactoryBot.create(:internal_api_subscriber, subscriber_id: subscriber_id) }

        it 'creates the event subscriber' do
          event_subscriber = Vineti::Notifications::EventSubscriber.find_by(
            vineti_notifications_events_id: event.id,
            vineti_notifications_subscribers_id: subscriber.id
          )
          expect(event_subscriber).not_to be_present
          expect { subject }.to change(Vineti::Notifications::EventSubscriber, :count).by(1)
          expect(subscriber.events.reload).to include(event)
        end

        it 'and subscriber to the amq topic' do
          expect(::EventServiceClient::Publish).to receive(:to_topic).with('topic_subscription', anything)
          subject
        end

        context 'when amq throws an error' do
          before do
            allow(::EventServiceClient::Publish).to receive(:to_topic)
              .with('topic_subscription', anything)
              .and_raise('AMQ Error')
          end

          it 'returns 500 status' do
            expect(subject[:status]).to eq(500)
            expect(subject[:errors]).to include("AMQ Error")
          end
        end
      end
    end

    describe '#fetch_and_parse_template' do
      context 'when params is valid' do
        it 'results in success' do
          expect(subject.success?).to eq(true)
        end
      end

      context 'when ParseTemplate throws errors' do
        let(:parse_result) { double }

        before do
          allow(Inbound::Operation::ParseTemplate).to receive(:call).and_return(parse_result)
          allow(parse_result).to receive(:success?).and_return(false)
          allow(parse_result).to receive(:[]).with(:errors).and_return(["error message"])
        end

        it 'return 500' do
          expect(subject[:status]).to eq(500)
          expect(subject[:errors]).to include("error message")
        end
      end
    end

    describe '#persist_event_transaction_with_publisher' do
      it 'creates an event transaction with CREATE status' do
        expect { subject }.to change(Vineti::Notifications::EventTransaction, :count).by(1)
        expect(Vineti::Notifications::EventTransaction.last.status).to eq("SUCCESS")
        expect(Vineti::Notifications::EventTransaction.last.payload.symbolize_keys).to eq(params)
      end
    end

    context 'Publishing data to activemq' do
      context 'When error occurs while publishing' do
        before do
          allow(mock_service).to receive(:publish_to_virtual_topic).and_return(success_result)
          allow(mock_service).to receive(:publish_to_virtual_topic).and_return(error_result)
          allow(mock_service).to receive(:create_client)
        end

        it 'returns error with response' do
          expect(subject.success?).to be false
          expect(subject[:status]).to eq(500)
          expect(subject[:errors]).to eq(["Failed to Publish to topic #{event.name}"])
        end
      end

      context 'When publishing is successful' do
        it 'returns success' do
          expect(subject.success?).to be true
          expect(subject[:message_id]).to eq(success_result)
        end
      end

      context 'When feature flag for activemq is not enabled' do
        before do
          allow(mock_service).to receive(:publish_to_virtual_topic).and_return(error_result)
        end

        it 'returns response' do
          expect(subject.success?).to be false
          expect(subject[:message_id]).to be nil
        end
      end
    end
  end
end
