# frozen_string_literal: true

module Vineti::Notifications
  module ServiceHelper
    def event?
      topic.is_a? Vineti::Notifications::Event
    end

    def publisher?
      topic.is_a? Vineti::Notifications::Publisher
    end

    def create_new_transaction(data = {})
      Vineti::Notifications::EventTransaction.create!(
        transaction_id: SecureRandom.uuid,
        payload: data,
        status: "CREATED",
        subscriber: subscriber,
        event: event? ? topic : nil,
        parent_transaction_id: parent_transaction_id
      )
    end

    def get_transaction_and_update_redelivery_count(data)
      transaction = Vineti::Notifications::EventTransaction.where(parent_transaction_id: parent_transaction_id, subscriber: subscriber, event: event? ? topic : nil).first
      if transaction.present?
        transaction.retries_count = transaction.retries_count + 1
        transaction.save
        transaction
      else
        create_new_transaction(data)
      end
    end

    def get_retry_transaction(data)
      if retry_transaction_id.present?
        Vineti::Notifications::EventTransaction.find_by!(transaction_id: retry_transaction_id)
      else
        create_new_transaction(data)
      end
    end
  end
end
