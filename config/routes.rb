CoarNotifyInbox::Engine.routes.draw do
  resources :users, only: [:index, :create, :show, :update] do
    member do
      patch :activate
      patch :deactivate
      put :auth_token
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
