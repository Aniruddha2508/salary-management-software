require "rails_helper"

RSpec.describe "Api::V1::Employees" do
  let(:password) { "correct-horse-battery-staple" }
  let!(:hr_user) { create(:user, email: "hr@acme.test", password: password) }

  def sign_in
    post "/api/v1/session", params: { email: "hr@acme.test", password: password }, as: :json
  end

  def csrf_token
    get "/api/v1/csrf_token"
    JSON.parse(response.body)["csrf_token"]
  end

  describe "authentication" do
    it "rejects index when not signed in" do
      get "/api/v1/employees"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/employees" do
    before do
      sign_in
      create(:employee, employee_id: "EMP00001", first_name: "Alice", last_name: "Smith",
                         email: "alice@acme.test", country: "United States", department: "Engineering")
      create(:employee, employee_id: "EMP00002", first_name: "Bob", last_name: "Jones",
                         email: "bob@acme.test", country: "India", department: "Sales")
    end

    it "lists employees with pagination metadata" do
      get "/api/v1/employees"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["employees"].size).to eq(2)
      expect(body["pagination"]).to include("page" => 1, "count" => 2)
    end

    it "searches by name" do
      get "/api/v1/employees", params: { search: "Alice" }

      body = JSON.parse(response.body)
      expect(body["employees"].size).to eq(1)
      expect(body["employees"].first["first_name"]).to eq("Alice")
    end

    it "searches by employee_id" do
      get "/api/v1/employees", params: { search: "EMP00002" }

      body = JSON.parse(response.body)
      expect(body["employees"].size).to eq(1)
      expect(body["employees"].first["employee_id"]).to eq("EMP00002")
    end

    it "filters by country" do
      get "/api/v1/employees", params: { country: "India" }

      body = JSON.parse(response.body)
      expect(body["employees"].size).to eq(1)
      expect(body["employees"].first["country"]).to eq("India")
    end

    it "filters by department" do
      get "/api/v1/employees", params: { department: "Sales" }

      body = JSON.parse(response.body)
      expect(body["employees"].size).to eq(1)
      expect(body["employees"].first["department"]).to eq("Sales")
    end

    it "sorts by a whitelisted column, descending" do
      get "/api/v1/employees", params: { sort_by: "first_name", sort_dir: "desc" }

      body = JSON.parse(response.body)
      expect(body["employees"].map { |e| e["first_name"] }).to eq(%w[Bob Alice])
    end

    it "ignores a non-whitelisted sort column rather than raising" do
      get "/api/v1/employees", params: { sort_by: "password_digest" }

      expect(response).to have_http_status(:ok)
    end

    it "paginates with per_page" do
      get "/api/v1/employees", params: { per_page: 1, page: 2 }

      body = JSON.parse(response.body)
      expect(body["employees"].size).to eq(1)
      expect(body["pagination"]).to include("page" => 2, "limit" => 1, "count" => 2)
    end

    it "returns an empty page rather than erroring when the page number is past the last page" do
      get "/api/v1/employees", params: { per_page: 1, page: 9999 }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["employees"]).to eq([])
      expect(body["pagination"]).to include("count" => 2, "limit" => 1)
    end
  end

  describe "GET /api/v1/employees/:id" do
    before { sign_in }

    it "returns the employee" do
      employee = create(:employee)

      get "/api/v1/employees/#{employee.id}"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["employee"]["id"]).to eq(employee.id)
    end

    it "returns 404 for an unknown id" do
      get "/api/v1/employees/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/employees" do
    before { sign_in }

    let(:valid_attributes) do
      {
        employee_id: "EMP09999", first_name: "New", last_name: "Hire",
        email: "new.hire@acme.test", country: "United States", department: "Engineering",
        job_title: "Software Engineer", employment_type: "full_time",
        hire_date: "2024-01-01", effective_date: "2024-01-01",
        base_salary: "95000", currency: "usd",
      }
    end

    it "creates an employee with a valid CSRF token" do
      token = csrf_token

      post "/api/v1/employees", params: { employee: valid_attributes }, as: :json,
                                 headers: { "X-CSRF-Token" => token }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["employee"]["employee_id"]).to eq("EMP09999")
      expect(body["employee"]["currency"]).to eq("USD")
      expect(Employee.count).to eq(1)
    end

    it "rejects creation without a CSRF token" do
      post "/api/v1/employees", params: { employee: valid_attributes }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(Employee.count).to eq(0)
    end

    it "returns validation errors for invalid attributes" do
      token = csrf_token

      post "/api/v1/employees", params: { employee: valid_attributes.merge(base_salary: -1) }, as: :json,
                                 headers: { "X-CSRF-Token" => token }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["error"]["details"]).to be_present
    end
  end

  describe "PATCH /api/v1/employees/:id" do
    before { sign_in }

    it "updates the employee with a valid CSRF token" do
      employee = create(:employee, job_title: "Engineer I")
      token = csrf_token

      patch "/api/v1/employees/#{employee.id}", params: { employee: { job_title: "Engineer II" } }, as: :json,
                                                  headers: { "X-CSRF-Token" => token }

      expect(response).to have_http_status(:ok)
      expect(employee.reload.job_title).to eq("Engineer II")
    end

    it "returns validation errors for an invalid update" do
      employee = create(:employee)
      token = csrf_token

      patch "/api/v1/employees/#{employee.id}", params: { employee: { email: "not-an-email" } }, as: :json,
                                                  headers: { "X-CSRF-Token" => token }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /api/v1/employees/:id" do
    before { sign_in }

    it "deletes the employee with a valid CSRF token" do
      employee = create(:employee)
      token = csrf_token

      delete "/api/v1/employees/#{employee.id}", headers: { "X-CSRF-Token" => token }

      expect(response).to have_http_status(:no_content)
      expect(Employee.exists?(employee.id)).to be(false)
    end
  end
end
