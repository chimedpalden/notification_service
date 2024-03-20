# frozen_string_literal: true

module Vineti
  module Notifications
    class SerializableEmailTemplate < JSONAPI::Serializable::Resource
      type 'email_template'

      attributes :template_id, :subject, :text_body, :html_body, :variables
    end
  end
end
