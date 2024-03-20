require 'rails_helper'

describe 'Vineti::Notifications::Template', type: :model do
  context 'validation' do
    subject { template.valid? }

    describe 'When subject is missing from the JSON data' do
      let(:template) { FactoryBot.create(:invalid_template, :without_subject) }

      it 'Raises validation error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe 'When text body missing from JSON data' do
      let(:template) { FactoryBot.create(:invalid_template, :without_text_body) }

      it 'Raises validation error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe 'When html body is missing from JSON data' do
      let(:template) { FactoryBot.create(:notification_template, :without_html_body) }

      it 'returns true' do
        expect(subject).to be true
      end
    end
  end
end
