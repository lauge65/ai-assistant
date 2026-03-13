Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :contexts do
    resources :chats, only: [:create]
  end

  resources :chats, only: [:show] do
    resources :messages, only: [:create]
  end
end
