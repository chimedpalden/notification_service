# frozen_string_literal: true

require 'rails_helper'

describe Vineti::Notifications::Subscriber::WebhookService do
  before(:each) do
    allow(Wso2).to receive(:new).and_return(wso2)
    # allow(SecureRandom).to receive(:uuid).and_return(transaction_id)
    allow_any_instance_of(::OAuth2::Client)
      .to receive_message_chain(:client_credentials, :get_token, :headers)
      .and_return(oauth_token)
    allow_any_instance_of(::Event::WebhookNotificationSent).to receive(:record).and_return(true)
    allow(wso2).to receive(:wso2_service_url).and_return('foo.com/bar.com/api/orderevent')
    allow(wso2).to receive(:wso_service_http_method).and_return('post')
    allow(wso2).to receive(:oauth_token).and_return(oauth_token)
  end

  let!(:event) { Vineti::Notifications::Event.find_or_create_by(name: 'order_confirmed') }

  let!(:subscriber) do
    Vineti::Notifications::Subscriber::WebhookSubscriber.create_with(
      subscriber_id: 'order_confirmed_developer_group',
      data: {
        payload: { first_param: :first_param_value },
        headers: { first_header: :first_header_value },
        webhook_url: 'www.testurl.com',
        'vault_key' => 'jnj_client_id_01'
      }
    ).find_or_create_by(subscriber_id: 'order_confirmed_developer_group')
  end

  let(:wso2) { double }
  # let(:transaction_id) { 'xxxabcd1234' }
  let(:parent_transaction) { FactoryBot.create(:event_transaction) }
  let(:oauth_token) do
    {
      "Authorization" => "Bearer 5a48706e-c3e1-9d18-f254b46aaadf",
    }
  end

  let(:payload) do
    {
      events: [
        data_changes: {
          "COI": "DRE2233JK",
          "FIRST_NAME": "JOHN",
          "LAST_NAME": "COO",
        },
        resource_type: "order",
        performed_by: "nina@vineti.com",
        event_name: event.name,
      ],
    }
  end

  let(:headers) do
    {
      "Authorization" => oauth_token['Authorization'],
      "Content-Type" => "application/json",
      "X-Authorization-Event" => "Bearer abc123",
      "X-callback-url" => "",
      "X-subscriber-id" => subscriber.subscriber_id,
      "X-target-url" => subscriber.data['webhook_url'],
      "X-transaction-id" => transaction_id,
    }
  end
  let(:metadata) do
    {
      treatment_id: 1,
      procedure_status: 'Confirmation',
      procedure_name: 'ordering',
      step_name: 'consent',
      order_status: 'Shipping',
      subscriber_id: 'subscriber_1',
      event_name: event.name,
    }
  end

  let(:params) do
    {
      topic: event,
      payload: payload,
      subscriber: subscriber,
      metadata: metadata,
      parent_transaction_id: parent_transaction.id,
    }
  end

  let!(:webhook) do
    Vineti::Notifications::EventSubscriber.find_or_create_by!(event: event, subscriber: subscriber)

    Vineti::Notifications::Subscriber::WebhookService.new(params)
  end

  context 'When params are valid' do
    describe '#initialize' do
      it 'send correct payload to wso server' do
        expect(webhook.payload).to eq(payload.with_indifferent_access)
      end
    end

    describe '#send_notification' do
      subject { webhook.send_notification }

      before do
        allow(RestClient::Request)
          .to receive(:execute)
          .and_return(Struct.new(:body, :code).new({ success: true }, 200))
      end

      it 'creates a new transaction record' do
        expect { subject }.to change(Vineti::Notifications::EventTransaction, :count).by(1)
      end

      it 'updates transaction status' do
        subject
        event_transaction = Vineti::Notifications::EventTransaction.find_by(vineti_notifications_subscribers_id: subscriber.id)
        expect(event_transaction.reload.status).to eq("WSO_SUCCESS")
      end

      it 'sends the correct basic headers to wso2' do
        expect_any_instance_of(Vineti::Notifications::Subscriber::WebhookService).to receive(:basic_outbound_headers)
        subject
      end

      context 'When valid metadata is provided' do
        it 'records webhook notification sent event' do
          expect(::Event::WebhookNotificationSent).to receive(:record)
          subject
        end
      end

      context 'When metadata is missing required keys' do
        let(:metadata) do
          {
            treatment_id: 1,
            procedure_status: 'Confirmation',
            step_name: 'Ordering',
            event_name: event.name,
          }
        end

        it 'does not records webhook notification sent event' do
          expect(::Event::WebhookNotificationSent).not_to receive(:record)
          subject
        end
      end
    end
  end

  context 'When webhook doesnt responds with status :OK' do
    describe '#send_notification' do
      subject { webhook.send_notification }

      before do
        allow(RestClient::Request)
          .to receive(:execute)
          .and_raise(RestClient::ExceptionWithResponse)
      end

      let(:webhook) { Vineti::Notifications::Subscriber::WebhookService.new(params) }

      it 'Returns error details' do
        expect(subject.error.message).to eq('RestClient::ExceptionWithResponse')
      end

      it 'updates transaction status' do
        subject
        event_transaction = Vineti::Notifications::EventTransaction.find_by(vineti_notifications_subscribers_id: subscriber.id)
        expect(event_transaction.reload.status).to eq("WSO_ERROR")
      end
    end
  end

  context 'When different headers are expected for WSO2' do
    describe "Headers for Oauth" do
      let(:subscriber) do
        Vineti::Notifications::Subscriber::WebhookSubscriber.create_with(
          subscriber_id: 'order_confirmed_developer_group_1',
          data: {
            payload: { first_param: :first_param_value },
            headers: { first_header: :first_header_value },
            webhook_url: 'www.testurl.com',
            token_url: 'abc123',
            vault_key: 'ck-1232233'
          }
        ).find_or_create_by(subscriber_id: 'order_confirmed_developer_group_1')
      end

      let(:webhook) { Vineti::Notifications::Subscriber::WebhookService.new(params) }

      subject { webhook.send_notification }

      it 'has the correct headers' do
        expect_any_instance_of(Vineti::Notifications::Subscriber::WebhookService).to receive(:oauth_outbound_headers)
        subject
      end
    end
  end
end
