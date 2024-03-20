FactoryBot.define do
  factory :internal_api_subscriber, class: 'Vineti::Notifications::Subscriber::InternalApiSubscriber' do
    subscriber_id { "internal-subscriber-#{Faker::Lorem.characters(15)}" }
  end
end
