Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :contexts do
    resources :chats, only: [:show, :create]
  end
end
