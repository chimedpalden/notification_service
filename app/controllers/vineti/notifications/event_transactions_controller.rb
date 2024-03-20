require_dependency "vineti/notifications/application_controller"

module Vineti::Notifications
  class EventTransactionsController < Vineti::Notifications::ApplicationController
    before_action :fetch_transaction!, only: %i[update show]

    # List all event transactions
    def find_by_event
      event = Vineti::Notifications::Event.find_by!(name: params[:name])
      transactions = Vineti::Notifications::EventTransaction.where(vineti_notifications_events_id: event)
      render jsonapi: transactions,
             include: [event_transaction: :subscriber],
             class: { 'Vineti::Notifications::EventTransaction': EventTransactionSerializer }
    end

    def update
      @transaction.update!(transaction_params)

      render json: { transaction_status: @transaction.status }
    end

    def show
      render jsonapi: @transaction,
             include: [event_transaction: :subscriber],
             class: { 'Vineti::Notifications::EventTransaction': EventTransactionSerializer }
    end

    private

    def transaction_params
      params.require(:transaction).permit(:transaction_id, :status, payload: {})
    end

    def fetch_transaction!
      @transaction = Vineti::Notifications::EventTransaction.find_by!(params.permit(:transaction_id))
    end
  end
end
