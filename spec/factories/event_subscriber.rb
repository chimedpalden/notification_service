FactoryBot.define do
  factory :event_subscriber, class: 'Vineti::Notifications::EventSubscriber' do
    event { FactoryBot.create(:event) }
    subscriber { FactoryBot.create(:email_subscriber) }

    trait :without_event do
      event { nil }
    end

    trait :without_subscriber do
      subscriber { nil }
    end

    trait :with_webhook_subscriber do
      subscriber { FactoryBot.create(:webhook_subscriber) }
    end
  end
end
