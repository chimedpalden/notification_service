# frozen_string_literal: true

class EventTransactionSerializer < JSONAPI::Serializable::Resource
  type 'event_transaction'

  attributes :transaction_id, :payload, :status, :response_code, :response, :subscriber
end
