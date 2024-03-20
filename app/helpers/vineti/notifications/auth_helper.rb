# frozen_string_literal: true

require 'jsonapi_errors_handler'

module Vineti::Notifications
  module AuthHelper
    def validate_user_permissions
      # NOOOO! Permission::Operation is specific to vineti-platform
      # This couples notifications engine to the application.
      run Permission::Operation::All do |result|
        result[:result][:general].each do |item|
          return true if item[:action] == "write" && item[:domain] == "roles"
        end
      end

      raise JsonapiErrorsHandler::Errors::Unauthorized
    end
  end
end
