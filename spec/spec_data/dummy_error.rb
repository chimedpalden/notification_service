# frozen_string_literal: true

# This class is to test responses in application
class DummyError < StandardError
  def initialize(message, backtrace)
    super(message)
    set_backtrace backtrace
  end

  def message_id
    'message_id'
  end
end
