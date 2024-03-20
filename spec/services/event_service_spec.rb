require 'rails_helper'

describe EventService do
  before do
    allow_any_instance_of(::Vineti::Notifications::EventSubscriber).to receive(:amq_seed)
    FactoryBot.create(:event_subscriber, event: event, subscriber: webhook_subscriber)
    FactoryBot.create(:event_subscriber, event: event, subscriber: email_subscriber)
    allow(Stomp::Client).to receive(:new).and_return(stomp_connection)
    allow(SecureRandom).to receive(:hex).and_return('abcd1234')
    allow(ENV).to receive(:fetch).with('VINETI_ACTIVEMQ_ENABLE', 'false').and_return(enable_amq)
    allow(ENV).to receive(:fetch).with('enable_virtual_topics', 'false').and_return(enable_virtual_topics)
  end

  let!(:event) { FactoryBot.create(:event) }
  let!(:template) { FactoryBot.create(:notification_template) }
  let!(:webhook_subscriber) { FactoryBot.create(:webhook_subscriber) }
  let!(:email_subscriber) { FactoryBot.create(:email_subscriber) }

  let(:event_name) { event.name }
  let(:enable_virtual_topics) { true }
  let(:enable_amq) { true }
  let(:data_changes) do
    {
      "patient": {
        "patient_middle_name": "Devin",
        "patient_custom_field": "def",
        "email": "bobd@gmail.com",
        "initials": "BDL",
      },
    }
  end
  let(:event_params) do
    {
      event_name: event_name,
      event_date: "2019-12-01T00:00:00+00:00",
      resource_id: "1234",
      resource_type: "order",
    }
  end
  let(:metadata) do
    {
      procedure_name: 'Ordering',
      procedure_step_name: 'patient',
      treatment_id: 1,
      correlation_id: transaction_id,
      transaction_id: transaction_id
    }
  end
  let(:connection_frame) { double('ConnectionFrame', command: "CONNECTED") }
  let(:stomp_connection) { double('Stomp::Client', connection_frame: connection_frame) }
  let(:uuid) { 'abcd_1234' }
  let(:transaction_id) { "Dummy_#{uuid}" }
  let(:event_service) { EventService.new(params) }
  let(:params) do
    {
      payload: {
        events: [
          event_params,
          data_changes: data_changes,
        ],
      },
      metadata: metadata,
    }
  end

  describe '#initialize' do
    let(:event_service) do
      EventService.new(params)
    end

    it 'Creates object with params data' do
      expect(event_service.event_name).to eq(event.name)
      expect(event_service.payload).to eq(
        events: [
          {
            event_name: event.name,
            event_date: "2019-12-01T00:00:00+00:00",
            resource_id: "1234",
            resource_type: "order",
          },
          data_changes: {
            "patient": {
              "patient_middle_name": "Devin",
              "patient_custom_field": "def",
              "email": "bobd@gmail.com",
              "initials": "BDL",
            },
          },
        ]
      )
    end
  end

  describe '#notify_subscribers', :feature do
    subject { event_service.notify_subscribers }

    before(:each) do
      @parent_transaction = FactoryBot.create(:event_transaction, transaction_id: SecureRandom.uuid)
      allow_any_instance_of(described_class).to receive(:persist_event_notification_transaction).and_return(@parent_transaction)
      allow(SecureRandom).to receive(:uuid).and_return('abcd_1234')
      allow(::EventServiceClient::Publish).to receive(:to_virtual_topic).and_return(result)
    end

    let(:event_data) do
      {
        payload: params[:payload],
        template_data: params[:template_data],
        delayed_time: params[:delayed_time],
        metadata: params[:metadata],
        parent_transaction_id: @parent_transaction.id,
      }
    end

    let(:result) do
      {
        message: "Published to topic",
        success: success,
        transaction_id: SecureRandom.hex
      }
    end

    let(:success) { true }

    context 'when the subscriber is webhook type' do
      it_behaves_like 'event service publish'
    end

    context 'when the subscriber is email type' do
      let(:params) do
        {
          payload: {
            events: [
              event_params,
              data_changes: data_changes,
            ],
          },
          template_data: {},
          delayed_time: 5,
          metadata: {
            correlation_id: transaction_id,
            transaction_id: transaction_id
          },
        }
      end

      it_behaves_like 'event service publish'
    end
  end

  describe 'Publish Retry' do
    subject { EventService }
    it 'should call the publish retry operation' do
      allow(Vineti::Notifications::Events::Operation::PublishRetry).to receive(:call).and_return(true)
      expect(Vineti::Notifications::Events::Operation::PublishRetry).to receive(:call)
      subject.republish_failed_events
    end
  end
end
