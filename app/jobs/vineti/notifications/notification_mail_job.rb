# frozen_string_literal: true

module Vineti::Notifications
  class NotificationMailJob < ApplicationJob
    queue_as :notification_mails

    def perform(mail_options)
      transaction = Vineti::Notifications::EventTransaction.find_by(transaction_id: mail_options[:transaction_id])
      log = Vineti::Notifications::NotificationEmailLog.create(mail_options[:email_log_attributes]) if mail_options[:log_email?]

      response = Ses.new.send_email(
        source: mail_options[:source],
        destination: mail_options[:destination],
        message: mail_options[:message]
      )

      transaction&.update!(status: "SUCCESS")
      log_mail_response(mail_options[:message], response&.message_id, log)
    rescue StandardError => e
      Rails.logger.error("Error: #{e} \n\tat #{e.backtrace.join("\n\tat ")}")
      transaction&.update!(status: "ERROR")
      log_mail_response(mail_options[:message], response&.message_id, log, e)
      Airbrake.notify(e, user: mail_options[:source], created_at: Time.now.utc, transaction_id: transaction&.transaction_id) if defined?(Airbrake)
    end

    private

    def log_mail_response(mail_body, message_id, log, error = nil)
      if error.nil?
        response = { message_id: message_id, mail_body: mail_body }
        Vineti::Notifications::NotificationEmailResponse::SuccessResponse.record(response, log)
      else
        response = { error: error&.message, backtrace: error&.backtrace, mail_body: mail_body }
        Vineti::Notifications::NotificationEmailResponse::ErrorResponse.record(response, log)
      end
    end
  end
end
