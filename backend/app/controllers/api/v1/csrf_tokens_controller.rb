module Api
  module V1
    class CsrfTokensController < BaseController
      # GET /api/v1/csrf_token
      #
      # The SPA calls this once on load (and after login) to obtain a CSRF
      # token to send back as the X-CSRF-Token header on every mutating
      # request (POST/PATCH/DELETE). See BaseController#verified_request?.
      def show
        render json: { csrf_token: form_authenticity_token }, status: :ok
      end
    end
  end
end
