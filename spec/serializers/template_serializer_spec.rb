require 'rails_helper'

describe TemplateSerializer do
  subject { described_class.new(object: template).as_jsonapi[:attributes] }

  let(:template) { FactoryBot.create(:notification_template) }

  it 'returns serialized atrributes from record passed' do
    expect(subject.keys).to eq(%i[template_id default_variables data subscribers])
    expect(subject[:template_id]).to eq(template.template_id)
  end
end
