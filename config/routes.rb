Rails.application.routes.draw do
  root "matches#index"

  resource :registration, only: %i[new create]
  resource :session, only: %i[new create destroy]

  resources :matches, only: %i[index show] do
    collection do
      get :calendar
      get :groups
      post :live_sync
    end

    resource :prediction, only: %i[create update]
  end

  resources :predictions, only: [] do
    resources :comments, controller: :prediction_comments, only: :create
  end

  resource :ranking, only: :show
  resource :achievements, only: :show
  resources :special_predictions, only: %i[index create update]

  namespace :admin do
    resource :sync, only: :create
  end
end
