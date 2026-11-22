require "rails_helper"

RSpec.describe "Api::V1::Analytics" do
  let(:password) { "correct-horse-battery-staple" }
  let!(:hr_user) { create(:user, email: "hr@acme.test", password: password) }

  def sign_in
    post "/api/v1/session", params: { email: "hr@acme.test", password: password }, as: :json
  end

  before do
    create(:employee, employee_id: "EMP00001", email: "a@acme.test", country: "United States",
                       department: "Engineering", currency: "USD", base_salary: 100_000)
    create(:employee, employee_id: "EMP00002", email: "b@acme.test", country: "India",
                       department: "Sales", currency: "INR", base_salary: 900_000)
  end

  describe "authentication" do
    it "rejects summary when not signed in" do
      get "/api/v1/analytics/summary"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/analytics/summary" do
    before { sign_in }

    it "returns overall headcount and a per-currency breakdown" do
      get "/api/v1/analytics/summary"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["overall_headcount"]).to eq(2)
      expect(body["by_currency"].map { |row| row["currency"] }).to contain_exactly("USD", "INR")
    end
  end

  describe "GET /api/v1/analytics/by_country" do
    before { sign_in }

    it "returns a row per country/currency" do
      get "/api/v1/analytics/by_country"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["by_country"].map { |row| row["country"] }).to contain_exactly("United States", "India")
    end
  end

  describe "GET /api/v1/analytics/by_department" do
    before { sign_in }

    it "returns a row per department/currency" do
      get "/api/v1/analytics/by_department"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["by_department"].map { |row| row["department"] }).to contain_exactly("Engineering", "Sales")
    end
  end
end
