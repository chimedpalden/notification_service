require 'rails_helper'

describe Vineti::Notifications::Templates::Operation::BulkCreate do
  subject { Vineti::Notifications::Templates::Operation::BulkCreate.call(templates: params) }

  describe 'valid params' do
    let(:params) do
      [
        {
          'template_id' => 'personalized_email',
          'data' => {
            'subject' => 'This is how {{subject}} with variable will look like',
            'text_body' => 'This is sample text',
            'html_body' => 'Also you can add a html like anchor tag ',
          },
          'deeplinks' => {
            'deep_link_for_step_1' => 'prescriber',
            'deep_link_for_step_2' => 'ordering_site',
            'deep_link_for_step_3' => 'active',
            'deep_link_for_step_4' => 'current',
          },
          'default_variables' => {
            'subject' => 'test',
            'link' => 'www.google.com',
            'link_text' => 'this',
          },
        },
        {
          'template_id' => 'print_fail',
          'data' => {
            'subject' => 'Printing failure when printing {{label}}',
            'text_body' => 'This email is to notify you that printing failed on {{label}}',
            'html_body' => 'More details can be found <a href={{link}}>{{link_text}}</a>',
          },
          'default_variables' => {
            'label' => 'LABEL',
            'link' => 'www.google.com',
            'link_text' => 'here',
          },
        },
        {
          'template_id' => 'sample_publisher_template',
          'data' => {
            'type' => 'json',
            'text_body' => "{\n  site: {{ 'site_number' | get }},\n  weight: {{ patient_weight }},\n  procedure: {{ procedure }}\n}\n",
          },
          'default_variables' => {
            'patient_weight' => 'test',
            'procedure' => 'Procedure::Ordering',
            'site_number' => 'data.site_number',
          },
        },
      ]
    end

    it 'creates the templates' do
      expect { subject }.to change(Vineti::Notifications::Template, :count).from(0).to(3)
    end

    it 'returns a 201 status' do
      response = subject
      expect(response[:status]).to eq(201)
    end
  end

  describe 'invalid params' do
    describe 'not an array' do
      let(:params) do
        { template_id: 'some string' }
      end

      it 'returns an error' do
        response = subject
        expect(response[:status]).to eq(422)
        expect(response[:errors][:message]).to eq('content is invalid')
      end
    end

    describe 'invalid keys' do
      let(:params) do
        [
          { template_id: 'some string', subject: 'some string' },
          { other_key: 'wrong value', data: { something: 'a value' } },
        ]
      end

      it 'returns an error' do
        response = subject
        expect(response[:status]).to eq(422)
        expect(response[:errors][:message]).to eq('content is invalid')
      end
    end

    describe 'data has invalid keys' do
      let(:params) do
        [
          { template_id: 'some string', data: { something: 'a value' } },
        ]
      end

      it 'returns an error' do
        response = subject
        expect(response[:status]).to eq(422)
        expect(response[:errors][:message]).to eq('content is invalid')
      end
    end

    describe 'deeplinks is not a hash' do
      let(:params) do
        [
          { template_id: 'some string', data: { to_address: 'a value' }, deeplinks: 'wrong' },
        ]
      end

      it 'returns an error' do
        response = subject
        expect(response[:status]).to eq(422)
        expect(response[:errors][:message]).to eq('content is invalid')
      end
    end

    describe 'default_variables is not a hash' do
      let(:params) do
        [
          { template_id: 'some string', data: { to_address: 'a value' }, default_variables: 'wrong' },
        ]
      end

      it 'returns an error' do
        response = subject
        expect(response[:status]).to eq(422)
        expect(response[:errors][:message]).to eq('content is invalid')
      end
    end
  end
end
