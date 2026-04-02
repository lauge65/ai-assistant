Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :contexts do
    resources :chats, only: [:create]
    resource :podcast_script, only: [:create] do
      member do
        get :download
        post :generate_audio
        get :download_audio
      end
    end
  end

  resources :chats, only: [:show, :destroy] do
    resources :messages, only: [:create]
  end

  get "shared/chats/:share_token", to: "shared_chats#show", as: :shared_chat
end
