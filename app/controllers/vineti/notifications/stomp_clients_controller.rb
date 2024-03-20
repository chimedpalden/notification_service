# frozen_string_literal: true

module Vineti::Notifications
  class StompClientsController < Vineti::Notifications::ApplicationController
    def create
      Vineti::Notifications::ConsumerSeeder.run

      render json: { status: 200 }
    end
  end
end
