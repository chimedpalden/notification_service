FactoryBot.define do
  factory :publisher, class: 'Vineti::Notifications::Publisher' do
    publisher_id { Faker::Lorem.characters(15) }
    template { FactoryBot.create(:notification_template) }
    data { { token: "test123#{Faker::Lorem.characters(15)}" } }

    trait :without_id do
      publisher_id { nil }
    end

    trait :without_template do
      template { nil }
    end

    trait :without_token do
      data { {} }
    end

    trait :liquid_template_with_variables do
      template { FactoryBot.create(:publisher_template, :with_liquid_variables) }
    end

    trait :liquid_template_without_variables do
      template { FactoryBot.create(:publisher_template, :without_variables) }
    end
  end
end
