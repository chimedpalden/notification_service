require 'rails_helper'

module Vineti::Notifications
  RSpec.describe Publisher, type: :model do
    let(:publisher) { FactoryBot.build(:publisher) }
    let(:publisher_without_id) { FactoryBot.build(:publisher, :without_id) }
    let(:publisher_without_template) { FactoryBot.build(:publisher, :without_template) }
    let(:publisher_without_token) { FactoryBot.build(:publisher, :without_token) }

    describe 'Checks if object is validated' do
      it 'Passes validation if publisher_id is present' do
        expect(publisher.valid?).to be true
      end

      it 'Fails validation if publisher_id is empty' do
        expect(publisher_without_id.valid?).to be false
      end

      it 'Fails validation if template is empty' do
        expect(publisher_without_template.valid?).to be false
      end

      it 'Fails validation if token attribute is missing in data' do
        expect(publisher_without_token.valid?).to be false
      end

      context 'when token is already associated with other publisher' do
        before { FactoryBot.create(:publisher, data: { token: "test123" }) }

        it 'Fails validation' do
          expect { FactoryBot.create(:publisher, data: { token: "test123" }) }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end
end
