FactoryBot.define do
  factory :event_transaction, class: 'Vineti::Notifications::EventTransaction' do
    transaction_id { SecureRandom.uuid }
    subscriber { FactoryBot.create(:webhook_subscriber) }
    trait :without_event do
      transaction_id { nil }
    end
    trait :without_subscriber do
      subscriber { nil }
    end

    trait :with_publisher do
      publisher { FactoryBot.create(:publisher) }
      subscriber { nil }
    end

    trait :with_event do
      event { FactoryBot.create(:event) }
      subscriber { nil }
    end
  end
end
