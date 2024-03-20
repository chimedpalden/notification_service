require 'rails_helper'

module Vineti
  module Notifications
    RSpec.describe WebhookSubscription do
      describe '#create_active_subscriptions', :feature do
        subject { Vineti::Notifications::WebhookSubscription.create_active_subscriptions }

        before(:each) do
          allow(SecureRandom).to receive(:hex).and_return('abcd1234')
          allow(SecureRandom).to receive(:uuid).and_return('abcd1234')
          allow(Stomp::Client).to receive(:new).and_return(stomp_connection)
          allow(stomp_connection).to receive(:open?).and_return("Connected")
        end

        let(:subscriber) { FactoryBot.create(:webhook_subscriber) }
        let(:subscriber_id) { subscriber.subscriber_id }
        let(:event) { subscriber.events.first }
        let(:connection_frame) { double('ConnectionFrame', command: "CONNECTED") }
        let(:stomp_connection) { double('Stomp::Client', connection_frame: connection_frame) }
        let(:subscription_name) { "#{subscriber_id}++#{SecureRandom.uuid}" }
        let(:error) { DummyError.new('Runtime Error', 'backtrace') }

        let(:webhook_error) { Vineti::Notifications::Subscriber::WebhookErrorResponse.new(error) }
        let(:publish_event) { ::EventServiceClient::Publish.to_virtual_topic(event.name, {}, {}) }

        let(:header) do
          {
            'ack' => 'client',
            'activemq.prefetchSize' => 1,
            'activemq.subscriptionName' => subscription_name
          }
        end

        context 'when enabled', vineti_activemq_enable: :enabled, enable_virtual_topics: :enabled do
          it 'calls amq with correct params' do
            expect(stomp_connection).to receive(:subscribe).with("/queue/Consumer.#{subscriber_id}.VirtualTopic.#{event.name}", anything)
            expect(subject.first[:subscriber_id]).to eq(subscriber_id)
          end

          context 'when subscription handler proc is invoked with amq response' do
            let(:webhook_service) { double('WebhookService').as_null_object }
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
              allow(Vineti::Notifications::Subscriber::WebhookService).to receive(:new) do |args|
                expect(args[:event]).to eq(event)
                expect(args[:metadata].keys).to eq(%w[treatment_id step_name procedure_status])
                expect(args[:delayed_time]).to eq(nil)
              end.and_return(webhook_service)

              subject
            end

            it 'raises an exception if error message class received' do
              subscriber
              allow(stomp_connection).to receive(:close).and_return(nil)
              allow_any_instance_of(Vineti::Notifications::Subscriber::WebhookService).to receive(:send_notification).and_return(webhook_error)
              publish_event
              expect { subject }.to raise_error(RuntimeError, webhook_error.message.to_s)
            end

            context 'when request is inbound' do
              let(:json_file_name) { 'inbound-amq-response.json' }

              it 'don\'t calls email service' do
                allow(Vineti::Notifications::Subscriber::WebhookService).to receive(:new) do |args|
                  expect(args[:event]).to eq(event)
                  expect(args[:metadata].keys).to eq(%w[treatment_id step_name procedure_status])
                  expect(args[:delayed_time]).to eq(nil)
                end.and_return(webhook_service)
                expect(Vineti::Notifications::Subscriber::WebhookService).not_to receive(:new)

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
end
