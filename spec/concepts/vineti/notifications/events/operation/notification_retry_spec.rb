require 'rails_helper'

module Vineti::Notifications
  describe Events::Operation::NotificationRetry do
    subject do
      Events::Operation::NotificationRetry.call(
        params: ActionController::Parameters.new(retry_params)
      )
    end

    let(:user) { FactoryBot.create(:system_user) }

    let(:event) { FactoryBot.create(:event) }
    let!(:event_transaction) { FactoryBot.create(:event_transaction, :with_event, event: event, status: "ERROR") }
    let(:mock_service) { double('activemq_service') }
    let(:json_file_name) { 'inbound-amq-response.json' }
    let(:amq_response_template) { File.read(Rails.root.join('..', '..', 'spec', 'fixtures', 'files', json_file_name)) }
    let(:stomp_message) { double('Stomp::Message', body: @amq_response_body) }
    let(:retry_params) do
      {
        "transaction_id": event_transaction.transaction_id
      }
    end
    let!(:publisher) { FactoryBot.create(:publisher) }
    let!(:publisher_subscriber) { FactoryBot.create(:publisher_subscriber, publisher: publisher) }
    let(:subscriber_id) { Vineti::Notifications::Subscriber.internal_api_subscriber_id(event.name) }
    let(:amq_response_body_data) do
      {
        uid: user.uid,
        transaction_id: event_transaction.transaction_id,
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

    describe '#fetch_transaction' do
      context 'when transaction is not present' do
        let(:retry_params) do
          {
            "transaction_id": nil
          }
        end

        it 'returns 422 status' do
          expect(subject[:status]).to eq(422)
          expect(subject[:errors]).to include(transaction: "Transaction not found")
        end
      end

      context 'when event is not present' do
        let!(:event_transaction) { FactoryBot.create(:event_transaction, status: "ERROR") }
        let(:retry_params) do
          {
            "transaction_id": event_transaction.transaction_id
          }
        end

        it 'returns 422 status' do
          expect(subject[:status]).to eq(422)
          expect(subject[:errors]).to include(event: 'Event not found')
        end
      end
    end

    describe '#when transaction is not a failed transaction' do
      let!(:event_transaction) { FactoryBot.create(:event_transaction, :with_event, status: "SUCCESS") }
      let(:retry_params) do
        {
          "transaction_id": event_transaction.transaction_id
        }
      end

      it 'returns 422 status' do
        expect(subject[:status]).to eq(422)
        expect(subject[:errors]).to include(transaction: "Transaction does not have a failed status")
      end
    end

    context 'Publishing data to activemq' do
      context 'When error occurs while publishing' do
        before do
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
        let!(:child_transaction) { FactoryBot.create(:event_transaction, :with_event, transaction_id: SecureRandom.uuid, parent_transaction_id: event_transaction.id, status: "ERROR") }
        let(:retry_params) do
          {
            "transaction_id": child_transaction.transaction_id
          }
        end
        it 'returns success does not create a new event transaction' do
          expect(subject.success?).to be true
          expect(subject[:result]).to eq(success_result)
          expect { subject }.not_to change(Vineti::Notifications::EventTransaction, :count)
        end
      end

      context 'When feature flag for activemq is not enabled' do
        before do
          allow(mock_service).to receive(:publish_to_virtual_topic).and_return(error_result)
        end

        it 'returns response' do
          expect(subject.success?).to be false
          expect(subject[:result]).to be nil
        end
      end
    end
  end
end
