module Vineti::Notifications::NotificationEmailResponse
  class SuccessResponse < ::Vineti::Notifications::NotificationEmailResponse::Base
    class << self
      def required_response_keys
        %i[message_id mail_body]
      end

      def optional_response_keys
        []
      end

      def record(response, log_object)
        Vineti::Notifications::NotificationEmailResponse::SuccessResponse.create!(
          response: response,
          email_log: log_object
        )
      end
    end
  end
end
