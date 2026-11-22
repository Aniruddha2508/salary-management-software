Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      get "csrf_token", to: "csrf_tokens#show"
      resource :session, only: %i[create show destroy]
      resources :employees, only: %i[index show create update destroy]
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
