# frozen_string_literal: true

class EmailSubscriberSerializer < JSONAPI::Serializable::Resource
  type 'email_subscriber'

  attributes :subscriber_id,
             :from_address,
             :to_addresses,
             :cc_addresses,
             :bcc_addresses,
             :email_template,
             :notification_event
end
