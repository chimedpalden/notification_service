# frozen_string_literal: true

class MessageSerializer < JSONAPI::Serializable::Resource
  type 'message'

  attributes :message_id, :text, :subject
end
