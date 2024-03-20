module Vineti::Notifications::NotificationEmailResponse
  class ErrorResponse < ::Vineti::Notifications::NotificationEmailResponse::Base
    class << self
      def required_response_keys
        %i[error backtrace]
      end

      def optional_response_keys
        %i[mail_body]
      end

      def record(response, log_object)
        Vineti::Notifications::NotificationEmailResponse::ErrorResponse.create!(
          response: response,
          email_log: log_object
        )
      end
    end
  end
end
