FactoryBot.define do
  factory :notification_template, class: 'Vineti::Notifications::Template' do
    sequence :template_id do |n|
      "Template_Number:_#{SecureRandom.hex(3)}_#{n}"
    end

    data do
      {
        'subject' => subject,
        'html_body' => html_body,
        'text_body' => text_body,
      }
    end

    default_variables { nil }

    transient do
      html_body { "<p>Template Body: #{SecureRandom.hex(3)}</p>" }
      text_body { "Template Body: #{SecureRandom.hex(3)}" }
      subject { "Template Subject: #{SecureRandom.hex(3)}" }
    end

    trait :without_html_body do
      data do
        {
          'subject' => "Template Subject: #{SecureRandom.hex(3)} {{variable2}}",
          'text_body' => "Template Body:{{variable4}} #{SecureRandom.hex(3)} {{variable2}}",
        }
      end
    end
  end

  factory :template_with_variables, class: 'Vineti::Notifications::Template' do
    sequence :template_id do |n|
      "Introduction #{SecureRandom.hex(3)}_#{n}"
    end
    data do
      {
        'subject' => "Template Subject: #{SecureRandom.hex(3)} {{variable2}}",
        'html_body' => "<p>Template Body: {{variable1}} #{SecureRandom.hex(3)}</p> {{variable3}}",
        'text_body' => "Template Body:{{variable4}} #{SecureRandom.hex(3)} {{variable2}}",
      }
    end
    default_variables do
      {
        'variable1' => "default_variables1",
        'variable2' => "default_variables2",
        'variable3' => "default_variables3",
        'variable4' => "default_variables4",
      }
    end
  end

  factory :publisher_template, class: 'Vineti::Notifications::Template' do
    sequence :template_id do |id|
      "Template ID #{SecureRandom.hex(3)}_#{id}"
    end

    default_variables do
      {
        'metadata' => {
          'coi' => '1234.ABCD.543.E',
        },
      }
    end

    trait :with_liquid_variables do
      data do
        {
          "subject" => "Order with COI {{ 'metadata.coi' | get }} is updated",
          'text_body' => {
            updated_date: "{{ 'metadata.date' | get | formatTime: '%m-%d-%Y' }} UTC",
          },
          'type' => 'json',
        }
      end
    end

    trait :without_variables do
      data do
        {
          "subject" => "Order with COI is updated",
          'text_body' => "Order updated",
        }
      end
    end
  end

  factory :template_with_default_variables, class: 'Vineti::Notifications::Template' do
    sequence :template_id do |n|
      "Introduction #{SecureRandom.hex(3)}_#{n}"
    end

    data do
      {
        "subject" => "This is how {{subject}} with variable will look like",
        "text_body" => "This is sample text, and you can add variables using handlebar like this {{variable}}",
        "html_body" =>
        "Also you can add a html like anchor tag as <a href={{link}}/{{order_id}}>"\
        "{{link_text}}</a>\n<br />\nLink to the Prescriber step - <a href={{deep_link_for_step_1}}>"\
        "{{link_text}}</a>\n<br />\nLink to the Ordering Site step - <a href={{deep_link_for_step_2}}>{{link_text}}</a>",
      }
    end
    default_variables do
      {
        'subject': 'test',
        'link': 'www.google.com',
        'link_text': 'this',
        'deep_link_for_step_1': 'prescriber',
        'deep_link_for_step_2': 'ordering_site',
      }
    end
    deeplinks do
      {
        'deep_link_for_step_1' => 'prescriber',
      }
    end
  end

  factory :invalid_template, class: 'Vineti::Notifications::Template' do
    sequence :template_id do |n|
      "Fake #{SecureRandom.hex(3)}_#{n}"
    end

    trait :without_subject do
      data do
        {
          'html_body' => "<p>Template Body: {{variable1}} #{SecureRandom.hex(3)}</p> {{variable3}}",
          'text_body' => "Template Body:{{variable4}} #{SecureRandom.hex(3)} {{variable2}}",
        }
      end
    end

    trait :without_text_body do
      data do
        {
          'subject' => "Template Subject: #{SecureRandom.hex(3)} {{variable2}}",
          'html_body' => "<p>Template Body: {{variable1}} #{SecureRandom.hex(3)}</p> {{variable3}}",
        }
      end
    end
  end
end
