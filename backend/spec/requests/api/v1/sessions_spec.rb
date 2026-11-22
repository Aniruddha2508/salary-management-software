require "rails_helper"

RSpec.describe "Api::V1::Sessions" do
  let(:password) { "correct-horse-battery-staple" }
  let!(:user) { create(:user, email: "hr@acme.test", password: password) }

  describe "POST /api/v1/session" do
    it "logs in and sets the session with correct credentials" do
      post "/api/v1/session", params: { email: "hr@acme.test", password: password }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["user"]).to include("email" => "hr@acme.test", "name" => user.name)
    end

    it "is case-insensitive on email" do
      post "/api/v1/session", params: { email: "HR@ACME.test", password: password }, as: :json

      expect(response).to have_http_status(:ok)
    end

    it "rejects an incorrect password" do
      post "/api/v1/session", params: { email: "hr@acme.test", password: "wrong" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]["message"]).to be_present
    end

    it "rejects an unknown email" do
      post "/api/v1/session", params: { email: "nobody@acme.test", password: password }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/session" do
    it "returns 401 when not signed in" do
      get "/api/v1/session"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the current user when signed in" do
      post "/api/v1/session", params: { email: "hr@acme.test", password: password }, as: :json

      get "/api/v1/session"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["user"]).to include("email" => "hr@acme.test")
    end
  end

  describe "DELETE /api/v1/session" do
    it "logs the user out so a subsequent current-user check is 401" do
      post "/api/v1/session", params: { email: "hr@acme.test", password: password }, as: :json

      csrf_token = JSON.parse(get("/api/v1/csrf_token") && response.body)["csrf_token"]
      delete "/api/v1/session", headers: { "X-CSRF-Token" => csrf_token }
      expect(response).to have_http_status(:no_content)

      get "/api/v1/session"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "CSRF protection on mutating requests" do
    it "rejects a mutating request without a valid CSRF token" do
      post "/api/v1/session", params: { email: "hr@acme.test", password: password }, as: :json

      delete "/api/v1/session", headers: { "X-CSRF-Token" => "bogus-token" }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "accepts a mutating request with a valid CSRF token" do
      post "/api/v1/session", params: { email: "hr@acme.test", password: password }, as: :json

      csrf_token = JSON.parse(get("/api/v1/csrf_token") && response.body)["csrf_token"]
      delete "/api/v1/session", headers: { "X-CSRF-Token" => csrf_token }

      expect(response).to have_http_status(:no_content)
    end
  end
end
