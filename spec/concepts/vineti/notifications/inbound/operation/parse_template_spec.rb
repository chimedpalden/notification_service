require 'rails_helper'

module Vineti::Notifications
  describe Inbound::Operation::ParseTemplate do
    subject { Inbound::Operation::ParseTemplate.call(publisher: publisher, template_data: template_data) }

    context 'Parsing liquid template with data' do
      let(:template_data) do
        ActionController::Parameters.new(
          'metadata' => {
            'coi' => '1234',
            'date' => date.to_s,
          }
        )
      end
      let(:date) { DateTime.now }
      let(:parsed_date) { date.strftime('%m-%d-%Y') }

      context 'When template has variables' do
        let(:publisher) { FactoryBot.create(:publisher, :liquid_template_with_variables) }

        context 'When parsing is failed' do
          let(:template_data) { ActionController::Parameters.new({}) }

          it 'returns empty value' do
            expect(subject.success?).to be true
            expect(subject[:parsed_data]).to eq('updated_date' => " UTC")
          end
        end

        context 'When  parsing is successful' do
          it 'Returns successfull response and parsed template' do
            expect(subject.success?).to be true
            expect(subject[:parsed_data]).to eq('updated_date' => "#{parsed_date} UTC")
          end
        end
      end

      context 'When template does not has variables and parsing is successful' do
        let(:publisher) { FactoryBot.create(:publisher, :liquid_template_without_variables) }

        it 'Returns successful response with parsed data' do
          expect(subject.success?).to be true
          expect(subject[:parsed_data]).to eq('data' => 'Order updated')
        end
      end
    end
  end
end
