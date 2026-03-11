Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :subjects do
    resources :contexts, only: [:new, :create]
  end
end
