require 'rails_helper'

module Vineti::Notifications
  RSpec.describe InboundEventsController, :feature, type: :controller do
    routes { Vineti::Notifications::Engine.routes }
    before do
      allow_any_instance_of(Vineti::Notifications::AuthHelper).to receive(:validate_user_permissions).and_return(true)
    end

    context 'When user is not logged in' do
      let(:error) { { 'errors' => ['You need to sign in or sign up before continuing.'] } }

      describe 'POST#message' do
        subject { post :message }

        it 'Returns 401 error' do
          subject
          expect(JSON.parse(response.body)).to eq(error)
        end
      end
    end

    context 'When Enabled', inbound_event_enable: :enabled do
      context 'When user is logged in' do
        before do
          api_sign_in user, request
          request.headers['HTTP_PUBLISHER_TOKEN'] = publisher_token
        end

        let(:user) { FactoryBot.create(:system_user) }

        describe 'POST#message' do
          subject { post :message, params: params }

          let(:event) { FactoryBot.create(:event) }
          let(:publisher) { FactoryBot.create(:publisher) }
          let(:params) { { payload: payload } }
          let(:payload) do
            {
              "event_name": event.name,
              "orchestrator": { a: 'b' }.with_indifferent_access,
            }
          end
          let(:publisher_token) { publisher.data['token'] }
          let(:connection_frame) { double('ConnectionFrame', command: "CONNECTED", headers: { message: "" }) }
          let(:mock_client) { double('Stomp::Client', connection_frame: connection_frame) }

          before do
            publisher.events << event
            allow(mock_client).to receive(:publish).and_return('abc1234')
            allow(mock_client).to receive(:subscribe).and_return('xyz456')
            allow(Stomp::Client).to receive(:new) { mock_client }

            allow(mock_client).to receive(:open?).and_return("Connected")
            allow(mock_client).to receive(:close).and_return("Disconnected")
          end

          context 'when request is valid' do
            it 'Returns 200' do
              expect { subject }.to change { Vineti::Notifications::EventTransaction.count }.by(1)
              expect(response.status).to eq 200
              expect(JSON.parse(response.body)).to eq("message" => "request registered")
            end
          end

          context 'when request is invalid' do
            let(:payload) { { "event_name": nil } }

            it 'Returns error' do
              subject
              expect(response.status).to eq 422
              expect(JSON.parse(response.body)['errors']).to include("event_name" => "parameter is required")
              expect(JSON.parse(response.body)['errors']).to include("orchestrator" => "parameter is required")
            end
          end

          context 'when payload is empty' do
            let(:payload) { {} }

            it 'Returns error' do
              subject
              expect(response.status).to eq 400
              expect(JSON.parse(response.body)['error']).to eq("param is missing or the value is empty: payload")
            end
          end

          context 'when publisher token is missing' do
            let(:publisher_token) { nil }

            it 'Returns error publisher token is not present' do
              subject
              expect(response.status).to eq 422
              expect(JSON.parse(response.body)['errors']).to eq([{ "publisher_token" => "header is required" }])
            end
          end
        end
      end
    end

    context 'When Disabled', inbound_event_enable: :disabled do
      before do
        api_sign_in user, request
      end

      let(:user) { FactoryBot.create(:system_user) }

      describe 'POST#message' do
        subject { post :message }

        it 'Returns 501' do
          subject
          expect(response.status).to eq 501
          expect(JSON.parse(response.body)).to eq("message" => "not implemented")
        end
      end
    end
  end
end
