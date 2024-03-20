module Vineti
  module Notifications
    class ApplicationController < ::ApplicationController
      include Vineti::Notifications::AuthHelper

      # Because Pundit is used in vineti-platform
      # it needs to be included in vineti-notifications
      # since this application controller inherits from
      # the parent application controller.
      include Pundit
      # `raise: false` because it will raise an error
      # if `after_action :verify..` is not added in prior,
      # which happens in the case that the controllers are
      # run independent of vineti-platform.
      skip_after_action :verify_authorized, raise: false
      skip_after_action :verify_policy_scoped, raise: false

      before_action :validate_user_permissions

      rescue_from ActiveRecord::RecordNotFound do |exception|
        render json: { status: 'No Matching Record Found', error: exception }, status: 404
      end

      rescue_from ActionController::ParameterMissing, ActiveRecord::RecordInvalid do |exception|
        render json: { status: 'Bad Request, Incorrect Params passed', error: exception }, status: 400
      end

      rescue_from JsonapiErrorsHandler::Errors::Unauthorized do |exception|
        render json: { status: 'Invalid Credentials', error: exception }, status: 401
      end
    end
  end
end
