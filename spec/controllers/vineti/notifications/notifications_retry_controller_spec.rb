require 'rails_helper'

module Vineti::Notifications
  RSpec.describe NotificationsRetryController, :feature, type: :controller do
    routes { Vineti::Notifications::Engine.routes }
    before do
      allow_any_instance_of(Vineti::Notifications::AuthHelper).to receive(:validate_user_permissions).and_return(true)
    end

    context 'When user is not logged in' do
      let(:error) { { 'errors' => ['You need to sign in or sign up before continuing.'] } }

      describe 'POST#retry_publishing' do
        subject { post :retry_publish }
        it 'Returns 401 error' do
          subject
          expect(JSON.parse(response.body)).to eq(error)
        end
      end
    end

    context 'When user is logged in' do
      before do
        api_sign_in(user, request)
      end
      let(:user) { FactoryBot.create(:system_user) }

      describe 'POST#retry_publishing' do
        subject { post :retry_publish, params: params }

        let(:event) { FactoryBot.create(:event) }
        let(:event_transaction) { FactoryBot.create(:event_transaction, :with_event, status: "ERROR") }
        let(:params) { { transaction: payload } }
        let(:payload) do
          {
            "transaction_id": event_transaction.transaction_id
          }
        end
        let(:connection_frame) { double('ConnectionFrame', command: "CONNECTED", headers: { message: "" }) }
        let(:mock_client) { double('Stomp::Client', connection_frame: connection_frame) }

        before do
          allow(mock_client).to receive(:publish).and_return("abc1234")
          allow(mock_client).to receive(:subscribe).and_return("xyz456")
          allow(Stomp::Client).to receive(:new) { mock_client }
          allow(mock_client).to receive(:open?).and_return("Connected")
          allow(mock_client).to receive(:close).and_return("Disconnected")
        end

        context 'when request is valid' do
          it 'Returns 200' do
            subject
            expect(response.status).to eq 200
            expect(JSON.parse(response.body)).to eq("message" => "Retry published successfully")
          end
        end

        context 'when transaction id is missing' do
          let(:payload) do
            {
              "transaction_id": nil
            }
          end

          it 'Returns error transaction id is not present' do
            subject
            expect(response.status).to eq 422
            expect(JSON.parse(response.body)['errors']).to eq([{ "transaction" => "Transaction not found" }])
          end
        end

        context 'when transaction event is missing' do
          let(:event_transaction) { FactoryBot.create(:event_transaction) }

          let(:payload) do
            {
              "transaction_id": event_transaction.transaction_id
            }
          end

          it 'Returns error when associated event is not present' do
            subject
            expect(response.status).to eq 422
            expect(JSON.parse(response.body)['errors']).to eq([{ "event" => 'Event not found' }])
          end
        end
      end
    end
  end
end
