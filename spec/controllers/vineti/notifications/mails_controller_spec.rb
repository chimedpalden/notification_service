require 'rails_helper'

describe Vineti::Notifications::MailsController, type: :controller do
  routes { Vineti::Notifications::Engine.routes }

  before do
    template = Vineti::Notifications::Template.find_by(template_id: 'Template Name')
    if template.nil?
      Vineti::Notifications::Template.create!(
        template_id: 'Template Name',
        data: {
          'subject' => 'Subject',
          'text_body' => 'text',
          'html_body' => '<h1>Header</h1>',
        }
      )
    end
    allow_any_instance_of(Vineti::Notifications::AuthHelper).to receive(:validate_user_permissions).and_return(true)
    allow_any_instance_of(Aws::SES::Client).to receive(:send_email).and_return(Seahorse::Client::Response.new(data: mail_response))
    allow_any_instance_of(Seahorse::Client::Response).to receive(:successful?).and_return(true)

    allow(Vineti::Notifications::UserRoleProcessor).to receive(:fetch_users_from_role).and_return(
      'from_address' => 'morty@birdman.com',
      'to_addresses' => ['rick.sanchez@plumbus.com']
    )
  end

  let(:message_id) { 'message-123-id-456-for-789-mail' }
  let(:event) { FactoryBot.create(:event) }
  let(:email_subscriber) { FactoryBot.create(:email_subscriber) }
  let(:mail_response) { Ses.new.client.stub_data(:send_email, message_id: message_id) }

  describe '#send_notification_mail' do
    subject { post :send_event_notification, params: params }

    context 'When user is logged in correct role and auth tokens are present in header' do
      before do
        api_sign_in user, request
        event.subscribers << email_subscriber
      end

      let(:user) { FactoryBot.create(:system_user) }
      let(:response_body) { JSON.parse(response.body) }
      let(:error_message) { response_body['error'] }
      let(:message_id_from_response) { response_body['data'].first['attributes']['message_id'] }

      context 'When event is not present' do
        let(:params) { { mail: { event_name: 'order_created', template_data: {} } } }

        it 'Raises error' do
          subject
          expect(response_body.keys).to match(%w[status error])
          expect(error_message).to eq("Couldn't find Vineti::Notifications::Event")
        end
      end

      context 'When delayed time is not passed in params' do
        let(:params) do
          {
            mail: {
              event_name: event.name,
              template_data: { variable_1: '' },
            },
          }
        end

        it 'Sends out notifications and return success response' do
          subject
          expect(message_id_from_response).to eq(message_id)
        end
      end

      context 'When delayed time is passed in params' do
        let(:params) do
          {
            mail: {
              event_name: event.name,
              template_data: { variable_1: '' },
              delayed_time: '5',
            },
          }
        end

        it 'Schedules job and return job response' do
          subject
          expect(message_id_from_response).to be nil
          expect(response.status).to eq(200)
        end
      end
    end

    context 'When user is not logged in and auth tokens are missing from header' do
      let(:error) { { 'errors' => ['You need to sign in or sign up before continuing.'] } }
      let(:params) { { mail: { event_name: event.name } } }

      it 'Returns 401 error' do
        subject
        expect(JSON.parse(response.body)).to eq(error)
      end
    end
  end
end
