require 'rails_helper'

module Vineti
  module Notifications
    RSpec.describe SubscriptionManager do
      before do
        allow(ENV).to receive(:fetch).with('VINETI_ACTIVEMQ_EVENT_DROP_QUEUE', 'EventServicev1.ERROR.Q').and_return(nil)
        allow(ENV).to receive(:fetch).with('VINETI_ACTIVE_RESPONSE_TOPIC', 'EventServicev1.RESP.Q').and_return(nil)
      end

      describe '#create_for' do
        subject { Vineti::Notifications::SubscriptionManager }

        let(:subscriber_id) { 'order_approved_developer_group_01' }

        context 'when subscription is not present' do
          it 'returns error message' do
            expect(STDOUT).to receive(:puts).with('No subscriber found with id: topic_subscription')
            subject.create_for('topic_subscription')
          end
        end

        context 'when the subscription id is an email subscriber' do
          it 'calls email subscription create for' do
            template = Vineti::Notifications::Template.create_with(
              template_id: 'generic_template',
              data: {
                subject: 'Subject with variable',
                text_body: 'Text with {{variable}}',
                html_body: '<p>Text with {{variable}}<p>',
              }
            ).find_or_create_by(template_id: 'generic_template')

            subscriber = Vineti::Notifications::Subscriber::EmailSubscriber.create_with(
              subscriber_id: subscriber_id,
              data: {
                from_address: 'no-reply@vineti.com',
                to_addresses: ['user@vineti.com'],
              },
              template: template
            ).find_or_create_by(subscriber_id: subscriber_id)

            allow(Vineti::Notifications::EmailSubscription).to receive(:create_subscription_for).and_return(true)
            expect(Vineti::Notifications::EmailSubscription).to receive(:create_subscription_for).with(subscriber)

            subject.create_for(subscriber_id)
          end
        end

        context 'when the subscription id is a web hook subscriber' do
          it 'calls webhook subscription create for' do
            subscriber = Vineti::Notifications::Subscriber::WebhookSubscriber.create_with(
              subscriber_id: subscriber_id,
              data: {
                payload: { first_param: :first_param_value },
                headers: { first_header: :first_header_value },
                webhook_url: 'www.testurl.com',
                'token_url' => 'https://externalsystem/token',
                'vault_key' => 'jnj_client_id_01',
              }
            ).find_or_create_by(subscriber_id: subscriber_id)

            allow(Vineti::Notifications::WebhookSubscription).to receive(:create_subscription_for).and_return(true)
            expect(Vineti::Notifications::WebhookSubscription).to receive(:create_subscription_for).with(subscriber)

            subject.create_for(subscriber_id)
          end
        end
      end
    end
  end
end
