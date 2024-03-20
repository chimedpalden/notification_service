module Vineti::Notifications
  class NotificationsController < Vineti::Notifications::ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

    def send_notifications
      result = EventService.new(send_notification_params).notify_subscribers
      if result.instance_of?(Vineti::Notifications::ActivemqPublishSuccessResponse)
        render jsonapi: result,
               class: {
                 'Vineti::Notifications::ActivemqPublishSuccessResponse': Vineti::Notifications::ActivemqPublishSerializer
               }
      else
        render jsonapi_errors: result,
               class: {
                 'Vineti::Notifications::ActivemqPublishErrorResponse': Vineti::Notifications::ActivemqPublishErrorSerializer
               },
               status: :internal_server_error
      end
    end

    private

    def send_notification_params
      params.require(:notifications).permit(:event_name, :delayed_time, template_data: {}, metadata: {}, payload: {}).to_h
    end

    def record_not_found(error)
      render jsonapi_errors: ActiveRecordErrorResponse.new(error),
             class: { 'ActiveRecordErrorResponse': ActiveRecordErrorSerializer },
             status: :not_found
    end
  end
end
