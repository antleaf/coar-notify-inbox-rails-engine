CoarNotifyInbox::Engine.routes.draw do
  resources :users, only: [:index, :create] do
    member do
      patch :activate
      patch :deactivate
    end
  end

  namespace :coar_notify_inbox do
    resources :senders
    resources :consumers
  end
end
