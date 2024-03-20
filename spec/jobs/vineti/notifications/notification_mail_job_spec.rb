require 'rails_helper'

RSpec.describe Vineti::Notifications::NotificationMailJob, type: :job do
  context 'When job object is called' do
    it 'matches with enqueued job' do
      ActiveJob::Base.queue_adapter = :test
      expect { Vineti::Notifications::NotificationMailJob.perform_later }.to have_enqueued_job(Vineti::Notifications::NotificationMailJob)
    end
  end

  describe "after the job object is perfomed" do
    ActiveJob::Base.queue_adapter = :test

    let(:subject) do
      described_class.perform_now(
        source: source,
        destination: destination,
        message: data,
        transaction_id: transaction_id,
        email_log_attributes: log_attributes,
        log_email?: true
      )
    end

    let(:transaction_id) { SecureRandom.uuid }
    let!(:event_transaction) { FactoryBot.create(:event_transaction, transaction_id: transaction_id, status: "CREATED") }
    let(:data) do
      {
        subject: {},
        body: {
          text: {
            data: {},
          },
          html: {
            data: {},
          },
        },
      }
    end
    let(:destination) do
      {
        to_addresses: ['to_addresses@example.com'],
        cc_addresses: ['cc_addresses@example.com'],
        bcc_addresses: ['bcc_addresses@example.com']
      }
    end
    let(:source) { "from_address@example.com" }
    let(:template) { FactoryBot.create(:template_with_default_variables) }
    let(:event) { FactoryBot.create(:event) }
    let(:subscriber) { FactoryBot.create(:email_subscriber, template: template) }
    let(:message_id) { 'message-123-id-456-for-789-mail' }
    let(:log_attributes) do
      {
        template: template,
        subscriber: subscriber,
        email_message: {
          source: source,
          destination: destination,
          topic_type: "event",
          topic: event.name
        }
      }
    end

    context 'when the email delivery is success' do
      before do
        allow_any_instance_of(Aws::SES::Client).to receive(:send_email).and_return(Seahorse::Client::Response.new(data: mail_response))
        allow_any_instance_of(Seahorse::Client::Response).to receive(:successful?).and_return(true)
      end

      let(:mail_response) do
        Ses.new.client.stub_data(:send_email, message_id: message_id)
      end

      it "it updates the transaction status and success response" do
        expect { subject }.to change(Vineti::Notifications::NotificationEmailResponse::SuccessResponse, :count).by(1)

        event_transaction.reload
        expect(event_transaction.status).to eq('SUCCESS')
      end
    end

    context 'when the email delivery fails' do
      before do
        allow_any_instance_of(Aws::SES::Client).to receive(:send_email).and_raise("The security token included in the request is invalid.")
        allow_any_instance_of(Seahorse::Client::Response).to receive(:successful?).and_return(true)
      end

      it "it updates the transaction status and error response" do
        expect { subject }.to change(Vineti::Notifications::NotificationEmailResponse::ErrorResponse, :count).by(1)

        event_transaction.reload
        expect(event_transaction.status).to eq('ERROR')
      end
    end
  end
end
