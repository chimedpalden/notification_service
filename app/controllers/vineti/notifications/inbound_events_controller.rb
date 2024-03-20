module Vineti::Notifications
  class InboundEventsController < Vineti::Notifications::ApplicationController
    before_action :validate_feature_flag

    # TODO: Workaround to unblock team Odyssey. Need to refactor when external api user is available
    skip_before_action :validate_user_permissions

    def message
      result = Inbound::Operation::Create.call(
        params: inbound_params,
        publisher_token: publisher_token,
        current_user: current_user
      )

      if result.success?
        render json: { message: 'request registered' }, status: 200
      else
        render json: { errors: result[:errors] }, status: result[:status]
      end
    end

    private

    def inbound_params
      params.require(:payload)
    end

    def publisher_token
      request.headers["publisher-token"]
    end

    def validate_feature_flag
      return if Vineti::Notifications::Config.instance.feature('inbound_event_enable')

      render json: { message: 'not implemented' }, status: :not_implemented
    end
  end
end
