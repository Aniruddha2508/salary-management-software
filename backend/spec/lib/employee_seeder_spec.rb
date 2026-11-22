require "rails_helper"

RSpec.describe EmployeeSeeder do
  # A small sample is enough to prove the generation logic is correct;
  # seeding the full 10,000 rows belongs in manual/local verification,
  # not the spec suite (it would make the suite slow for no real gain
  # in confidence).
  let(:sample_size) { 50 }

  before { described_class.new.seed!(count: sample_size) }

  it "creates exactly the requested number of employees" do
    expect(Employee.count).to eq(sample_size)
  end

  it "gives every employee a unique employee_id" do
    expect(Employee.distinct.count(:employee_id)).to eq(sample_size)
  end

  it "gives every employee a unique email" do
    expect(Employee.distinct.count(:email)).to eq(sample_size)
  end

  it "produces only valid employee records" do
    invalid = Employee.all.reject(&:valid?)

    expect(invalid).to be_empty
  end

  it "assigns exactly one currency per country" do
    currencies_per_country = Employee.distinct.pluck(:country, :currency).group_by(&:first)

    currencies_per_country.each_value do |pairs|
      expect(pairs.map(&:last).uniq.size).to eq(1)
    end
  end

  it "never assigns an employee as their own manager" do
    self_managed = Employee.where("manager_id = id")

    expect(self_managed).to be_empty
  end

  it "only points manager_id at an employee that actually exists" do
    employee_ids = Employee.pluck(:id)
    dangling = Employee.where.not(manager_id: nil).where.not(manager_id: employee_ids)

    expect(dangling).to be_empty
  end

  it "keeps a manager in the same country as their direct reports" do
    Employee.where.not(manager_id: nil).includes(:manager).find_each do |employee|
      expect(employee.manager.country).to eq(employee.country)
    end
  end

  it "re-running the seed replaces rather than duplicates records" do
    described_class.new.seed!(count: sample_size)

    expect(Employee.count).to eq(sample_size)
  end
end
