# frozen_string_literal: true

class SubscriberSerializer < JSONAPI::Serializable::Resource
  type 'subscriber'

  attributes :subscriber_id, :data, :type, :active, :delayed_time, :events, :template
end
