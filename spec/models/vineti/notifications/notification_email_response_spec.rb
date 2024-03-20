require 'rails_helper'

module Vineti::Notifications
  RSpec.describe NotificationEmailResponse, type: :model do
    describe 'When initialized' do
      subject { Vineti::Notifications::NotificationEmailResponse::Base.new }

      it 'Raises error' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end
end
