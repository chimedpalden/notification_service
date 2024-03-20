FactoryBot.define do
  factory :success_response, class: 'Vineti::Notifications::NotificationEmailResponse::SuccessResponse' do
    email_log { FactoryBot.create(:notification_email_log) }
    response do
      {
        message_id: 'abc_123',
        mail_body: { subject: 'test subject', body: {} },
      }
    end

    trait :without_message_id do
      response { { success_message: 'Email Sent' } }
    end

    trait :without_log_reference do
      email_log { nil }
    end
  end
end
