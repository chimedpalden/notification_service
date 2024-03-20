# frozen_string_literal: true

class MessageErrorSerializer < JSONAPI::Serializable::Resource
  type 'message_error'

  attributes :message, :backtrace
end
