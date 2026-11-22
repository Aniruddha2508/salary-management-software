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

      # Consistent JSON error envelope for common failure modes, so the
      # client never sees a raw Rails error page or an inconsistently
      # shaped body. Rails' rescue_from matches the *most recently
      # declared* handler first (not the most specific class), so
      # StandardError must be declared FIRST as the catch-all fallback -
      # every handler declared after it takes priority over it for the
      # exception types it covers.
      rescue_from StandardError, with: :render_internal_error
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::InvalidForeignKey, with: :render_invalid_reference
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

      def render_bad_request(exception)
        render json: { error: { message: exception.message } }, status: :bad_request
      end

      def render_not_found
        render json: { error: { message: "Record not found." } }, status: :not_found
      end

      # A model-level validation should normally catch an invalid foreign
      # key reference (see Employee#manager_exists) before it reaches the
      # database. This is a safety net in case a future association is
      # added without one.
      def render_invalid_reference
        render json: { error: { message: "References a record that does not exist." } }, status: :unprocessable_content
      end

      def render_internal_error(exception)
        # Full detail goes to the server log; the client only ever sees a
        # generic message, so the response body never leaks internals.
        Rails.logger.error("#{exception.class}: #{exception.message}")
        render json: { error: { message: "Something went wrong. Please try again." } }, status: :internal_server_error
      end
    end
  end
end
