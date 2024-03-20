require 'rails_helper'

module Vineti::Notifications
  RSpec.describe EventTransaction, type: :model do
    context 'Validations' do
      subject { event_transaction.valid? }

      let(:errors) { event_transaction.errors.full_messages.join(', ') }

      describe 'When event is empty' do
        let(:event_transaction) { FactoryBot.build(:event_transaction, :without_event) }

        it 'Returns false for validation check' do
          expect(subject).to be false
          expect(errors).to eq("Transaction can't be blank")
        end
      end

      describe 'when event is present' do
        let(:event_transaction) { FactoryBot.build(:event_transaction, transaction_id: SecureRandom.uuid) }

        it 'Returns true for validation check' do
          expect(subject).to be true
        end

        it 'Sets default for status is nil' do
          expect(event_transaction.status).to be nil
        end
      end
    end

    context 'Associations' do
      before do
        @parent_transaction = FactoryBot.create(:event_transaction, transaction_id: SecureRandom.uuid)
        @child_transaction = FactoryBot.create(:event_transaction,
                                               transaction_id: SecureRandom.uuid,
                                               parent_transaction_id: @parent_transaction.id)
      end

      it "refers child transactions" do
        expect(@parent_transaction.child_transactions.first).to eq(@child_transaction)
      end

      it "refers to parent transaction" do
        expect(@child_transaction.parent_transaction).to eq(@parent_transaction)
      end
    end

    context "has associated event" do
      let(:event_transaction) { FactoryBot.build(:event_transaction, :with_event) }

      it "refers to associated event" do
        expect(event_transaction.event).to be_a_kind_of(Vineti::Notifications::Event)
      end
    end

    context 'Scopes' do
      describe 'failed_publish_events' do
        before do
          @failed_transaction = FactoryBot.create(:event_transaction, transaction_id: SecureRandom.uuid, status: 'ERROR')
          @retry_count = 5
        end

        it "should give the failed transaction" do
          expect(Vineti::Notifications::EventTransaction.failed_publish_events(@retry_count)).to include(@failed_transaction)
        end

        it "should not include the transaction if successfully created" do
          @failed_transaction.update(status: 'CREATED')
          expect(Vineti::Notifications::EventTransaction.failed_publish_events(@retry_count)).not_to include(@failed_transaction)
        end
      end
    end
  end
end
