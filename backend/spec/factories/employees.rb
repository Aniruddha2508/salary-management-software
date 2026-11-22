FactoryBot.define do
  factory :employee do
    sequence(:employee_id) { |n| format("EMP%05d", n) }
    first_name { "Jane" }
    last_name { "Doe" }
    sequence(:email) { |n| "employee#{n}@acme.test" }
    country { "United States" }
    department { "Engineering" }
    job_title { "Software Engineer" }
    employment_type { "full_time" }
    hire_date { Date.new(2022, 1, 15) }
    effective_date { Date.new(2022, 1, 15) }
    base_salary { 85_000.00 }
    currency { "USD" }
    manager { nil }
  end
end
