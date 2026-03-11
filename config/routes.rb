Rails.application.routes.draw do
  root to: "pages#home"

  resources :subjects do
    resources :contexts, only: [:new, :create]
  end
end
