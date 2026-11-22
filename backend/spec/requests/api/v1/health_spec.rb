require "rails_helper"

RSpec.describe "Api::V1::Health" do
  describe "GET /api/v1/health" do
    it "returns a 200 with an ok status payload" do
      get "/api/v1/health"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("status" => "ok")
    end
  end
end
