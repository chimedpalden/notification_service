FactoryBot.define do
  factory :error_response, class: 'Vineti::Notifications::NotificationEmailResponse::ErrorResponse' do
    email_log { FactoryBot.create(:notification_email_log) }
    response { { error: 'Message Rejected', backtrace: [] } }

    trait :without_error do
      response { { event: 'order_created' } }
    end

    trait :without_log_reference do
      email_log { nil }
    end
  end
end
