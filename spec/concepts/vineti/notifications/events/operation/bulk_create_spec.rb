require 'rails_helper'

describe Vineti::Notifications::Events::Operation::BulkCreate do
  subject { Vineti::Notifications::Events::Operation::BulkCreate.call(events: params) }

  let(:content_error) { [{ message: 'content is invalid' }] }

  describe 'valid params' do
    let!(:template1) { FactoryBot.create(:notification_template, template_id: 'template1') }
    let!(:template2) { FactoryBot.create(:notification_template, template_id: 'template2') }
    let!(:template3) { FactoryBot.create(:notification_template, template_id: 'template3') }

    let(:params) do
      [
        {
          'event_name' => 'order_completed',
          'subscribers' => [
            {
              'subscriber_id' => 'developer_group',
              'template' => 'template1',
              'type' => 'email',
              'active' => true,
              'delayed_time' => 5,
              'data' => {
                'from_address' => 'no-reply@vineti.com',
                'to_addresses' => [
                  'developer@vineti.com',
                ],
                'cc_addresses' => [
                  'product_managers@vineti.com',
                ],
              },
            },
            {
              'subscriber_id' => 'channel_group',
              'type' => 'webhook',
              'active' => true,
              'data' => {
                'webhook_url' => 'https =>//hooks.slack.com/services/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',
                'token_url' => 'https://externalsystem/token',
                'vault_key' => 'jnj_client_id_01'
              },
            },
            {
              'subscriber_id' => 'channel_group_liquid',
              'type' => 'webhook',
              'active' => true,
              'data' => {
                'webhook_url' => "{{ 'config_webhook_url' | config }}",
                'token_url' => 'https://externalsystem/token',
                'vault_key' => 'jnj_client_id_01'
              },
            },
          ],
        },
        {
          'event_name' => 'labelary_fail',
          'subscribers' => [
            {
              'subscriber_id' => 'developer_group_2',
              'template' => 'template2',
              'type' => 'email',
              'active' => true,
              'data' => {
                'from_address' => 'no-reply@vineti.com',
                'to_addresses' => ['developer@vineti.com'],
                'cc_addresses' => %w[product_managers@vineti.com shipment@vineti.com],
              },
            },
          ],
        },
        {
          'event_name' => 'approval_message',
          'publishers' => [
            {
              'publisher_id' => 'salesforce',
              'template' => 'template3',
              'payload_type' => 'JSON',
              'active' => true,
              'data' => {
                'request_method' => 'post',
                'token' => 'AKOOLO$NJSNJAN',
              },
              'subscribers' => [
                {
                  'subscriber_id' => 'xyz',
                  'template' => 'template2',
                  'type' => 'email',
                  'active' => true,
                  'data' => {
                    'from_address' => 'no-reply@vineti.com',
                    'to_addresses' => ['developer@vineti.com'],
                    'cc_addresses' => %w[product_managers@vineti.com shipment@vineti.com],
                  },
                },
              ],
            },
          ],
        },
      ]
    end

    before do
      allow(Vineti::Notifications::UserRoleProcessor).to receive(:fetch_users_from_role).and_return(
        'from_address' => 'morty@birdman.com',
        'to_addresses' => ['rick.sanchez@plumbus.com'],
        'webhook_url' => 'https://google.com',
        'token_url' => 'https://externalsystem/token',
        'vault_key' => 'jnj_client_id_01'
      )
    end

    it 'creates the templates' do
      expect { subject }.to change(Vineti::Notifications::Event, :count).from(0).to(3)
    end

    it 'creates three email subscribers' do
      expect { subject }.to change(Vineti::Notifications::Subscriber::EmailSubscriber, :count).from(0).to(3)
    end

    it 'creates one webhook subscribers' do
      expect { subject }.to change(Vineti::Notifications::Subscriber::WebhookSubscriber, :count).from(0).to(2)
    end

    it 'creates internalApi subscriber for publisher events' do
      expect { subject }.to change(Vineti::Notifications::Subscriber::InternalApiSubscriber, :count).from(0).to(1)
    end

    it 'creates the publishers' do
      expect { subject }.to change(Vineti::Notifications::Publisher, :count).from(0).to(1)
    end

    it 'returns a 201 status' do
      response = subject
      expect(response[:status]).to eq(201)
    end

    it 'reads the liquid template and returns values from the config' do
      allow(Vineti::Templates::Config).to receive(:fetch).with("config_webhook_url").and_return('https://vineti.com')
      subject
      liquified_subscriber = Vineti::Notifications::Subscriber.where(subscriber_id: 'channel_group_liquid').first
      expect(liquified_subscriber.data["webhook_url"]).to eq('https://vineti.com')
      expect(liquified_subscriber.data["token_url"]).to eq('https://externalsystem/token')
      expect(liquified_subscriber.data["vault_key"]).to eq('jnj_client_id_01')
    end
  end

  describe 'invalid params' do
    describe 'not an array' do
      let(:params) do
        { event_name: 'some string', email_template_id: 'some string', email_subscribers: [] }
      end

      it 'returns an error' do
        response = subject
        expect(response[:status]).to eq(422)
        expect(response[:errors]).to eq(content_error)
      end
    end

    describe 'invalid keys' do
      let(:params) do
        [
          { event_name: 'some string', email_template_id: 'some string', email_subscribers: [] },
          { event_name: 'some string', email_template_id: 'some string', other_key: [] },
        ]
      end

      it 'returns an error' do
        response = subject
        expect(response[:status]).to eq(422)
        expect(response[:errors]).to eq(content_error)
      end
    end

    describe 'template id and name are not strings' do
      let(:params) do
        [
          { event_name: {}, email_template_id: 'some string', email_subscribers: [] },
          { event_name: 'some string', email_template_id: 'some string', other_key: [] },
        ]
      end

      it 'returns an error' do
        response = subject
        expect(response[:status]).to eq(422)
        expect(response[:errors]).to eq(content_error)
      end
    end

    describe 'email_subscribers have invalid keys' do
      let(:params) do
        [
          { event_name: 'some string', email_template_id: 'some string', email_subscribers: [{ other_key: 'bad' }] },
        ]
      end

      it 'returns an error' do
        response = subject
        expect(response[:status]).to eq(422)
        expect(response[:errors]).to eq(content_error)
      end
    end

    describe 'publisher have invalid keys' do
      let(:params) do
        [
          { event_name: 'some string', publishers: [{ other_key: 'bad' }] },
        ]
      end

      it 'returns an error' do
        response = subject
        expect(response[:status]).to eq(422)
        expect(response[:errors]).to eq(content_error)
      end
    end
  end
end
