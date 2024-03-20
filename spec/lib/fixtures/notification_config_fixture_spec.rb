# frozen_string_literal: true

require 'rails_helper'

module Config
  class Bundle
  end
end

module Fixtures
  RSpec.describe NotificationConfigFixture do
    describe '#call' do
      subject { described_class.new }

      before do
        allow_any_instance_of(Fixtures::NotificationConfigFixture).to receive(:seed_email_templates)
        allow_any_instance_of(Fixtures::NotificationConfigFixture).to receive(:seed_notification_config)
      end

      it 'seeds email template and notification config' do
        subject.call
        expect(subject).to have_received(:seed_email_templates).once
        expect(subject).to have_received(:seed_notification_config).once
      end
    end

    describe '#fixture_file' do
      subject { described_class.new }

      before do
        allow(Config::Bundle).to receive(:bundle_path).and_return('tenant-config/barb-ga')
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return(file_content)
      end

      context 'when file is empty' do
        let(:file_content) { "" }
        it 'return empty hash' do
          expect(subject.fixture_file('test.yml')).to eq(file_content)
        end
      end

      context 'when file doesnot exist' do
        let(:file_content) { {} }
        before do
          allow(File).to receive(:exist?).and_return(false)
        end

        it 'return empty hash' do
          expect(subject.fixture_file('test.yml')).to eq(nil)
        end
      end

      context 'when file doesnot exist' do
        let(:file_content) do
          "templates:\n  - template_id: test_template\n    data:\n      subject: \"Test Subject\"\n      text_body: \"Test\"\n      html_body: \"Test\"\n "
        end

        it 'return empty hash' do
          expect(subject.fixture_file('test.yml')).to eq(file_content)
        end
      end
    end

    describe '#get_yml_data' do
      subject { described_class.new }

      before do
        allow_any_instance_of(described_class).to receive(:fixture_file).and_return(file_content)
      end

      context 'when fixture file is nil' do
        let(:file_content) { nil }
        it 'returns nil' do
          expect(subject.get_yml_data('notifications/email_templates.yml', 'templates')).to eq(nil)
        end
      end

      context 'when fixture file is empty' do
        let(:file_content) { "" }
        it 'returns nil' do
          expect(subject.get_yml_data('notifications/email_templates.yml', 'templates')).to eq(nil)
        end
      end

      context 'when fixture file is present' do
        let(:file_content) do
          "templates:\n  - template_id: test_template\n    data:\n      subject: \"Test Subject\"\n      text_body: \"Test\"\n      html_body: \"Test\"\n "
        end

        it 'returns array object' do
          expect(subject.get_yml_data('notifications/email_templates.yml', 'templates')).to eq(
            [{
              "template_id" => "test_template",
              "data" => {
                "subject" => "Test Subject",
                "text_body" => "Test",
                "html_body" => "Test"
              }
            }]
          )
        end
      end
    end

    describe '#seed_email_templates' do
      subject { described_class.new }

      before do
        allow_any_instance_of(Fixtures::NotificationConfigFixture).to receive(:get_yml_data).and_return(yaml_data)
      end

      context 'when params are passed' do
        let(:yaml_data) { nil }

        it 'returns nil' do
          expect(Fixtures::NotificationConfigFixture).to_not receive(:get_yml_data)
          expect(subject.seed_email_templates('')).to eq(nil)
        end
      end

      context 'when params are not passed' do
        let(:yaml_data) { '' }

        it 'calls get_yml_data' do
          expect_any_instance_of(described_class).to receive(:get_yml_data).once
          subject.seed_email_templates
        end
      end

      context 'when template data is invalid' do
        let(:yaml_data) { { "template_id" => "test_template" } }

        it 'raises error' do
          expect { subject.seed_email_templates }.to raise_error(StandardError, "Invalid template configuration")
        end
      end

      context 'when template data is valid' do
        let(:yaml_data) do
          [{
            "template_id" => "test_template",
            "data" => {
              "subject" => "Test Subject",
              "text_body" => "Test",
              "html_body" => "Test"
            }
          }]
        end

        it 'creates new template' do
          expect { subject.seed_email_templates }.to change { Vineti::Notifications::Template.count }.by(1)
        end
      end

      context 'when template data is valid and template already exist' do
        let(:yaml_data) do
          [{
            "template_id" => "test_template",
            "data" => {
              "subject" => "Test Subject",
              "text_body" => "Test",
              "html_body" => "Test"
            }
          }]
        end
        before do
          FactoryBot.create(:notification_template, template_id: 'test_template', subject: 'test')
        end

        it 'update existing template' do
          template = Vineti::Notifications::Template.find_by(template_id: 'test_template')
          expect do
            subject.seed_email_templates
            template.reload
          end.to change(template, :data)
        end
      end
    end

    describe '#seed_notification_config' do
      subject { described_class.new }

      before do
        allow_any_instance_of(Fixtures::NotificationConfigFixture).to receive(:get_yml_data).and_return(yaml_data)
      end

      context 'when params are passed' do
        let(:yaml_data) { nil }

        it 'returns nil' do
          expect(Fixtures::NotificationConfigFixture).to_not receive(:get_yml_data)
          expect(subject.seed_notification_config('')).to eq(nil)
        end
      end

      context 'when params are not passed' do
        let(:yaml_data) { '' }

        it 'calls get_yml_data' do
          expect_any_instance_of(described_class).to receive(:get_yml_data).once
          subject.seed_email_templates
        end
      end

      context 'when template data is valid' do
        before do
          FactoryBot.create(:notification_template, template_id: 'test_template', subject: 'test')
          FactoryBot.create(:publisher_template, :without_variables)
          allow_any_instance_of(Vineti::Notifications::PubSubUpsertHelper).to receive(:upsert_subscribers)
        end

        let(:yaml_data) do
          [{
            "event_name" => "test_event",
            "subscribers" => [{
              "subscriber_id" => "test_subscriber",
              "template" => "test_template",
              "type" => "email",
              "active" => true,
              "data" => {
                "from_address" => "test@test.com",
                "to_addresses" => ["test@test.com"]
              }
            }]
          }]
        end

        it 'creates new event and subscribers' do
          expect_any_instance_of(Vineti::Notifications::PubSubUpsertHelper).to receive(:upsert_subscribers).once
          expect { subject.seed_notification_config }.to change { Vineti::Notifications::Event.count }.by(1)
        end
      end

      context 'when template data contains publisher' do
        before do
          FactoryBot.create(:notification_template, template_id: 'test_template', subject: 'test')
          FactoryBot.create(:publisher_template, :without_variables)
          allow_any_instance_of(Vineti::Notifications::PubSubUpsertHelper).to receive(:upsert_subscribers)
          allow_any_instance_of(Vineti::Notifications::PubSubUpsertHelper).to receive(:upsert_publishers)
        end

        let(:yaml_data) do
          [{
            "event_name" => "test_event",
            "subscribers" => [{
              "subscriber_id" => "test_subscriber",
              "template" => "test_template",
              "type" => "email",
              "active" => true,
              "data" => {
                "from_address" => "test@test.com",
                "to_addresses" => ["test@test.com"]
              }
            }],
            "publishers" => [{
              "publisher_id" => "test_publisher",
              "template" => "test_publisher_template",
              "payload_type" => "JSON",
              "active" => true,
              "data" => { "request_method" => "post", "token" => "12345567" },
              "subscribers" => [{
                "subscriber_id" => "xyz",
                "template" => "test_publisher_template",
                "type" => "email",
                "active" => true,
                "data" => {
                  "from_address" => "no-reply@vineti.com",
                  "to_addresses" => ["developer@vineti.com"]
                }
              }]
            }]
          }]
        end

        it 'creates new event and calls upsert_publishers' do
          expect_any_instance_of(Vineti::Notifications::PubSubUpsertHelper).to receive(:upsert_subscribers).once
          expect_any_instance_of(Vineti::Notifications::PubSubUpsertHelper).to receive(:upsert_publishers).once
          expect { subject.seed_notification_config }.to change { Vineti::Notifications::Event.count }.by(1)
        end
      end

      context 'when exception occurs' do
        before do
          FactoryBot.create(:notification_template, template_id: 'test_template', subject: 'test')
          FactoryBot.create(:publisher_template, :without_variables)
          allow_any_instance_of(Vineti::Notifications::PubSubUpsertHelper).to receive(:upsert_subscribers).and_raise(StandardError)
        end

        let(:yaml_data) do
          [{
            "event_name" => "test_event",
            "subscribers" => [{
              "subscriber_id" => "test_subscriber",
              "template" => "test_template",
              "type" => "email",
              "active" => true,
              "data" => {
                "from_address" => "test@test.com",
                "to_addresses" => ["test@test.com"]
              }
            }]
          }]
        end

        it 'creates new event and subscribers' do
          expect { subject.seed_notification_config }.to raise_error(StandardError)
        end
      end
    end
  end
end
