# frozen_string_literal: true

require 'rails_helper'
describe Vineti::Notifications::TemplatesController, type: :controller do
  routes { Vineti::Notifications::Engine.routes }

  before do
    allow_any_instance_of(Vineti::Notifications::AuthHelper).to receive(:validate_user_permissions).and_return(true)
  end

  context 'When user is not logged in' do
    let(:error) { { 'errors' => ['You need to sign in or sign up before continuing.'] } }

    describe 'GET#index' do
      subject { get :index }

      it 'Returns 401 unauthorized error' do
        subject
        expect(JSON.parse(response.body)).to eq(error)
      end
    end

    describe 'GET#show' do
      subject { get :show, params: { template_id: template.template_id } }

      let(:template) { FactoryBot.create(:template_with_variables) }

      it 'Returns 401 unauthorized error' do
        subject
        expect(JSON.parse(response.body)).to eq(error)
      end
    end

    describe 'POST#create' do
      subject { post :create }

      it 'Returns 401 unauthorized error' do
        subject
        expect(JSON.parse(response.body)).to eq(error)
      end
    end

    describe 'PUT#update' do
      subject { patch :update, params: { template_id: template.template_id } }

      let(:template) { FactoryBot.create(:template_with_variables) }

      it 'Returns 401 unauthorized error' do
        subject
        expect(JSON.parse(response.body)).to eq(error)
      end
    end

    describe 'DELETE#destroy' do
      subject { delete :destroy, params: { template_id: template.template_id } }

      let(:template) { FactoryBot.create(:template_with_variables) }

      it 'Returns 401 unauthorized error' do
        subject
        expect(JSON.parse(response.body)).to eq(error)
      end
    end
  end

  context 'When user is signed in' do
    before do
      api_sign_in admin, request
    end

    let(:admin) { FactoryBot.create(:system_user) }

    describe 'GET#index' do
      subject(:make_request) { get :index }

      it 'gets list of existing templates' do
        templates = FactoryBot.create_list(:template_with_variables, 2)

        expected_json = {
          data: [
            {
              id: templates.first.id.to_s,
              type: 'template',
              attributes: {
                template_id: templates.first.template_id,
                default_variables: {
                  variable1: "default_variables1",
                  variable2: "default_variables2",
                  variable3: "default_variables3",
                  variable4: "default_variables4",
                },
                data: {
                  subject: templates.first["data"]["subject"],
                  html_body: templates.first["data"]["html_body"],
                  text_body: templates.first["data"]["text_body"],
                },
                subscribers: [],
              },
            },
            {
              id: templates.last.id.to_s,
              type: 'template',
              attributes: {
                template_id: templates.last.template_id,
                default_variables: {
                  variable1: "default_variables1",
                  variable2: "default_variables2",
                  variable3: "default_variables3",
                  variable4: "default_variables4",
                },
                data: {
                  subject: templates.last["data"]["subject"],
                  html_body: templates.last["data"]["html_body"],
                  text_body: templates.last["data"]["text_body"],
                },
                subscribers: [],
              },
            },
          ],
          jsonapi: {
            version: '1.0',
          },
        }.to_json

        make_request
        expect(response.body).to eq(expected_json)
        expect(response.status).to be(200)
      end
    end

    describe 'POST#create' do
      let(:new_template) { FactoryBot.build(:notification_template) }

      context 'When Template is created successfully' do
        subject(:make_request) do
          post :create, params: {
            template: {
              template_id: new_template.template_id,
              default_variables: {
                variable: "default_variables",
              },
              data: {
                subject: 'Checking Template Creation with {{variable}}',
                text_body: 'Check template creation',
                html_body: '<p>Check Template Creation</p>',
              },
            },
          }
        end

        it 'returns attributes of created template' do
          make_request

          response_data = JSON.parse(response.body)['data']['attributes']
          expect(response_data['template_id']).to eq(new_template.template_id)
          expect(response_data['data']['subject']).to eq('Checking Template Creation with {{variable}}')
          expect(response_data['data']['text_body']).to eq('Check template creation')
          expect(response_data['data']['html_body']).to eq('<p>Check Template Creation</p>')
          expect(response_data['default_variables']).to eq("variable" => "default_variables")
          expect(response.status).to be(200)
        end
      end

      context 'When creation get failed' do
        subject(:make_request) do
          post :create, params: {
            template: {
              default_variables: {
                variable: "default_variables",
              },
              data: {
                subject: 'Checking Template Creation with {{variable}}',
                text_body: 'Check template creation',
                html_body: '<p>Check Template Creation</p>',
              },
            },
          }
        end

        it 'returns status 400' do
          make_request
          expect(response.status).to eq(400)
        end
      end
    end

    describe 'PUT#update' do
      let(:template) { FactoryBot.create(:notification_template) }

      context 'When Template is updated successfully' do
        subject(:make_request) do
          put :update, params: {
            template_id: template.template_id,
            template: {
              data: {
                subject: 'New subject',
                text_body: 'New text body',
                html_body: '<p>New text body<p>',
              },
            },
          }
        end

        it 'returns attributes of updated template' do
          make_request

          response_data = JSON.parse(response.body)['data']['attributes']
          expect(response_data['template_id']).to eq(template.template_id)
          expect(response_data['data']['subject']).to eq('New subject')
          expect(response_data['data']['text_body']).to eq('New text body')
          expect(response_data['data']['html_body']).to eq('<p>New text body<p>')
          expect(response.status).to be(200)
        end
      end

      context 'When updation get failed' do
        subject(:make_request) do
          put :update, params: {
            template_id: template.template_id,
            template: { template_id: nil },
          }
        end

        it 'returns status 400' do
          make_request
          expect(response.status).to eq(400)
        end
      end
    end

    describe 'DELETE#destroy' do
      let(:template) { FactoryBot.create(:notification_template) }

      context 'When Template is deleted successfully' do
        subject(:make_request) do
          delete :destroy, params: { template_id: template.template_id }
        end

        it 'returns attributes of deleted template' do
          make_request

          response_data = JSON.parse(response.body)['data']['attributes']
          expect(response_data['template_id']).to eq(template.template_id)
          expect(response_data['data']['subject']).to eq(template.data['subject'])
          expect(response_data['data']['text_body']).to eq(template.data['text_body'])
          expect(response_data['data']['html_body']).to eq(template.data['html_body'])
          expect(response.status).to be(200)
        end
      end

      context 'When template is not found' do
        subject(:make_request) do
          delete :destroy, params: { template_id: SecureRandom.hex(16) }
        end

        it 'returns 404' do
          make_request
          expect(response.status).to eq(404)
        end
      end
    end

    describe 'GET#show' do
      subject(:make_request) do
        get :show, params: { template_id: template_name_param }
      end

      let(:template) { FactoryBot.create(:template_with_variables) }

      context 'When template is present' do
        let(:template_name_param) { template.template_id }

        it 'Renders template attribtues' do
          make_request

          response_data = JSON.parse(response.body)['data']['attributes']
          expect(response_data['data']['subject']).to eq(template.data['subject'])
          expect(response_data['data']['text_body']).to eq(template.data['text_body'])
          expect(response_data['data']['html_body']).to eq(template.data['html_body'])
          expect(response_data['default_variables']).to eq(
            "variable1" => "default_variables1",
            "variable2" => "default_variables2",
            "variable3" => "default_variables3",
            "variable4" => "default_variables4"
          )
        end
      end

      context 'When template is missing' do
        let(:template_name_param) { SecureRandom.hex(16) }

        it 'returns 404' do
          make_request
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
