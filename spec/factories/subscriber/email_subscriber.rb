FactoryBot.define do
  factory :email_subscriber, class: 'Vineti::Notifications::Subscriber::EmailSubscriber' do
    template { FactoryBot.create(:notification_template) }
    sequence :subscriber_id do |n|
      "#{Faker::Lorem.word}_group_#{n}_#{SecureRandom.hex.first(6)}"
    end
    data do
      {
        'from_address' => Faker::Internet.email,
        'to_addresses' => [Faker::Internet.email, Faker::Internet.email],
        'cc_addresses' => [Faker::Internet.email, Faker::Internet.email],
      }
    end
    after(:create) do |subscriber|
      create(:event_subscriber, subscriber: subscriber)
      subscriber.events.reload
    end

    trait :without_subscriber_id do
      subscriber_id { nil }
    end

    trait :with_invalid_template do
      template { nil }
    end

    trait :without_from_address do
      data do
        {
          'to_addresses' => [Faker::Internet.email, Faker::Internet.email],
          'cc_addresses' => [Faker::Internet.email, Faker::Internet.email],
        }
      end
    end

    trait  :with_invalid_from_address do
      data do
        {
          'from_address' => 'test@',
          'to_addresses' => [Faker::Internet.email, Faker::Internet.email],
          'cc_addresses' => [Faker::Internet.email, Faker::Internet.email],
        }
      end
    end

    trait :without_to_addresses do
      data do
        {
          'from_address' => Faker::Internet.email,
          'cc_addresses' => [Faker::Internet.email, Faker::Internet.email],
        }
      end
    end

    trait :with_to_addresses_as_empty_array do
      data do
        {
          'from_address' => Faker::Internet.email,
          'to_addresses' => [],
          'cc_addresses' => [Faker::Internet.email, Faker::Internet.email],
        }
      end
    end

    trait :with_invalid_to_addresses do
      data do
        {
          'from_address' => Faker::Internet.email,
          'to_addresses' => [nil, 'test@'],
          'cc_addresses' => [Faker::Internet.email, Faker::Internet.email],
        }
      end
    end

    trait :with_invalid_cc_addresses do
      data do
        {
          'from_address' => Faker::Internet.email,
          'to_addresses' => [Faker::Internet.email, Faker::Internet.email],
          'cc_addresses' => [nil, 'test@'],
        }
      end
    end
  end
end
