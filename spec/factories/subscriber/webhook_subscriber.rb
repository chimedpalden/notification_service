FactoryBot.define do
  factory :webhook_subscriber, class: 'Vineti::Notifications::Subscriber::WebhookSubscriber' do
    template { FactoryBot.create(:notification_template) }
    sequence :subscriber_id do |n|
      "#{Faker::Lorem.unique.word}_group_#{n}_#{SecureRandom.hex.first(6)}"
    end

    data do
      {
        'webhook_url' => Faker::Internet.email,
        'vault_key' => SecureRandom.hex(16),
        'token_url' => 'https://externalsystem/token',
      }
    end

    after(:create) do |subscriber|
      create(:event_subscriber, subscriber: subscriber)
      subscriber.events.reload
    end

    trait :without_subscriber_id do
      subscriber_id { nil }
    end

    trait :without_webhook_url do
      data do
        {
          'vault_key' => SecureRandom.hex(16),
          'token_url' => 'https://externalsystem/token',
        }
      end
    end

    trait :without_vault_key do
      data do
        {
          'webhook_url' => Faker::Internet.email,
          'token_url' => 'https://externalsystem/token',
        }
      end
    end

    trait :without_token_url do
      data do
        {
          'webhook_url' => Faker::Internet.email,
          'vault_key' => SecureRandom.hex(16),
        }
      end
    end

    trait :with_blank_webhook_url do
      data do
        {
          'webhook_url' => '',
          'vault_key' => SecureRandom.hex(16),
          'token_url' => 'https://externalsystem/token',
        }
      end
    end

    trait :with_blank_vault_key do
      data do
        {
          'webhook_url' => 'www.example.com',
          'vault_key' => '',
          'token_url' => 'https://externalsystem/token',
        }
      end
    end

    trait :with_blank_token_url do
      data do
        {
          'webhook_url' => 'www.example.com',
          'vault_key' => SecureRandom.hex(16),
          'token_url' => '',
        }
      end
    end

    trait :without_data do
      data { nil }
    end
  end
end
