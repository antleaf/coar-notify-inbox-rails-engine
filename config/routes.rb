CoarNotifyInbox::Engine.routes.draw do
  resources :users, only: [:index, :create, :show, :update] do
    member do
      put :activate
      put :auth_token
    end
  end

  resources :senders do
    member do
      put :activate    
    end
  end

  resources :consumers do
    member do
      put :activate    
    end
  end

  resources :notification_types
  resources :notifications, only: [:index, :create] do
    collection do
      get :search
    end
  end
end
