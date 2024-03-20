require 'rails_helper'

module Vineti::Notifications
  describe ActivemqPublishSuccessResponse do
    let(:response) do
      described_class.new(result: '12345')
    end

    describe '#correlation_id' do
      subject { response.result }

      it 'returns correlation id from response' do
        expect(subject).to eq('12345')
      end
    end

    describe '#id' do
      subject { response.id }

      it 'returns id' do
        expect(subject).to eq('current')
      end
    end
  end
end
