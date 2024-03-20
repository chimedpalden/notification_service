# frozen_string_literal: true

class EventSerializer < JSONAPI::Serializable::Resource
  type 'event'

  attributes :name, :subscribers
end
