# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

# In production, Rails serves the built React SPA itself (same origin),
# so CORS isn't needed there by default. FRONTEND_ORIGIN lets a decoupled
# deployment (frontend hosted separately from the API) opt back in without
# a code change.
allowed_origins = ["http://localhost:5173"]
allowed_origins << ENV["FRONTEND_ORIGIN"] if ENV["FRONTEND_ORIGIN"].present?

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "/api/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: true
  end
end
