FactoryBot.define do
  factory :system_user, class: 'User' do
    uid { email }
    name { Faker::Name.first_name }
    sequence(:email) { |i| "email#{i}#{name}@example.com" }
    password { "password" }
    password_confirmation { "password" }
  end
end
