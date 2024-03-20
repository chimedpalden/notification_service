require 'rails_helper'

module Vineti::Notifications
  describe Events::Operation::PublishRetry do
    subject do
      Events::Operation::PublishRetry.call
    end

    context "Republishing the failed persisted events " do
      let(:event) { FactoryBot.create(:event) }
      let(:failed_transaction) { FactoryBot.create(:event_transaction, transaction_id: SecureRandom.uuid, status: 'ERROR', event: event, retries_count: 0) }

      let(:success_response) do
        {
          success: true
        }
      end

      let(:failure_response) do
        {
          success: false
        }
      end

      let(:failure_response_amq_down) do
        {
          success: false,
          errors: [Errno::ECONNREFUSED.new]
        }
      end

      let(:airbrake_notify_params) do
        {
          error: [],
          transaction_id: 'abc-123',
          event_name: 'test_event'
        }
      end

      before(:each) do
        @failed_transaction = failed_transaction
      end

      before do
        allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('vineti_activemq_retry_enable', true).and_return(true)
        allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('vineti_failed_event_retry_max_count').and_return(5)
        allow(success_response).to receive(:success?).and_return(true)
        allow(failure_response).to receive(:success?).and_return(false)
        allow(failure_response_amq_down).to receive(:success?).and_return(false)
      end

      context 'vineti_activemq_retry_enable', :feature do
        context 'when enabled', vineti_activemq_retry_enable: :enabled, vineti_failed_event_retry_max_count: 5 do
          it 'Should notify when a max number of retries is <= 0' do
            allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('vineti_failed_event_retry_max_count').and_return(0)
            expect(subject[:status]).to eq(200)
            expect(subject[:errors][:message]).to eq('Max retries is set to 0')
          end

          it 'Should notify when no publish messages are found' do
            failed_transaction.update(status: 'SUCCESS')
            expect(subject[:status]).to eq(422)
            expect(subject[:errors][:message]).to eq('Failed Published transactions not found')
          end

          it 'Should update the status to success when successfully republish' do
            allow(Vineti::Notifications::Events::Operation::NotificationRetry).to receive(:call).and_return(success_response)
            subject
            failed_transaction.reload
            expect(failed_transaction.retries_count).to eq(1)
            expect(failed_transaction.status).to eq('SUCCESS')
          end

          it 'Should update the retry count when republish fails' do
            failure_response
            allow(Vineti::Notifications::Events::Operation::NotificationRetry).to receive(:call).and_return(failure_response)
            subject
            failed_transaction.reload
            expect(failed_transaction.status).to eq('ERROR')
            expect(failed_transaction.retries_count).to eq(1)
          end

          it 'Should notify airbrake when AMQ is down' do
            allow(Vineti::Notifications::Events::Operation::NotificationRetry).to receive(:call).and_return(failure_response_amq_down)
            allow(Airbrake).to receive(:notify).with('ActiveMQ Down', airbrake_notify_params).and_return(true)
            expect(Airbrake).to receive(:notify)
            subject
          end
        end

        context "When disabled", vineti_activemq_retry_enable: :disabled, vineti_failed_event_retry_max_count: 5 do
          before do
            allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('vineti_activemq_retry_enable', true).and_return(false)
          end

          it 'Should notify when feature flag is disabled' do
            expect(subject[:status]).to eq(501)
          end

          it 'Should not initiate retry operation' do
            # allow(Vineti::Notifications::Events::Operation::NotificationRetry).to receive(:call).and_return(success_response)
            expect(Vineti::Notifications::Events::Operation::NotificationRetry).not_to receive(:call)
            subject
            failed_transaction.reload
            expect(failed_transaction.retries_count).to eq(0)
            expect(failed_transaction.status).to eq('ERROR')
          end
        end
      end
    end
  end
end
