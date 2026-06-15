Rails.application.routes.draw do
  root "matches#index"

  resource :registration, only: %i[new create]
  resource :session, only: %i[new create destroy]

  resources :matches, only: %i[index show] do
    collection do
      get :calendar
      get :groups
      get :bracket
      post :live_sync
    end

    resource :prediction, only: %i[create update]
    resources :messages, controller: :match_messages, only: %i[index create]
  end

  resources :predictions, only: [] do
    resources :comments, controller: :prediction_comments, only: :create
  end

  resources :activity_events, only: [] do
    resources :comments, controller: :activity_event_comments, only: :create
    post "reactions/:reaction_type", to: "activity_event_reactions#create", as: :reaction
    delete "reactions/:reaction_type", to: "activity_event_reactions#destroy"
  end

  resource :ranking, only: :show
  resource :mural, only: :show
  resource :achievements, only: :show
  resources :special_predictions, only: %i[index create update]

  namespace :admin do
    resource :sync, only: :create
  end
end
