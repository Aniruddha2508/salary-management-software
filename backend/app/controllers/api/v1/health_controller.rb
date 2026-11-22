module Api
  module V1
    class HealthController < BaseController
      # Simple liveness check for the frontend/dev workflow to confirm the
      # API is reachable, separate from Rails' own /up infra health check.
      def show
        render json: { status: "ok" }, status: :ok
      end
    end
  end
end
