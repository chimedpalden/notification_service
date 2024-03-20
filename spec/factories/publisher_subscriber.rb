FactoryBot.define do
  factory :publisher_subscriber, class: 'Vineti::Notifications::PublisherSubscriber' do
    publisher { FactoryBot.create(:publisher) }
    subscriber { FactoryBot.create(:email_subscriber) }

    trait :without_publisher do
      publisher { nil }
    end

    trait :without_subscriber do
      subscriber { nil }
    end
  end
end
