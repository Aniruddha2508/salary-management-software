require "rails_helper"

RSpec.describe AnalyticsService do
  subject(:service) { described_class.new }

  describe "#summary" do
    before do
      create(:employee, employee_id: "EMP00001", email: "a@acme.test", currency: "USD", base_salary: 100_000)
      create(:employee, employee_id: "EMP00002", email: "b@acme.test", currency: "USD", base_salary: 200_000)
      create(:employee, employee_id: "EMP00003", email: "c@acme.test", currency: "INR", base_salary: 900_000)
    end

    it "reports overall headcount across all currencies" do
      expect(service.summary[:overall_headcount]).to eq(3)
    end

    it "groups figures by currency, never blending them" do
      by_currency = service.summary[:by_currency].index_by { |row| row[:currency] }

      expect(by_currency.keys).to contain_exactly("USD", "INR")
      expect(by_currency["USD"][:headcount]).to eq(2)
      expect(by_currency["USD"][:total_salary]).to eq("300000.0")
      expect(by_currency["USD"][:average_salary]).to eq("150000.0")
      expect(by_currency["USD"][:median_salary]).to eq("150000.0")

      expect(by_currency["INR"][:headcount]).to eq(1)
      expect(by_currency["INR"][:total_salary]).to eq("900000.0")
      expect(by_currency["INR"][:average_salary]).to eq("900000.0")
      expect(by_currency["INR"][:median_salary]).to eq("900000.0")
    end
  end

  describe "#by_country" do
    before do
      create(:employee, employee_id: "EMP00001", email: "a@acme.test", country: "United States",
                         currency: "USD", base_salary: 60_000)
      create(:employee, employee_id: "EMP00002", email: "b@acme.test", country: "United States",
                         currency: "USD", base_salary: 80_000)
      create(:employee, employee_id: "EMP00003", email: "c@acme.test", country: "United States",
                         currency: "USD", base_salary: 100_000)
      create(:employee, employee_id: "EMP00004", email: "d@acme.test", country: "India",
                         currency: "INR", base_salary: 1_000_000)
    end

    it "computes headcount, total, average, and an exact median per country" do
      result = service.by_country[:by_country]
      us_row = result.find { |row| row[:country] == "United States" }
      india_row = result.find { |row| row[:country] == "India" }

      expect(us_row).to include(
        currency: "USD", headcount: 3,
        total_salary: "240000.0", average_salary: "80000.0", median_salary: "80000.0"
      )
      expect(india_row).to include(
        currency: "INR", headcount: 1,
        total_salary: "1000000.0", average_salary: "1000000.0", median_salary: "1000000.0"
      )
    end

    it "computes the median correctly for an even-sized group (average of the two middle values)" do
      create(:employee, employee_id: "EMP00005", email: "e@acme.test", country: "United States",
                         currency: "USD", base_salary: 120_000)

      us_row = service.by_country[:by_country].find { |row| row[:country] == "United States" }

      # salaries: 60000, 80000, 100000, 120000 -> median = (80000 + 100000) / 2 = 90000
      expect(us_row[:median_salary]).to eq("90000.0")
    end

    it "keeps two currencies within the same country as separate rows" do
      create(:employee, employee_id: "EMP00006", email: "f@acme.test", country: "United States",
                         currency: "EUR", base_salary: 70_000)

      result = service.by_country[:by_country].select { |row| row[:country] == "United States" }

      expect(result.map { |row| row[:currency] }).to contain_exactly("USD", "EUR")
    end
  end

  describe "#by_department" do
    before do
      create(:employee, employee_id: "EMP00001", email: "a@acme.test", department: "Engineering",
                         country: "United States", currency: "USD", base_salary: 100_000)
      create(:employee, employee_id: "EMP00002", email: "b@acme.test", department: "Engineering",
                         country: "India", currency: "INR", base_salary: 1_500_000)
      create(:employee, employee_id: "EMP00003", email: "c@acme.test", department: "Sales",
                         country: "United States", currency: "USD", base_salary: 70_000)
    end

    it "groups a department that spans countries by currency separately" do
      engineering_rows = service.by_department[:by_department].select { |row| row[:department] == "Engineering" }

      expect(engineering_rows.size).to eq(2)
      usd_row = engineering_rows.find { |row| row[:currency] == "USD" }
      inr_row = engineering_rows.find { |row| row[:currency] == "INR" }
      expect(usd_row[:headcount]).to eq(1)
      expect(inr_row[:headcount]).to eq(1)
    end

    it "reports a separate row for a different department" do
      sales_row = service.by_department[:by_department].find { |row| row[:department] == "Sales" }

      expect(sales_row).to include(currency: "USD", headcount: 1, total_salary: "70000.0")
    end
  end
end
