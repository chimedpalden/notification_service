Rails.application.routes.draw do
  devise_for :users
  mount Vineti::Notifications::Engine => "/vineti-notifications"
  resources :templates, except: [:new, :edit], param: :template_id
  resources :subscribers, except: [:new, :edit], param: :subscriber_id
  resources :events, except: [:new, :edit], param: :name
end
