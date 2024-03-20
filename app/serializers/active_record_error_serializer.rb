# frozen_string_literal: true

class ActiveRecordErrorSerializer < JSONAPI::Serializable::Resource
  type 'active_record_error'

  attributes :message, :backtrace
end
