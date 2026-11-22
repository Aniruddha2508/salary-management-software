require "rails_helper"

RSpec.describe Employee do
  describe "validations" do
    it "is valid with all required fields" do
      expect(build(:employee)).to be_valid
    end

    %i[employee_id first_name last_name email country department job_title
       hire_date effective_date base_salary currency].each do |field|
      it "requires #{field}" do
        employee = build(:employee, field => nil)

        expect(employee).not_to be_valid
        expect(employee.errors[field]).not_to be_empty
      end
    end

    it "requires a unique employee_id" do
      create(:employee, employee_id: "EMP00001")
      employee = build(:employee, employee_id: "EMP00001")

      expect(employee).not_to be_valid
      expect(employee.errors[:employee_id]).to include("has already been taken")
    end

    it "requires a unique email, case-insensitively" do
      create(:employee, email: "jane@acme.test")
      employee = build(:employee, email: "JANE@acme.test")

      expect(employee).not_to be_valid
      expect(employee.errors[:email]).to include("has already been taken")
    end

    it "requires a well-formed email" do
      employee = build(:employee, email: "not-an-email")

      expect(employee).not_to be_valid
      expect(employee.errors[:email]).to include("is invalid")
    end

    it "requires base_salary to be greater than zero" do
      employee = build(:employee, base_salary: 0)

      expect(employee).not_to be_valid
      expect(employee.errors[:base_salary]).to include("must be greater than 0")
    end

    it "rejects a negative base_salary" do
      employee = build(:employee, base_salary: -100)

      expect(employee).not_to be_valid
      expect(employee.errors[:base_salary]).to include("must be greater than 0")
    end

    it "requires currency to be a 3-letter ISO-style code" do
      employee = build(:employee, currency: "US")

      expect(employee).not_to be_valid
      expect(employee.errors[:currency]).to be_present
    end

    it "upcases a lowercase currency code before validating" do
      employee = build(:employee, currency: "usd")

      expect(employee).to be_valid
      expect(employee.currency).to eq("USD")
    end

    it "requires employment_type to be one of the known values" do
      employee = build(:employee, employment_type: "freelance")

      expect(employee).not_to be_valid
      expect(employee.errors[:employment_type]).to be_present
    end

    it "rejects a manager_id equal to its own id" do
      employee = create(:employee)
      employee.manager_id = employee.id

      expect(employee).not_to be_valid
      expect(employee.errors[:manager_id]).to include("can't be the employee's own id")
    end
  end

  describe "normalization" do
    it "downcases and strips the email before saving" do
      employee = create(:employee, email: "  Jane.Doe@ACME.test  ")

      expect(employee.email).to eq("jane.doe@acme.test")
    end
  end

  describe "employment_type enum" do
    it "exposes the expected values" do
      expect(Employee.employment_types.keys).to contain_exactly("full_time", "part_time", "contract")
    end

    it "provides query methods for the current value" do
      employee = build(:employee, employment_type: "contract")

      expect(employee.contract?).to be(true)
      expect(employee.full_time?).to be(false)
    end
  end

  describe "manager association" do
    it "allows an employee to have no manager" do
      employee = build(:employee, manager: nil)

      expect(employee).to be_valid
    end

    it "allows an employee to report to another employee" do
      manager = create(:employee, employee_id: "EMP00001", email: "manager@acme.test")
      report = build(:employee, manager: manager)

      expect(report).to be_valid
      expect(report.manager).to eq(manager)
    end

    it "exposes direct_reports from the manager's side" do
      manager = create(:employee, employee_id: "EMP00001", email: "manager@acme.test")
      report = create(:employee, employee_id: "EMP00002", email: "report@acme.test", manager: manager)

      expect(manager.direct_reports).to contain_exactly(report)
    end
  end
end
