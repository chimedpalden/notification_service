require 'rails_helper'

describe ApplicationMailerService do
  subject { described_class.new.send_email(source: source, destination: destination, message: message) }

  let(:source) { 'no-reply@vineti.com' }
  let(:destination) do
    {
      to_addresses: ['test@vineti.com'],
      cc_addresses: [],
      bcc_addresses: [],
    }
  end
  let(:message) do
    {
      subject: { data: 'This is subject' },
      body: {
        text: { data: 'This is text' },
        html: { data: 'This is HTML' },
      },
    }
  end

  describe '#send_email' do
    it 'sends out mail to email addresses passed in params' do
      expect(subject.class).to eq(Mail::Message)
      expect(subject.from).to eq([source])
      expect(subject.to).to eq(destination[:to_addresses])
      expect(subject.cc).to eq(destination[:cc_addresses])
      expect(subject.bcc).to eq(destination[:bcc_addresses])
    end
  end
end
