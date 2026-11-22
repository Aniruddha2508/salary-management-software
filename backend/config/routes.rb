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
      get "analytics/summary", to: "analytics#summary"
      get "analytics/by_country", to: "analytics#by_country"
      get "analytics/by_department", to: "analytics#by_department"
    end
  end

  # SPA fallback for production: any GET request that isn't an API route
  # (and isn't the health check) gets the built frontend's index.html, so
  # React Router can handle the client-side route on a full page
  # load/refresh (e.g. /employees/42). Actual static files in public/
  # (JS/CSS/images) are served directly by Rails' static file middleware
  # before a request ever reaches this route.
  get "*path", to: "static#index",
               constraints: ->(req) { !req.path.start_with?("/api") && req.path != "/up" }

  # Defines the root path route ("/")
  # root "posts#index"
end
