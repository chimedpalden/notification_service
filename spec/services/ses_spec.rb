require 'rails_helper'

describe Ses do
  let(:ses) { Ses.new }

  describe '#initialize' do
    context 'disable_ses == false' do
      before do
        allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('disable_ses').and_return(false)
        allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('aws_ses_access_key_id').and_call_original
        allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('aws_ses_secret_access_key').and_call_original
        allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('aws_ses_region').and_call_original
      end

      it 'Creates a aws mail client' do
        expect(ses.client).to be_instance_of(Aws::SES::Client)
      end
    end

    context 'disable_ses == true' do
      before do
        allow(Vineti::Notifications::Config.instance).to receive(:fetch).with('disable_ses').and_return(true)
      end

      it 'Creates a application mailer service' do
        expect(ses.client).to be_instance_of(ApplicationMailerService)
      end
    end
  end
end
