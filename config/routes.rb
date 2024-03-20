Vineti::Notifications::Engine.routes.draw do
  resources :templates, except: %i[new edit], param: :template_id
  resources :subscribers, except: %i[new edit], param: :subscriber_id
  resources :events, except: %i[new edit], param: :name
  get :events_list, to: 'events#list'
  post :activemq, to: 'stomp_clients#create'
  resources :event_transactions, only: %i[update show], param: :transaction_id do
    collection do
      get :find_by_event
    end
  end
  post :message, to: 'inbound_events#message'

  post :send_notifications, to: 'notifications#send_notifications'
  post :retry_publish, to: 'notifications_retry#retry_publish'

  resources :mails, only: [] do
    collection do
      post :send_event_notification, to: 'mails#send_event_notification'
    end
  end
end
