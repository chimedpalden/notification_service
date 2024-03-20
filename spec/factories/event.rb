FactoryBot.define do
  factory :event, class: 'Vineti::Notifications::Event' do
    sequence :name do |n|
      "#{Faker::Lorem.word}_#{n}"
    end

    trait :without_name do
      name { nil }
    end

    trait :with_email_subscriber do
      after(:create) do |event|
        event.subscribers << FactoryBot.create(:email_subscriber)
      end
    end

    trait :with_webhook_subscriber do
      after(:create) do |event|
        event.subscribers << FactoryBot.create(:webhook_subscriber)
      end
    end
  end
end
