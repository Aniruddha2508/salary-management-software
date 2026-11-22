module Api
  module V1
    class AnalyticsController < BaseController
      before_action :require_authentication!

      # GET /api/v1/analytics/summary
      def summary
        render json: AnalyticsService.new.summary, status: :ok
      end

      # GET /api/v1/analytics/by_country
      def by_country
        render json: AnalyticsService.new.by_country, status: :ok
      end

      # GET /api/v1/analytics/by_department
      def by_department
        render json: AnalyticsService.new.by_department, status: :ok
      end
    end
  end
end
