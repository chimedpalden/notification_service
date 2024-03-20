require 'rails_helper'

describe Vineti::Notifications::NotificationsController, type: :controller do
  routes { Vineti::Notifications::Engine.routes }
  let(:connection_frame) { double('ConnectionFrame', command: "CONNECTED") }
  let(:stomp_connection) { double('Stomp::Client', connection_frame: connection_frame) }
  let(:enable_amq) { true }
  let(:enable_virtual_topics) { true }
  let(:uuid) { 'abcd_1234' }
  let(:transaction_id) { "Dummy_#{uuid}" }

  let!(:event) { FactoryBot.create(:event) }
  let!(:template) { FactoryBot.create(:notification_template) }
  let!(:webhook_subscriber) { FactoryBot.create(:webhook_subscriber, template: template) }
  let!(:email_subscriber) { FactoryBot.create(:email_subscriber, template: template) }

  before(:each) do
    FactoryBot.create(:event_subscriber, event: event, subscriber: webhook_subscriber)
    FactoryBot.create(:event_subscriber, event: event, subscriber: email_subscriber)

    allow(Stomp::Client).to receive(:new).and_return(stomp_connection)
    allow(SecureRandom).to receive(:hex).and_return('abcd1234')
    allow(SecureRandom).to receive(:uuid).and_return('abcd_1234')
    allow_any_instance_of(Vineti::Notifications::AuthHelper).to receive(:validate_user_permissions).and_return(true)
    allow(ENV).to receive(:fetch).with('VINETI_ACTIVEMQ_ENABLE', 'false').and_return(enable_amq)
    allow(ENV).to receive(:fetch).with('enable_virtual_topics', 'false').and_return(enable_virtual_topics)
  end

  describe '#send_notifications' do
    context 'When user is logged in and auth tokens are present in header' do
      subject { post :send_notifications, params: { notifications: params } }

      before do
        api_sign_in(user, request)
        allow(::EventServiceClient::Publish).to receive(:to_virtual_topic).and_return(result)
      end

      let(:user) { FactoryBot.create(:system_user) }
      let(:result) do
        {
          message: "Published to topic #{event.name}",
          success: success,
          transaction_id: transaction_id
        }
      end

      let(:success) { true }
      let(:params) do
        {
          template_data: { variable: 'variable value' },
          payload: {
            events: [
              data_changes: {
                first_param: 'first_param_value',
                headers: { first_header: :first_header_value },
                webhook_url: 'www.testurl.com',
              },
              performed_by: "nina@vineti.com",
              event_name: event.name,
              event_date: "2019-12-01T00:00:00+00:00",
              resource_type: "order",
            ],
          },
        }
      end

      let(:event_data) do
        {
          payload: params[:payload],
          template_data: params[:template_data],
          delayed_time: params[:delayed_time],
          metadata: nil,
          parent_transaction_id: @parent_transaction.id,
        }
      end

      it_behaves_like 'notification controller send notification'
    end

    context 'When user is not logged-in' do
      subject { post :send_notifications }

      let(:errors) { { 'errors' => ['You need to sign in or sign up before continuing.'] } }

      it 'Returns 401 error' do
        subject
        expect(JSON.parse(response.body)).to eq(errors)
      end
    end
  end
end
