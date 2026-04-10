Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  root to: "pages#home"

  resources :contexts do
    member do
      get :generate_summary
    end
    resources :chats, only: [:create]
    resource :podcast_script, only: [:create] do
      get :download_audio, on: :member
    end
  end

  resources :chats, only: [:show, :destroy] do
    resources :messages, only: [:create]
  end

  get "shared/chats/:share_token", to: "shared_chats#show", as: :shared_chat
end
