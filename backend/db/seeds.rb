# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# --- HR Manager account -----------------------------------------------------
#
# There is exactly one user of this system (see docs/requirements.md). The
# credentials come from the environment rather than being hardcoded, so the
# same seed script is safe to run against a deployed environment without
# shipping a known password in source control.
hr_manager_email = ENV.fetch("HR_MANAGER_EMAIL", "hr-manager@acme.test")
hr_manager_password = ENV.fetch("HR_MANAGER_PASSWORD", "password123")

hr_manager = User.find_or_initialize_by(email: hr_manager_email)
hr_manager.name = "HR Manager"
hr_manager.password = hr_manager_password
hr_manager.save!

puts "Seeded HR Manager user: #{hr_manager.email}"
if ENV["HR_MANAGER_PASSWORD"].blank?
  puts "  (using default dev password 'password123' - set HR_MANAGER_PASSWORD to override)"
end

# --- Employees ---------------------------------------------------------
#
# Generates 10,000 employee records for local development and demos.
# Each country maps to exactly one currency, so analytics never has to
# reconcile mixed currencies within a single country (see
# docs/requirements.md - "no blended total payroll figure").
EmployeeSeeder.new.seed!(count: 10_000)
puts "Seeded #{Employee.count} employees."
