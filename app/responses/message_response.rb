# frozen_string_literal: true

class MessageResponse
  attr_reader :response, :msg_obj

  delegate :message_id, :message, :backtrace, to: :response
  delegate :text, :subject, to: :msg_obj

  def initialize(response, msg_obj = {})
    @response = response
    @msg_obj = msg_obj
  end

  def id
    'current'
  end
end
