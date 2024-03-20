# frozen_string_literal: true

module Vineti::Notifications
  class Subscriber::EmailErrorResponseSerializer < JSONAPI::Serializable::Resource
    type 'email_error_response'

    attributes :message, :backtrace
  end
end
