require 'rails_helper'

module Vineti::Notifications
  RSpec.describe EventTransactionsController, type: :controller do
    routes { Vineti::Notifications::Engine.routes }

    before do
      allow_any_instance_of(Vineti::Notifications::AuthHelper).to receive(:validate_user_permissions).and_return(true)
    end

    context 'When user is not logged in' do
      let(:event_transaction) { FactoryBot.create(:event_transaction, :with_event) }
      let(:error) { { 'errors' => ['You need to sign in or sign up before continuing.'] } }
      let(:response_body) { JSON.parse(response.body) }

      describe 'PUT#update' do
        subject { patch :update, params: { transaction_id: event_transaction.transaction_id } }

        it 'Returns 401 error' do
          subject
          expect(response_body).to eq(error)
        end
      end

      describe 'GET#show' do
        subject { get :show, params: { transaction_id: event_transaction.transaction_id } }

        it 'Returns 401 error' do
          subject
          expect(response_body).to eq(error)
        end
      end

      describe 'GET#find_by_event' do
        subject { get :find_by_event, params: { name: event_transaction.event.name } }

        it 'Returns 401 error' do
          subject
          expect(response_body).to eq(error)
        end
      end
    end

    context 'When user is signed in' do
      before do
        api_sign_in user, request
      end

      let(:user) { FactoryBot.create(:system_user) }
      let(:event_transaction) { FactoryBot.create(:event_transaction) }

      describe "PUT #update" do
        subject { patch :update, params: params }

        context 'When params is correct' do
          let(:params) do
            {
              transaction_id: event_transaction.transaction_id,
              transaction: {
                status: "WSO_SUCCESS",
              },
            }
          end

          it 'successfully updates event_transaction status' do
            expect(event_transaction.reload.status).to eq(nil)
            subject
            expect(event_transaction.reload.status).to eq('WSO_SUCCESS')
          end
        end

        context 'When params is incorrect' do
          context 'when transaction_id is not found' do
            let(:params) do
              {
                transaction_id: '12312',
                transaction: {
                  status: "CREATED",
                },
              }
            end

            it 'returns 404' do
              expect(subject.status).to eq(404)
            end
          end

          context 'when then status is not included in enum defination' do
            let(:params) do
              {
                transaction_id: event_transaction.transaction_id,
                transaction: {
                  status: "FAIL",
                },
              }
            end

            it 'raises an error' do
              expect { subject }.to raise_error(ActiveRecord::StatementInvalid)
            end
          end
        end
      end

      describe 'GET#show' do
        subject { get :show, params: { transaction_id: transaction_id } }

        let(:event_transaction) { FactoryBot.create(:event_transaction) }
        let(:response_body) { JSON.parse(response.body) }

        context 'When record with transaction id is present' do
          let(:transaction_id) { event_transaction.transaction_id }

          it 'Returns json response with event transaction records attributes' do
            subject
            expect(response_body['data']['attributes'].keys).to eq(%w[transaction_id payload status response_code response subscriber])
          end
        end

        context 'When record with transaction id is missing' do
          let(:transaction_id) { SecureRandom.hex }
          let(:error) do
            {
              'status' => 'No Matching Record Found',
              'error' => "Couldn't find Vineti::Notifications::EventTransaction",
            }
          end

          it 'returns 404 response' do
            subject
            expect(response_body).to eq(error)
            expect(response.status).to eq(404)
          end
        end
      end

      describe 'GET#fetch_by_event' do
        subject { get :find_by_event, params: { name: event_name } }

        let(:event_transaction) { FactoryBot.create(:event_transaction, :with_event) }
        let(:response_body) { JSON.parse(response.body) }

        context 'When transaction record for event is present' do
          let(:event_name) { event_transaction.event.name }

          it 'Returns json response with event transaction records attributes' do
            subject
            expect(response_body['data']).to be_an_instance_of(Array)
            expect(response_body['data'][0]['attributes'].keys).to eq(%w[transaction_id payload status response_code response subscriber])
          end
        end

        context 'When record for event is not present' do
          let(:event_transaction) { FactoryBot.create(:event_transaction) }
          let(:event_name) { 'test_event' }
          let(:error) do
            {
              'status' => 'No Matching Record Found',
              'error' => "Couldn't find Vineti::Notifications::Event",
            }
          end

          it 'returns 404 response' do
            subject
            expect(response_body).to eq(error)
            expect(response.status).to eq(404)
          end
        end

        context 'When transaction record for event is not present' do
          let(:event) { FactoryBot.create(:event) }
          let(:event_name) { event.name }

          it 'returns blank array' do
            subject
            expect(response_body['data']).to eq([])
            expect(response.status).to eq(200)
          end
        end
      end
    end
  end
end
