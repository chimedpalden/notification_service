require 'rails_helper'

RSpec.describe NotificationEmailValidator do
  subject do
    Class.new do
      include ActiveModel::Validations
      attr_accessor :from_address, :to_addresses, :cc_addresses, :bcc_addresses,
                    :vineti_notifications_email_templates_id,
                    :vineti_notifications_email_subscribers_id
      validates :from_address,
                :to_addresses,
                :bcc_addresses,
                :cc_addresses,
                email: { optional: %i[cc_addresses bcc_addresses] }
    end.new
  end

  context 'When valid email address are passed' do
    it 'returns true for valid check' do
      subject.from_address = Faker::Internet.email
      subject.to_addresses = [Faker::Internet.email, Faker::Internet.email]
      subject.vineti_notifications_email_subscribers_id = 1
      subject.vineti_notifications_email_templates_id = 1
      expect(subject.valid?).to be true
    end
  end

  context 'From address' do
    describe 'When not present' do
      it 'Invalidates the object' do
        subject.from_address = ''
        expect(subject.valid?).to be false
        expect(subject.errors.messages[:from_address].join(', ')).to eq(
          "Can't be blank, please specify valid value, please add correct email address"
        )
      end
    end

    describe 'When format is not right' do
      it 'Invalidated object' do
        subject.from_address = 'invalid@'
        expect(subject.valid?).to be false
        expect(subject.errors.messages[:from_address].join(', ')).to eq(
          'please add correct email address'
        )
      end
    end

    describe 'When valid email id is passed' do
      it 'Passes validation for from addresses' do
        subject.from_address = Faker::Internet.email
        subject.valid?
        expect(subject.errors.messages[:from_address]).to match([])
      end
    end
  end

  context 'To addresses' do
    describe 'When empty' do
      it 'Raises error for validation' do
        subject.to_addresses = []
        expect(subject.valid?).to be false
        expect(subject.errors.messages[:to_addresses].join(', ')).to eq(
          "Can't be blank, please specify valid value"
        )
      end
    end

    describe 'When emails are not valid' do
      it 'Raises error for validation' do
        subject.to_addresses = [false, true, Faker::Internet.email]
        expect(subject.valid?).to be false
        expect(subject.errors.messages[:to_addresses].join(', ')).to eq(
          'false in to_addresses is not valid, true in to_addresses is not valid'
        )
      end
    end

    describe 'When all emails in to addresses are valid' do
      it 'Does not add any error for to addresses' do
        subject.to_addresses = [Faker::Internet.email, Faker::Internet.email]
        subject.valid?
        expect(subject.errors.messages[:to_addresses]).to match([])
      end
    end
  end

  context 'CC addresses' do
    describe 'When not passed' do
      it 'does not validate addresses as CC addresses are optional' do
        subject.cc_addresses = []
        expect(subject.valid?).to be false
        expect(subject.errors.messages[:cc_addresses]).to match([])
      end
    end

    describe 'When invalid data is passed' do
      it 'Raises error for validation' do
        subject.cc_addresses = [false, Faker::Internet.email]
        expect(subject.valid?).to be false
        expect(subject.errors.messages[:cc_addresses].join(', ')).to eq(
          'false in cc_addresses is not valid'
        )
      end
    end
  end

  context 'Bcc addresses' do
    describe 'When not passed' do
      it 'does not validate addresses as Bcc addresses are optional' do
        subject.bcc_addresses = []
        expect(subject.valid?).to be false
        expect(subject.errors.messages[:bcc_addresses]).to match([])
      end
    end

    describe 'When invalid data is passed' do
      it 'Raises error for validation' do
        subject.bcc_addresses = [false, Faker::Internet.email]
        expect(subject.valid?).to be false
        expect(subject.errors.messages[:bcc_addresses].join(', ')).to eq(
          'false in bcc_addresses is not valid'
        )
      end
    end
  end
end
