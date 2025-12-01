CoarNotifyInbox::Engine.routes.draw do
  resources :users, only: [:index, :create] do
    member do
      patch :activate
      patch :deactivate
    end
  end

  resources :senders
  resources :consumers
  resources :notification_types
  resources :notifications, only: [:index, :create] do
    collection do
      get :search
    end
  end
end
