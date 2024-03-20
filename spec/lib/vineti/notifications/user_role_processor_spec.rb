require 'rails_helper'

module Vineti::Notifications
  describe UserRoleProcessor do
    describe '.fetch_users_from_role' do
      subject { UserRoleProcessor.fetch_users_from_role(data) }

      before do
        response = OpenStruct.new(success?: true)
        response[:user_emails] = ['developer@vineti.com']
        allow(UserRoleProcessor).to receive(:fetch_user_emails).and_return(response)
      end

      let(:data) do
        {
          'to_addresses' => ['test_user@vineti.com', 'developer'],
          'cc_addresses' => ['developer'],
          'bcc_addresses' => ['developer'],
        }
      end

      it 'returns the emails from role passed' do
        expect(subject['to_addresses']).to eq(['test_user@vineti.com', 'developer@vineti.com'])
        expect(subject['cc_addresses']).to eq(['developer@vineti.com'])
        expect(subject['bcc_addresses']).to eq(['developer@vineti.com'])
      end
    end
  end
end
