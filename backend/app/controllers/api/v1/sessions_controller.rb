module Api
  module V1
    class SessionsController < BaseController
      # Logging in is itself a mutating request, but the browser can't have
      # a CSRF token yet before it's ever authenticated, so this is the one
      # action exempt from the check. Every action after login (including
      # logout) still requires the token fetched via CsrfTokensController.
      skip_before_action :verify_authenticity_token, only: :create

      # POST /api/v1/session
      def create
        user = User.find_by(email: login_params[:email].to_s.downcase.strip)

        if user&.authenticate(login_params[:password].to_s)
          session[:user_id] = user.id
          render json: { user: user_json(user) }, status: :ok
        else
          render json: { error: { message: "Invalid email or password." } }, status: :unauthorized
        end
      end

      # DELETE /api/v1/session
      def destroy
        session[:user_id] = nil
        head :no_content
      end

      # GET /api/v1/session
      #
      # Lets the frontend check "am I logged in?" on app load / refresh.
      def show
        if current_user
          render json: { user: user_json(current_user) }, status: :ok
        else
          render json: { error: { message: "Not signed in." } }, status: :unauthorized
        end
      end

      private

      # Rails' ParamsWrapper nests JSON params under the resource name
      # (here "session") alongside the top-level keys. Reading from
      # `params[:session]` first (falling back to top-level) handles both
      # a wrapped body ({"session": {...}}) and a flat one ({"email": ...}),
      # which is what our curl smoke tests and the frontend both send.
      def login_params
        params[:session].presence || params
      end

      def user_json(user)
        { id: user.id, name: user.name, email: user.email }
      end
    end
  end
end
