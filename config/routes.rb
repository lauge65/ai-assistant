Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :contexts, only: [:index, :new, :create, :edit, :update, :show] do
    resources :chats, only: [:show, :create]
  end
end
