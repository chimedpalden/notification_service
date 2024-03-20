require 'rails_helper'

describe Wso2 do
  before(:each) do
    allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('wso2_tenant_base_url').and_return(wso2_tenant_base_url)
    allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('wso2_tenant').and_return(wso2_tenant)
    allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('wso2_events_api').and_return(wso2_events_api)
    allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('wso2_oauth2_client_id').and_return('xyz')
    allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('wso2_oauth2_client_secret').and_return('abc')
    allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('wso2_oauth2_token_url').and_return('/bar')
    allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('wso2_oauth2_auth_scheme').and_return('basic_auth')
  end

  let(:wso2) { Wso2.new }
  let(:oauth_token) do
    {
      "Authorization" => "Bearer 5a48706e-c3e1-9d18-f254b46aaadf",
    }
  end

  let(:wso2_tenant_base_url) { 'https://foo.com/t' }
  let(:wso2_tenant) { 'bar.com' }
  let(:wso2_events_api) { 'api/event/v1/outbound-events' }

  describe '#oauth_token' do
    subject { wso2.oauth_token }

    context 'when outh token generation is successfull' do
      before do
        allow_any_instance_of(::OAuth2::Client).to receive_message_chain(:client_credentials, :get_token, :headers).and_return(oauth_token)
      end

      it 'Returns outh token' do
        expect(subject).to eq(oauth_token)
      end
    end

    context 'when oauth token generation is not successfull' do
      before do
        allow_any_instance_of(::OAuth2::Client).to receive_message_chain(:client_credentials, :get_token, :headers).and_raise('OAuth:Error')
      end

      it 'Returns error' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end
end
