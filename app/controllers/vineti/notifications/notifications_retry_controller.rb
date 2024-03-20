# frozen_string_literal: true

module Vineti::Notifications
  class NotificationsRetryController < Vineti::Notifications::ApplicationController
    def retry_publish
      result = Events::Operation::NotificationRetry.call(
        params: retry_params
      )
      if result.success?
        render json: { message: 'Retry published successfully' }, status: 200
      else
        render json: { errors: result[:errors] }, status: result[:status]
      end
    end

    private

    def retry_params
      params.require(:transaction).permit(:event_name, :transaction_id)
    end
  end
end
