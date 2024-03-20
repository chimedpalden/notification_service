require 'rails_helper'
require 'stomp'

class UserRole end

module Vineti::Notifications
  RSpec.describe SubscribersController, type: :controller do
    routes { Vineti::Notifications::Engine.routes }

    before do
      allow_any_instance_of(Vineti::Notifications::AuthHelper).to receive(:validate_user_permissions).and_return(true)
    end

    let(:email_data) { %w[from_address to_addresses cc_addresses] }

    let(:webhook_data) { %w[webhook_url vault_key token_url] }

    let(:response_attributes) { %w[subscriber_id data type active delayed_time events template] }

    context 'When user is logged in and auth tokens are present in header' do
      before do
        api_sign_in(user, request)
      end

      let(:user) { FactoryBot.create(:system_user) }

      describe 'GET#index' do
        subject { get :index }

        before(:each) do
          FactoryBot.create(:email_subscriber)
          FactoryBot.create(:webhook_subscriber)
        end

        it 'returns all types of subscribers' do
          response = JSON.parse(subject.body)
          expect(response['data'].count).to eq(2)
        end

        it 'contains all required attributes' do
          response = JSON.parse(subject.body)
          expect(response['data'].first['attributes'].keys).to match(response_attributes)
          expect(response['data'].last['attributes'].keys).to match(response_attributes)
        end

        it 'contains correct data for email subscribers' do
          response = JSON.parse(subject.body)
          subscriber = response['data'].select { |x| x['attributes']['type'] == "Vineti::Notifications::Subscriber::EmailSubscriber" }
          expect(subscriber.first['attributes']["data"].keys).to match(email_data)
        end

        it 'contains correct data for webhook subscribers' do
          response = JSON.parse(subject.body)
          subscriber = response['data'].select { |x| x['attributes']["type"] == "Vineti::Notifications::Subscriber::WebhookSubscriber" }
          expect(subscriber.first['attributes']["data"].keys).to match(webhook_data)
        end
      end

      describe 'GET#show' do
        subject { get :show, params: { subscriber_id: subscriber_id } }

        before(:each) do
          FactoryBot.create(:email_subscriber)
          FactoryBot.create(:webhook_subscriber)
        end

        context 'When subscriber with id in params is present' do
          context 'when subscriber is an email type' do
            let(:subscriber_id) { FactoryBot.create(:email_subscriber).subscriber_id }

            it 'returns the subscriber with passed subscriber_id' do
              response = JSON.parse(subject.body)

              expect(response['data']['attributes']['subscriber_id']).to eq(subscriber_id)
              expect(response['data']['attributes'].keys).to match(response_attributes)
              expect(response['data']['attributes']["data"].keys).to match(email_data)
            end
          end

          context 'when subscriber is an webhook type' do
            let(:subscriber_id) { FactoryBot.create(:webhook_subscriber).subscriber_id }

            it 'returns the subscriber with passed subscriber_id' do
              response = JSON.parse(subject.body)
              expect(response['data']['attributes']['subscriber_id']).to eq(subscriber_id)
              expect(response['data']['attributes'].keys).to match(response_attributes)
              expect(response['data']['attributes']["data"].keys).to match(webhook_data)
            end
          end
        end

        context 'When subscriber is not present' do
          let(:subscriber_id) { SecureRandom.hex(16) }

          it 'returns status 404' do
            subject
            expect(response.status).to eq(404)
          end
        end
      end

      describe 'POST#create' do
        subject { post :create, params: params }

        before(:each) do
          allow(UserRole).to receive_message_chain(:where, :blank?).and_return(false)
          allow(active_mq).to receive(:publish_to_topic).with(activemq_topic_data).and_return(true)
        end

        let(:template) { FactoryBot.create(:notification_template) }
        let(:event) { FactoryBot.create(:event) }
        let(:subscriber_id) { 'order_shipped_email' }
        let(:active_mq) { double("active_mq") }
        let(:activemq_topic_data) do
          {
            event_name: event.name,
            subscriber_id: subscriber_id,
            email_subscriber: email_subscriber
          }
        end
        let(:email_subscriber) { true }

        context 'When valid params are passed' do
          let(:params) do
            {
              subscriber: {
                type: 'email',
                subscriber_id: subscriber_id,
                template_id: template.template_id,
                event_names: [event.name],
                active: true,
                data: {
                  from_address: 'no-reply@vineti.com',
                  to_addresses: ['test@vineti.com'],
                },
              },
            }
          end

          it 'Creates a record and returns a json response' do
            expect { subject }.to change(Vineti::Notifications::Subscriber, :count).by(1)
            response = JSON.parse subject.body
            attributes = response['data']['attributes']

            expect(attributes['subscriber_id']).to eq(params[:subscriber][:subscriber_id])
            expect(attributes['template']['template_id']).to eq(template.template_id)
          end

          it 'Creates topic and subscriber in ActiveMq' do
            subject
            allow(active_mq).to receive(:subscribe_to_topic).with(event.name, event.name).and_return(true)
          end
        end

        context 'When roles are passed in email address config' do
          let(:params) do
            {
              subscriber: {
                type: 'email',
                subscriber_id: 'order_shipped_email',
                template_id: template.template_id,
                event_names: [event.name],
                active: true,
                data: email_list_with_roles,
              },
            }
          end

          let(:email_list_with_roles) do
            {
              "from_address" => 'from@vineti.com',
              "to_addresses" => ['developers@vineti.com'],
              "cc_addresses" => ['case_manager'],
            }
          end

          context 'when valid roles are passed' do
            it 'persists the roles along with emails in database' do
              response = JSON.parse subject.body
              attributes = response['data']['attributes']
              expect(attributes['data']).to eq(email_list_with_roles)
            end
          end

          context 'when invalid roles are passed' do
            before do
              allow(UserRole).to receive_message_chain(:where, :blank?).and_return(true)
            end

            it 'persists the roles along with emails in database' do
              response = JSON.parse subject.body
              expect(response['error']).to eq('Validation failed: Data case_manager in cc_addresses is neither a valid email address nor a valid user role')
            end
          end
        end

        context 'When referrence to template is missing' do
          context 'when type is webhook' do
            let(:params) do
              {
                subscriber: {
                  type: 'webhook',
                  subscriber_id: subscriber_id,
                  event_names: [event.name],
                  active: true,
                  data: {
                    webhook_url: 'www.example.com',
                    'token_url' => 'https://externalsystem/token',
                    'vault_key' => 'jnj_client_id_01',
                  },
                },
              }
            end
            let(:email_subscriber) { false }

            it 'returns status 200' do
              expect { subject }.to change(Vineti::Notifications::Subscriber, :count).by(1)
              expect(response.status).to eq(200)
            end

            it 'Creates topic and subscriber in ActiveMq' do
              subject
              allow(active_mq).to receive(:subscribe_to_topic).with(event.name, event.name).and_return(true)
            end
          end

          context 'when type is email' do
            let(:params) do
              {
                subscriber: {
                  type: 'email',
                  subscriber_id: 'order_shipped_email',
                  event_names: [event.name],
                  active: true,
                  data: {
                    from_address: 'no-reply@vineti.com',
                    to_addresses: ['test@vineti.com'],
                  },
                },
              }
            end

            it 'returns status 400' do
              expect { subject }.not_to change(Vineti::Notifications::Subscriber, :count)
              expect(response.status).to eq(400)
            end

            it 'does not creates topics in ActiveMq' do
              subject
              expect(active_mq).not_to receive(:subscribe_to_topic).with(event.name, event.name)
            end
          end
        end

        context 'when the type is not valid' do
          let(:params) do
            {
              subscriber: {
                type: 'abc',
                subscriber_id: subscriber_id,
                template_id: template.template_id,
                event_names: [event.name],
                active: true,
                data: {
                  from_address: 'no-reply@vineti.com',
                  to_addresses: ['test@vineti.com'],
                },
              },
            }
          end

          it 'returns status 400' do
            expect { subject }.not_to change(Vineti::Notifications::Subscriber, :count)
            expect(response.status).to eq(400)
          end

          it 'does not creates topics in ActiveMq' do
            subject
            expect(active_mq).not_to receive(:subscribe_to_topic).with(event.name, event.name)
          end
        end

        context 'when event_names params is incorrect' do
          context 'when the event_names is not passed as an array' do
            let(:params) do
              {
                subscriber: {
                  type: 'email',
                  subscriber_id: subscriber_id,
                  template_id: template.template_id,
                  event_names: event.name,
                  active: true,
                  data: {
                    from_address: 'no-reply@vineti.com',
                    to_addresses: ['test@vineti.com'],
                  },
                },
              }
            end

            it 'raises error' do
              expect { subject }.to raise_error(NoMethodError)
            end
          end

          context 'when the event name does not exist in the database' do
            let(:params) do
              {
                subscriber: {
                  type: 'email',
                  subscriber_id: 'order_shipped_email',
                  template_id: template.template_id,
                  event_names: [event.name, 'random_event'],
                  active: true,
                  data: {
                    from_address: 'no-reply@vineti.com',
                    to_addresses: ['test@vineti.com'],
                  },
                },
              }
            end

            let(:error_message) do
              "Event with name random_event is not present. Please use 'GET /events_list' to find out all events that can be used"
            end

            it 'returns status 404' do
              expect { subject }.not_to change(Vineti::Notifications::Subscriber, :count)
              expect(subject.response_code).to eq(404)
              expect(JSON.parse(response.body)['error']).to eq(error_message)
            end

            it 'does not creates topics in ActiveMq' do
              subject
              expect(active_mq).not_to receive(:subscribe_to_topic).with(event.name, event.name)
            end
          end
        end
      end

      describe 'DELETE#destroy' do
        subject { delete :destroy, params: { subscriber_id: subscriber_id } }

        before(:each) do
          allow(mock_client).to receive(:publish_to_topic).and_return true
        end

        let(:connection_frame) { double('ConnectionFrame', command: "CONNECTED", headers: { message: "" }) }
        let(:mock_client) { double('Stomp::Client', connection_frame: connection_frame) }

        context 'When subscriber with is present' do
          let(:subscriber_id) { FactoryBot.create(:email_subscriber).subscriber_id }

          before do
            allow_any_instance_of(Vineti::Notifications::SubscribersController).to receive(:delete_activemq_subscriptions).and_return({})
          end

          it 'Deletes the susbcriber and returns json response' do
            response = JSON.parse subject.body
            expect(response['data']['attributes'].keys).to match(response_attributes)
          end
        end

        context 'When subscriber with event is not present' do
          let(:subscriber_id) { SecureRandom.hex(16) }

          it 'returns status 404' do
            subject
            expect(response.status).to eq(404)
          end
        end
      end
    end

    context 'When user is not logged in' do
      let(:errors) { { 'errors' => ['You need to sign in or sign up before continuing.'] } }
      let(:subscriber) { FactoryBot.create(:webhook_subscriber) }

      describe 'GET#index' do
        subject { get :index }

        it 'Returns 401 error' do
          subject
          expect(JSON.parse(response.body)).to eq(errors)
        end
      end

      describe 'GET#show' do
        subject { get :show, params: { subscriber_id: subscriber.subscriber_id } }

        it 'Returns 401 error' do
          subject
          expect(JSON.parse(response.body)).to eq(errors)
        end
      end

      describe 'POST#create' do
        subject { post :create }

        it 'Returns 401 error' do
          subject
          expect(JSON.parse(response.body)).to eq(errors)
        end
      end

      describe 'DELETE#destroy' do
        subject { delete :destroy, params: { subscriber_id: subscriber.subscriber_id } }

        it 'Returns 401 error' do
          subject
          expect(JSON.parse(response.body)).to eq(errors)
        end
      end
    end
  end
end
