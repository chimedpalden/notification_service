# frozen_string_literal: true

module Vineti::Notifications
  class Subscriber::EmailResponseSerializer < JSONAPI::Serializable::Resource
    type 'email_response'

    attributes :message_id, :text, :subject
  end
end
