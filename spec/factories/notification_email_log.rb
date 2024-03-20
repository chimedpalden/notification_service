FactoryBot.define do
  factory :notification_email_log, class: 'Vineti::Notifications::NotificationEmailLog' do
    event { FactoryBot.create(:event) }
    publisher { FactoryBot.create(:publisher) }
    template { FactoryBot.create(:notification_template) }
    subscriber { FactoryBot.create(:email_subscriber) }
    email_message { { source: 'admin@vineti.com', mail_body: {}, error: nil } }

    trait :without_event do
      event { nil }
    end

    trait :without_email_template do
      template { nil }
    end

    trait :without_email_subscriber do
      subscriber { nil }
    end

    trait :with_error_message do
      email_message { { source: nil, destination: nil, mail_body: nil, error: 'Error Message' } }
    end
  end
end
