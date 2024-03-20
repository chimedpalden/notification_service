# frozen_string_literal: true

require 'rails_helper'

module Vineti::Notifications
  RSpec.describe EventsController, type: :controller do
    routes { Vineti::Notifications::Engine.routes }
    before do
      allow_any_instance_of(Vineti::Notifications::AuthHelper).to receive(:validate_user_permissions).and_return(true)
    end

    let(:response_keys) { %w[name subscribers] }

    shared_examples_for 'events_controller' do
      context 'When user is not logged in' do
        let(:error) { { 'errors' => ['You need to sign in or sign up before continuing.'] } }

        describe 'GET#index' do
          subject { get :index }

          it 'Returns 401 error' do
            subject
            expect(JSON.parse(response.body)).to eq(error)
          end
        end

        describe 'GET#list' do
          subject { get :list }

          it 'returns 401 unauthorized error' do
            subject
            expect(JSON.parse(response.body)).to eq(error)
          end
        end

        describe 'GET#show' do
          subject { get :show, params: { name: event.name } }

          let(:event) { FactoryBot.create(:event) }

          it 'Returns 401 error' do
            subject
            expect(JSON.parse(response.body)).to eq(error)
          end
        end

        describe 'POST#create' do
          subject { post :create }

          it 'Returns 401 error' do
            subject
            expect(JSON.parse(response.body)).to eq(error)
          end
        end

        describe 'PUT#update' do
          subject { patch :update, params: { name: event.name } }

          let(:event) { FactoryBot.create(:event) }

          it 'Returns 401 error' do
            subject
            expect(JSON.parse(response.body)).to eq(error)
          end
        end

        describe 'DELETE#destroy' do
          subject { delete :destroy, params: { name: event.name } }

          let(:event) { FactoryBot.create(:event) }

          it 'Returns 401 error' do
            subject
            expect(JSON.parse(response.body)).to eq(error)
          end
        end
      end

      context 'When user is logged in' do
        before do
          api_sign_in user, request
        end

        let(:user) { FactoryBot.create(:system_user) }

        describe 'GET#index' do
          subject { get :index }

          before(:each) do
            FactoryBot.create_list(:event, 2)
          end

          it 'returns the list for events' do
            response = JSON.parse subject.body
            expect(response['data'].count).to eq(2)
            expect(response['data'].first['attributes'].keys).to match(response_keys)
          end
        end

        describe 'GET#list' do
          subject { get :list }

          before(:each) do
            FactoryBot.create_list(:event, 2)
          end

          it 'returns the event names list' do
            event_names = Vineti::Notifications::Event.pluck(:name)
            response = JSON.parse subject.body
            expect(response['events'].count).to eq(2)
            expect(response['events']).to eq(event_names)
          end
        end

        describe 'GET#show' do
          subject { get :show, params: { name: name } }

          context 'When event with name is present' do
            let(:name) { FactoryBot.create(:event).name }

            it 'returns a json data for event' do
              response = JSON.parse subject.body

              expect(response['data']['attributes']['name']).to eq(name)
            end
          end

          context 'When event with name is not present' do
            let(:name) { SecureRandom.hex(16) }

            it 'returns status 404' do
              subject
              expect(response.status).to eq(404)
            end
          end
        end

        describe 'POST#create' do
          subject { post :create, params: params }

          let(:active_mq) { double("active_mq") }
          let(:event_name) { 'order_completed' }
          let(:params) { { event: { name: event_name } } }

          before do
            allow(active_mq).to receive(:subscribe_to_topic).with(event_name, "#{event_name}_subscription").and_return(true)
          end

          context 'when params are correct' do
            it 'Creates an event and returns a json' do
              expect { subject }.to change(Vineti::Notifications::Event, :count).by(1)
              response = JSON.parse subject.body
              expect(response['data']['attributes']['name']).to eq(event_name)
            end

            it 'Creates topic in ActiveMq' do
              subject
              allow(active_mq).to receive(:subscribe_to_topic).with(event_name, "#{event_name}_subscription").and_return(true)
            end
          end

          context 'when params are incorrect' do
            let(:event_name) { '' }

            it 'does not creates an event and returns a json with error message' do
              expect { subject }.not_to change(Vineti::Notifications::Event, :count)
              response = JSON.parse subject.body
              expect(response['error']).to eq("Validation failed: Name can't be blank")
            end

            it 'does not creates topics in ActiveMq' do
              subject
              expect(active_mq).not_to receive(:subscribe_to_topic).with(event_name, "#{event_name}_subscription")
            end
          end
        end

        describe 'PUT#update' do
          subject { put :update, params: params }

          let(:params) do
            {
              name: name,
              event: {
                name: 'order_shipped',
              },
            }
          end

          context 'When event with name is present' do
            let(:name) { FactoryBot.create(:event).name }

            it 'returns json response' do
              response = JSON.parse subject.body

              expect(response['data']['attributes']['name']).to eq('order_shipped')
            end
          end

          context 'When event with name is not present' do
            let(:name) { SecureRandom.hex(16) }

            it 'returns status 404' do
              subject
              expect(response.status).to eq(404)
            end
          end
        end

        describe 'DELETE#destroy' do
          subject { delete :destroy, params: { name: name } }

          context 'When event with name passed is present' do
            let(:name) { FactoryBot.create(:event).name }

            it 'deletes record and returns json' do
              response = JSON.parse subject.body

              expect(response['data']['attributes']['name']).to eq(name)
            end
          end

          context 'When event with name passed is not present' do
            let(:name) { SecureRandom.hex(16) }

            it 'returns status 404' do
              subject
              expect(response.status).to eq(404)
            end
          end
        end
      end
    end

    context 'vineti_activemq_enable', :feature do
      context 'when disabled', vineti_activemq_enable: :disabled, enable_virtual_topics: :disabled do
        it_behaves_like 'events_controller'
      end

      context 'when enabled', vineti_activemq_enable: :enabled, enable_virtual_topics: :enabled do
        it_behaves_like 'events_controller'
      end
    end
  end
end
