require 'rails_helper'

module Vineti::Notifications
  RSpec.describe EmailSubscription do
    describe '#create_active_subscriptions', :feature do
      subject { Vineti::Notifications::EmailSubscription.create_active_subscriptions }

      before do
        allow(SecureRandom).to receive(:hex).and_return('abcd1234')
        allow(SecureRandom).to receive(:uuid).and_return('abcd1234')
        allow(Stomp::Client).to receive(:new).and_return(stomp_connection)
        allow(stomp_connection).to receive(:open?).and_return("Connected")
      end

      let(:connection_frame) { double('ConnectionFrame', command: "CONNECTED") }
      let(:stomp_connection) { double('Stomp::Client', connection_frame: connection_frame) }
      let(:email_subscriber) { FactoryBot.create(:email_subscriber) }
      let(:subscriber_id) { email_subscriber.subscriber_id }
      let(:event_name) { email_subscriber.events.last.name }
      let(:subscription_name) { "#{subscriber_id}++#{SecureRandom.uuid}" }
      let(:error) { DummyError.new('Runtime Error', 'backtrace') }
      let(:email_error) { Vineti::Notifications::Subscriber::EmailErrorResponse.new(error) }
      let(:publish_event) { ::EventServiceClient::Publish.to_virtual_topic(event_name, {}, {}) }

      let(:header) do
        {
          'ack' => 'client',
          'activemq.prefetchSize' => 1,
          'activemq.subscriptionName' => subscription_name,
        }
      end

      context 'when enabled', vineti_activemq_enable: :enabled, enable_virtual_topics: :enabled do
        context 'when subscription handler proc is invoked with amq response' do
          let(:email_service) { double('EmailService').as_null_object }
          let(:json_file_name) { 'amq-response.json' }
          let(:amq_response_body) { File.read(Rails.root.join('..', '..', 'spec', 'fixtures', 'files', json_file_name)) }
          let(:amq_headers) { { "redelivered": true } }
          let(:stomp_message) { double('Stomp::Message', body: amq_response_body, headers: amq_headers) }

          before do
            allow_any_instance_of(::EventServiceClient::Adapters::Activemq).to receive(:subscribe_to_topic) do |_instance, _subscriber_id, &handler|
              handler.call(stomp_message)
            end
            allow_any_instance_of(::EventServiceClient::Adapters::Activemq).to receive(:subscribe_to_virtual_topic) do |_instance, _subscriber_id, &handler|
              handler.call(stomp_message)
            end
          end

          it 'calls email service with the correct params' do
            allow(Vineti::Notifications::Subscriber::EmailService).to receive(:new) do |args|
              expect(args[:event]).to eq(subscriber.event)
              expect(args[:metadata].keys).to eq(%w[treatment_id step_name procedure_status])
              expect(args[:delayed_time]).to eq(nil)
            end.and_return(email_service)

            subject
          end

          it 'raises an exception if error message class received' do
            email_subscriber
            allow(Vineti::Notifications::Subscriber::EmailService).to receive(:new).with(anything).and_return(email_service)
            allow(email_service).to receive(:send_notification_to_subscriber).and_return(email_error)
            allow(stomp_connection).to receive(:close).and_return(nil)
            publish_event
            expect { subject }.to raise_error(RuntimeError, email_error.message.to_s)
          end

          context 'when request is inbound' do
            let(:json_file_name) { 'inbound-amq-response.json' }

            it "doesn't call email service" do
              allow(Vineti::Notifications::Subscriber::EmailService).to receive(:new) do |args|
                expect(args[:event]).to eq(event)
                expect(args[:metadata].keys).to eq(%w[treatment_id step_name procedure_status])
                expect(args[:delayed_time]).to eq(nil)
              end.and_return(email_service)
              expect(Vineti::Notifications::Subscriber::EmailService).not_to receive(:new)

              subject
            end
          end
        end
      end

      context 'when disabled', vineti_activemq_enable: :disabled, enable_virtual_topics: :disabled do
        it 'calls amq with correct params' do
          expect(stomp_connection).not_to receive(:subscribe)
          expect(subject.first).to be nil
        end
      end
    end
  end
end
