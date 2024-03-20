require 'rails_helper'

describe Vineti::Notifications::PubSubUpsertHelper do
  let(:class_instance) { (Class.new { include Vineti::Notifications::PubSubUpsertHelper }).new }
  let!(:event) { FactoryBot.create(:event) }
  let!(:template1) { FactoryBot.create(:notification_template, template_id: 'template1') }
  let!(:template2) { FactoryBot.create(:notification_template, template_id: 'template2') }
  let!(:template3) { FactoryBot.create(:notification_template, template_id: 'template3') }
  let(:subscribers_config) do
    [
      {
        "subscriber_id" => "developer_group",
        "template" => "template1", "type" => "email", "active" => true,
        "data" => {
          "from_address" => "no-reply@vineti.com",
          "to_addresses" => ["developer@vineti.com"],
          "cc_addresses" => ["product_managers@vineti.com"],
        },
      },
      { "subscriber_id" => "channel_group",
        "type" => "webhook", "active" => true,
        "data" => {
          "webhook_url" => "https =>//hooks.slack.com/services/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",
          'token_url' => 'https://externalsystem/token',
          'vault_key' => 'jnj_client_id_01',
        }, },
    ]
  end
  let(:invalid_subscribers_config) do
    [{
      "subscriber_id" => "channel_group",
      "type" => "invalid_type",
      "active" => true,
      "data" => {
        "webhook_url" => "https =>//hooks.slack.com/services/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",
        'token_url' => 'https://externalsystem/token',
        'vault_key' => 'jnj_client_id_01',
      },
    }]
  end

  describe '#upsert_subscribers' do
    it 'creates subscribers' do
      expect do
        class_instance.send(:upsert_subscribers, subscribers: subscribers_config,
                                                 topic: event)
      end .to change(Vineti::Notifications::Subscriber, :count).from(0).to(2)
    end

    it 'raises error for invalid type' do
      expect do
        class_instance.send(:upsert_subscribers, subscribers: invalid_subscribers_config,
                                                 topic: event)
      end .to raise_error "Undefined Subscriber Type"
    end
  end

  describe '#upsert_publishers' do
    let(:publishers_config) do
      [{
        "publisher_id" => "salesforce",
        "template" => "template3",
        "payload_type" => "JSON", "active" => true,
        "data" => {
          "request_method" => "post",
          "token" => "AKOOLO$NJSNJAN",
        },
        "subscribers" => subscribers_config,
      }]
    end

    it 'creates publishers' do
      expect do
        class_instance.send(:upsert_publishers, publishers: publishers_config, event: event)
      end .to change(Vineti::Notifications::Publisher, :count).from(0).to(1)
    end

    it 'creates publisher subscribers along with internal subscriber' do
      expect do
        class_instance.send(:upsert_publishers, publishers: publishers_config, event: event)
      end .to change(Vineti::Notifications::Subscriber, :count).from(0).to(3)
    end

    it 'raises error for invalid type' do
      expect do
        class_instance.send(:upsert_subscribers, subscribers: invalid_subscribers_config, topic: event)
      end .to raise_error "Undefined Subscriber Type"
    end
  end
end
