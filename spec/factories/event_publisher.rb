FactoryBot.define do
  factory :event_publisher, class: 'Vineti::Notifications::EventPublisher' do
    event { FactoryBot.create(:event) }
    publisher { FactoryBot.create(:publisher) }

    trait :without_event do
      event { nil }
    end

    trait :without_publisher do
      publisher { nil }
    end
  end
end
