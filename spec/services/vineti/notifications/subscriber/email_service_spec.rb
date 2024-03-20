# frozen_string_literal: true

require 'rails_helper'

describe Vineti::Notifications::Subscriber::EmailService do
  include ActiveSupport::Testing::TimeHelpers

  before do
    allow(Deeplink::Operation::GetURL).to receive(:call).and_return(deeplink: "/workflow/1/3")
    stub_request(:post, /email.us-west-2.amazonaws.com/)
      .and_return(status: 200, body: "", headers: {})

    allow(Vineti::Notifications::UserRoleProcessor).to receive(:fetch_users_from_role).and_return(
      'from_address' => 'morty@birdman.com',
      'to_addresses' => ['rick.sanchez@plumbus.com'],
      'webhook_url' => 'https://google.com',
      'jwt-token' => 'abc123'
    )
  end

  let(:json_file_name) { 'simple-email-template-data.json' }
  let(:json_file) { File.read(Rails.root.join('..', '..', 'spec', 'fixtures', 'files', json_file_name)) }
  let(:template_data) { params['template_data'].merge(extra_template_data) }
  let(:message_id) { 'message-123-id-456-for-789-mail' }
  let(:extra_template_data) { { 'event_name' => event.name } }
  let(:params) { JSON.parse(json_file) }
  let(:event) { FactoryBot.create(:event) }
  let(:delayed_time) { nil }
  let(:metadata) { {} }
  let(:mail) { described_class.new(topic: event, template_data: template_data, delayed_time: delayed_time, metadata: metadata) }
  let(:template) { FactoryBot.create(:template_with_default_variables) }
  let(:subscriber) { FactoryBot.create(:email_subscriber, template: template) }
  let!(:event_subscriber) { Vineti::Notifications::EventSubscriber.find_or_create_by!(event: event, subscriber: subscriber) }

  context 'When params are valid' do
    describe '#initialize' do
      before do
        allow(Aws::SES::Client).to receive(:new)
          .and_return(true)
      end

      it 'Creates object with params data' do
        expect(mail.client).to be_instance_of(Ses)
        expect(mail.template_render).to be(Vineti::Templates::Render)
        expect(mail.template_data).to eq(params['template_data'].with_indifferent_access.merge(extra_template_data))
        expect(mail.valid?).to be true
      end
    end

    describe '#send_notification_to_subscriber' do
      subject { mail.send_notification_to_subscriber(subscriber) }

      before do
        allow_any_instance_of(Aws::SES::Client)
          .to receive(:send_email)
          .and_return(
            Seahorse::Client::Response.new(data: mail_response)
          )
        allow_any_instance_of(Seahorse::Client::Response)
          .to receive(:successful?)
          .and_return(true)
        allow(SecureRandom).to receive(:uuid).and_return('abcd1234')
        Vineti::Notifications::EventTransaction.delete_all
      end

      let(:mail_response) do
        Ses.new.client.stub_data(:send_email, message_id: message_id)
      end

      it 'sends mail to email subscribers and created success log' do
        expect(subject.response.message_id).to eq(message_id)
        response = Vineti::Notifications::NotificationEmailResponse::SuccessResponse.last
        log = Vineti::Notifications::NotificationEmailLog.last
        expect(log.event).not_to be nil
        expect(log.subscriber).not_to be nil
        expect(response.email_log).to eq(log)
      end

      it 'persist in event_transaction table' do
        expect { subject }.to change(Vineti::Notifications::EventTransaction, :count).by(1)
        event_transaction = Vineti::Notifications::EventTransaction.last
        expect(event_transaction.transaction_id).to eq('abcd1234')
        expect(event_transaction.status).to eq('SUCCESS')
      end

      it 'adds deeplinks in template data' do
        subject
        expect(mail.template_data[:deep_link_for_step_1]).to eq('/workflow/1/3')
      end

      context 'with JSONAPI template data' do
        # Sample data from https://vineti.atlassian.net/browse/CGT-3936
        let(:json_file_name) { 'complex-email-template-data.json' }
        let(:extra_template_data) { { 'base_url' => 'https://example.com', 'notification_email_address' => 'hi@vineti.com' } }
        let(:rendered_text) { subject&.text&.dig(:text, :data) }
        let(:rendered_html) { subject&.text&.dig(:html, :data) }
        let(:default_variables) do
          {
            current_value: 'meta.data_change.1',
          }
        end
        let(:template) do
          FactoryBot.create(:notification_template,
                            html_body: raw_template,
                            text_body: raw_template,
                            default_variables: default_variables)
        end

        context 'when get helper is used' do
          let(:raw_template) do
            <<~TEMPLATE
              New Order
              Study Number: {{ 'meta.procedure.data.relationships.treatment.data.relationships.study_number.data.attributes.name' | get}}
              Institution Number: {{ 'meta.procedure.data.attributes.institution_id' | get}}
              Institution Name: {{ 'meta.procedure.data.relationships.institution.data.attributes.name' | get}}
              Institution Country: {{ 'meta.procedure.data.relationships.institution.data.relationships.addresses.data.0.attributes.country' | get}}
              Subject Number: {{ 'meta.procedure.data.relationships.treatment.data.attributes.subject_number' | get}}
              COI#: {{ 'meta.procedure.data.relationships.treatment.data.attributes.coi' | get}}
              Apheresis scheduled for {{ 'meta.procedure.data.relationships.treatment.data.attributes.schedules.apheresis_date_jnj68284528_jnj_2003eu.date' | get}} for Subject Number {{'meta.procedure.data.relationships.treatment.data.attributes.subject_number' | get}}.
              See order status here: <a href="{{base_url}}/order_status_tracking/{{ 'meta.procedure.data.relationships.treatment.data.id' | get}}">Order Status</a>
              If needed, please contact us at {{notification_email_address}}
              Change data: {{ current_value | get }}
              The Team,
              Vineti
            TEMPLATE
          end
          let(:rendered_template) do
            <<~EMAIL
              New Order
              Study Number: 68284528MMY2003
              Institution Number: 5
              Institution Name: Test Institution 1
              Institution Country: US
              Subject Number: 6747
              COI#: JNJ.XKNAA8.77B.5
              Apheresis scheduled for 2020-02-08T18:00:00Z for Subject Number 6747.
              See order status here: <a href="https://example.com/order_status_tracking/2">Order Status</a>
              If needed, please contact us at hi@vineti.com
              Change data: 02-Jun-2020
              The Team,
              Vineti
            EMAIL
          end

          it 'renders text and html body', aggregate_failures: true do
            expect(subject.class).to eq(Vineti::Notifications::Subscriber::EmailResponse)
            expect(rendered_text).to eq(rendered_template)
            expect(rendered_html).to eq(rendered_template)
          end
        end

        context 'when formatTime helpers is used with get' do
          let(:raw_template) do
            <<~TEMPLATE
              New Order
              Study Number: {{ 'meta.procedure.data.relationships.treatment.data.relationships.study_number.data.attributes.name' | get}}
              Institution Number: {{ 'meta.procedure.data.attributes.institution_id' | get}}
              Institution Name: {{ 'meta.procedure.data.relationships.institution.data.attributes.name' | get}}
              Institution Country: {{ 'meta.procedure.data.relationships.institution.data.relationships.addresses.data.0.attributes.country' | get}}
              Subject Number: {{ 'meta.procedure.data.relationships.treatment.data.attributes.subject_number' | get}}
              COI#: {{ 'meta.procedure.data.relationships.treatment.data.attributes.coi' | get}}
              Apheresis scheduled for {{ 'meta.procedure.data.relationships.treatment.data.attributes.schedules.apheresis_date_jnj68284528_jnj_2003eu.date' | get | formatTime: '%I:%M%p' }} for Subject Number {{ 'meta.procedure.data.relationships.treatment.data.attributes.subject_number' | get}}.
              See order status here: <a href="{{base_url}}/order_status_tracking/{{ 'meta.procedure.data.relationships.treatment.data.id' | get}}">Order Status</a>
              If needed, please contact us at {{notification_email_address}}
              The Team,
              Vineti
            TEMPLATE
          end
          let(:rendered_template) do
            <<~EMAIL
              New Order
              Study Number: 68284528MMY2003
              Institution Number: 5
              Institution Name: Test Institution 1
              Institution Country: US
              Subject Number: 6747
              COI#: JNJ.XKNAA8.77B.5
              Apheresis scheduled for 06:00PM for Subject Number 6747.
              See order status here: <a href="https://example.com/order_status_tracking/2">Order Status</a>
              If needed, please contact us at hi@vineti.com
              The Team,
              Vineti
            EMAIL
          end

          it 'renders text body' do
            expect(rendered_text).to eq(rendered_template)
          end

          it 'renders html body' do
            expect(rendered_html).to eq(rendered_template)
          end
        end

        context 'when liquid template is used' do
          let(:schedules_string) do
            "meta.procedure.data.relationships.treatment.data.attributes.schedules"
          end

          let(:apheresis_date_string) do
            "meta.procedure.data.relationships.treatment.data.attributes.schedules.apheresis_date_jnj68284528_jnj_2003eu.date"
          end

          let(:schedules_json) do
            template_data
              .with_indifferent_access
              .dig(:meta, :procedure, :included)
              .find { |included| included[:type] == 'treatments' }
              .dig(:attributes, :schedules)
              .to_json
          end

          let(:default_variables) do
            {
              schedules: schedules_string,
              apheresis_date: apheresis_date_string,
              current_value: 'meta.data_change.1',
            }
          end

          let(:raw_template) do
            <<~RAW_TEMPLATE
              F O R M A T  T I M E example:\n
              {{  apheresis_date | get | formatTime: '%Y-%m-%d' }}\n
              S T R I N G I F Y Example:\n
              {{ apheresis_date | get | stringify }}\n
              J S O N example:\n
              {{ schedules | get | json }}\n
              A R R A Y example:\n
              {{ current_value | get }}\n
            RAW_TEMPLATE
          end

          let(:rendered_template) do
            <<~RENDERED_TEMPLATE
              F O R M A T  T I M E example:\n
              2020-02-08\n
              S T R I N G I F Y Example:\n
              2020-02-08T18:00:00Z\n
              J S O N example:\n
              #{schedules_json}\n
              A R R A Y example:\n
              02-Jun-2020\n
            RENDERED_TEMPLATE
          end

          it 'renders text body' do
            expect(rendered_text).to eq(rendered_template)
          end

          it 'renders html body' do
            expect(rendered_html).to eq(rendered_template)
          end
        end
      end
    end

    describe '#send_notification_to_subscriber with delayed_time params' do
      context 'When valid delayed time is provided' do
        let(:delayed_time) { '5' }

        before do
          allow(Aws::SES::Client).to receive(:new).and_return(true)
        end

        it 'queues the job' do
          email_service = described_class.new(topic: event, template_data: template_data, delayed_time: delayed_time)

          ActiveJob::Base.queue_adapter = :test
          expect { email_service.send_notification_to_subscriber(subscriber) }.to have_enqueued_job(Vineti::Notifications::NotificationMailJob)
        end
      end
    end

    describe '#send_notification_to_subscriber with metadata params' do
      subject { mail.send_notification_to_subscriber(subscriber) }

      context 'When valid metadata is provided' do
        let(:metadata) { { procedure_name: 'Procedure::Ordering', step_name: 'patient', treatment_id: 1 } }

        it 'records email notification sent event' do
          expected_keys = %i[from_address to_addresses cc_addresses event_transaction_id template_name subscriber_id procedure_name step_name treatment_id]
          expect(::Event::EmailNotificationSent).to receive(:record).with(event_details: hash_including(*expected_keys))

          subject
        end
      end

      context 'When metadata does not contain all required keys' do
        let(:metadata) { { procedure_name: 'Procedure::Ordering', step_name: 'patient' } }

        context 'when metabase is missing any keys' do
          it 'does not record email notification sent event' do
            expect(::Event::EmailNotificationSent).not_to receive(:record)
            subject
          end
        end

        context 'when metabase is blank' do
          let(:metadata) { {} }

          it 'does not record email notification sent event' do
            expect(::Event::EmailNotificationSent).not_to receive(:record)
            subject
          end
        end
      end
    end

    describe '#send_notification' do
      subject { mail.send_notification }

      before do
        allow_any_instance_of(Aws::SES::Client).to receive(:send_email).and_return(Seahorse::Client::Response.new(data: mail_response))
        allow_any_instance_of(Seahorse::Client::Response).to receive(:successful?).and_return(true)
      end

      let(:mail_response) do
        Ses.new.client.stub_data(:send_email, message_id: message_id)
      end

      it 'sends mail to email subscribers and created success log' do
        expect(subject.last.response.message_id).to eq(message_id)
        response = Vineti::Notifications::NotificationEmailResponse::SuccessResponse.last
        log = Vineti::Notifications::NotificationEmailLog.last
        expect(log.event).not_to be nil
        expect(log.subscriber).not_to be nil
        expect(response.email_log).to eq(log)
      end

      it 'adds deep links in template_data variable' do
        subject
        expect(mail.template_data[:deep_link_for_step_1]).to eq('/workflow/1/3')
      end
    end
  end

  context 'When params are invalid' do
    let(:ses) { double("aws_ses") }

    before do
      allow(Aws::SES::Client).to receive(:new).and_return(ses)
    end

    describe '#send_notification_to_subscriber' do
      subject { mail.send_notification_to_subscriber(subscriber) }

      before do
        @time_now = Time.now.utc
        allow(Time).to receive_message_chain(:now, :utc).and_return(@time_now)
        allow(ses).to receive(:send_email).and_raise(
          Aws::SES::Errors::MessageRejected.new(
            Seahorse::Client::RequestContext,
            'Message Rejected'
          )
        )
        allow(SecureRandom).to receive(:uuid).and_return('efgh1234')
        Vineti::Notifications::EventTransaction.delete_all
      end

      it 'Logs the error when email gets fail' do
        subject
        log = Vineti::Notifications::NotificationEmailLog.last
        email_response = Vineti::Notifications::NotificationEmailResponse::Base.last
        expect(email_response.email_log).to eq(log)
        expect(email_response.response.keys).to eq(%w[error backtrace mail_body])
      end

      it 'persist in event_transaction table' do
        expect { subject }.to change(Vineti::Notifications::EventTransaction, :count).by(1)
        event_transaction = Vineti::Notifications::EventTransaction.last
        expect(event_transaction.transaction_id).to eq('efgh1234')
        expect(event_transaction.status).to eq('ERROR')
      end

      it 'adds deeplinks in template_data' do
        subject
        expect(mail.template_data[:deep_link_for_step_1]).to eq('/workflow/1/3')
      end

      describe 'When template data is wrong or not an object' do
        let(:mail) { described_class.new(topic: event, template_data: template_data) }
        let(:template_data) { '' }

        it 'is invalid' do
          expect(mail.valid?).to be false
          expect(mail.errors.full_messages).to include('Template data missing JSONAPI key "meta"', 'Template data missing JSONAPI key "data"')
        end

        context 'when template data is not JSONAPI format' do
          let(:template_data) { {} }

          it 'is invalid' do
            expect(mail.valid?).to be false
            expect(mail.errors.full_messages).to include('Template data missing JSONAPI key "meta"', 'Template data missing JSONAPI key "data"')
          end
        end
      end
    end

    describe '#send_notification' do
      subject { mail.send_notification }

      before do
        freeze_time
        allow(ses).to receive(:send_email).and_raise(
          Aws::SES::Errors::MessageRejected.new(
            Seahorse::Client::RequestContext,
            'Message Rejected'
          )
        )
      end

      after { travel_back }

      it 'Logs the error when email gets fail' do
        subject
        log = Vineti::Notifications::NotificationEmailLog.last
        email_response = Vineti::Notifications::NotificationEmailResponse::Base.last
        expect(email_response.email_log).to eq(log)
        expect(email_response.response.keys).to eq(%w[error backtrace mail_body])
        expect(mail.template_data[:deep_link_for_step_1]).to eq('/workflow/1/3')
      end

      describe 'when template parsing throws error' do
        before do
          dbl = double
          allow(Vineti::Templates::Render).to receive(:factory).and_return(dbl)
          allow(dbl).to receive(:call!).and_raise('Variable missing')
        end

        it 'rescue the running process and update event transaction with the error status' do
          subject
          event_transaction = Vineti::Notifications::EventTransaction.last
          expect(event_transaction.status).to eq('ERROR')
          expect(event_transaction.subscriber).to eq(subscriber)
        end

        it 'log error in email responses table' do
          subject
          log = Vineti::Notifications::NotificationEmailLog.last
          email_response = Vineti::Notifications::NotificationEmailResponse::Base.last
          expect(email_response.email_log).to eq(log)
          expect(email_response.response['error']).to eq('Variable missing')
        end
      end

      describe '#send_notification with inavalid delayed_time params' do
        let(:delayed_time) { 'abc' }

        it 'Raises runtime error' do
          expect do
            described_class.new(topic: event, template_data: template_data, delayed_time: delayed_time)
          end.to raise_error('invalid value for Integer(): "abc"')
        end
      end
    end
  end
end
