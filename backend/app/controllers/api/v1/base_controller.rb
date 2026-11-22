module Api
  module V1
    # All Api::V1 controllers inherit from here so we have one place to
    # add cross-cutting API concerns (auth, error rendering, etc.)
    class BaseController < ApplicationController
      # Rails' forgery protection renders an HTML error page by default,
      # which doesn't make sense for a JSON API. Respond with a 422 JSON
      # error instead, and require the CSRF token Rails itself issues
      # (fetched by the frontend from Api::V1::CsrfTokensController) on
      # every mutating request.
      protect_from_forgery with: :exception, prepend: true
      rescue_from ActionController::InvalidAuthenticityToken, with: :render_invalid_authenticity_token

      # Expose the CSRF token in the session for ActionController's
      # protect_from_forgery to compare against, even though this is an
      # API-only app (no forms to embed it in).
      def verified_request? # rubocop:disable Style/OptionalBooleanParameter
        super || valid_authenticity_token?(session, request.headers["X-CSRF-Token"].to_s)
      end

      private

      def current_user
        @current_user ||= User.find_by(id: session[:user_id])
      end

      def require_authentication!
        return if current_user

        render json: { error: { message: "You must be signed in to do that." } }, status: :unauthorized
      end

      def render_invalid_authenticity_token
        render json: { error: { message: "Invalid or missing CSRF token." } }, status: :unprocessable_content
      end
    end
  end
end
