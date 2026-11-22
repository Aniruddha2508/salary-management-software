# Generates realistic, internally consistent Employee records for
# development/demo use.
#
# Design choices:
# - Each country maps to exactly one currency (COUNTRIES below), so
#   analytics never has to reconcile mixed currencies within a country.
# - Salary ranges are per-country and per-level, so aggregates look
#   plausible (managers earn more than ICs, US salary numbers look like
#   US salaries, etc.) rather than being pure random noise.
# - A small org hierarchy (executive -> manager -> individual
#   contributor) gives manager_id a believable reporting line, scoped to
#   employees in the same country.
# - Records are bulk-inserted with insert_all in batches, which is what
#   makes `rails db:seed` finish in a few seconds instead of minutes.
class EmployeeSeeder
  COUNTRIES = {
    "United States" => "USD",
    "United Kingdom" => "GBP",
    "India" => "INR",
    "Germany" => "EUR",
    "Canada" => "CAD",
    "Australia" => "AUD",
    "Singapore" => "SGD",
    "Japan" => "JPY",
  }.freeze

  DEPARTMENTS = ["Engineering", "Sales", "Marketing", "Finance", "Human Resources",
                 "Customer Support", "Product", "Operations", "Legal"].freeze

  TITLES_BY_LEVEL = {
    executive: ["VP", "Director"],
    manager: ["Engineering Manager", "Sales Manager", "Finance Manager", "Team Lead"],
    individual_contributor: ["Software Engineer", "Account Executive", "Marketing Specialist",
                              "Financial Analyst", "HR Generalist", "Support Specialist",
                              "Product Manager", "Operations Analyst", "Legal Counsel"],
  }.freeze

  # Base annual salary range per level, in the country's own currency.
  # Scaled to roughly match that currency's typical magnitude - not
  # economically precise, just plausible enough for aggregates to look
  # sensible (e.g. an "average salary by country" view).
  SALARY_RANGES = {
    "USD" => { executive: 180_000..260_000, manager: 120_000..170_000, individual_contributor: 65_000..115_000 },
    "GBP" => { executive: 140_000..200_000, manager: 90_000..130_000, individual_contributor: 45_000..85_000 },
    "INR" => { executive: 4_000_000..7_000_000, manager: 2_000_000..3_800_000, individual_contributor: 700_000..1_800_000 },
    "EUR" => { executive: 150_000..220_000, manager: 95_000..140_000, individual_contributor: 50_000..90_000 },
    "CAD" => { executive: 190_000..270_000, manager: 125_000..180_000, individual_contributor: 68_000..120_000 },
    "AUD" => { executive: 200_000..280_000, manager: 130_000..190_000, individual_contributor: 72_000..125_000 },
    "SGD" => { executive: 220_000..320_000, manager: 140_000..210_000, individual_contributor: 78_000..140_000 },
    "JPY" => { executive: 18_000_000..28_000_000, manager: 11_000_000..17_000_000, individual_contributor: 5_000_000..9_500_000 },
  }.freeze

  # Roughly 2% executives, 13% managers, 85% individual contributors -
  # a realistic-looking org pyramid.
  LEVEL_WEIGHTS = { executive: 0.02, manager: 0.13, individual_contributor: 0.85 }.freeze

  INSERT_BATCH_SIZE = 1_000

  def seed!(count:)
    Employee.delete_all

    rows = build_rows(count)
    insert_in_batches(rows)
    link_managers(rows)

    Rails.logger.info("Seeded #{rows.size} employees across #{COUNTRIES.size} countries.")
  end

  private

  def build_rows(count)
    levels = level_assignments(count)
    now = Time.current

    levels.each_with_index.map do |level, index|
      country, currency = COUNTRIES.to_a.sample
      salary_range = SALARY_RANGES.fetch(currency).fetch(level)
      hire_date = Faker::Date.between(from: 10.years.ago, to: 6.months.ago)
      employee_id = format("EMP%05d", index + 1)

      {
        employee_id: employee_id,
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        email: "employee#{employee_id.delete_prefix('EMP').downcase}@acme.test",
        country: country,
        department: DEPARTMENTS.sample,
        job_title: TITLES_BY_LEVEL.fetch(level).sample,
        employment_type: weighted_employment_type,
        hire_date: hire_date,
        effective_date: hire_date,
        base_salary: rand(salary_range),
        currency: currency,
        level: level, # not a DB column - stripped before insert, used by link_managers
        created_at: now,
        updated_at: now,
      }
    end
  end

  # Mostly full-time, as is typical for a large org, with a modest mix
  # of part-time/contract.
  def weighted_employment_type
    [:full_time, :full_time, :full_time, :full_time, :part_time, :contract].sample.to_s
  end

  # Returns an array of level symbols, one per employee-to-be, matching
  # LEVEL_WEIGHTS proportions as closely as integer rounding allows.
  def level_assignments(count)
    levels = LEVEL_WEIGHTS.flat_map { |level, weight| Array.new((count * weight).round, level) }
    levels = levels.first(count) if levels.size > count
    levels.push(:individual_contributor) while levels.size < count
    levels.shuffle
  end

  def insert_in_batches(rows)
    rows.each_slice(INSERT_BATCH_SIZE) do |batch|
      columns = batch.map { |row| row.except(:level) }
      Employee.insert_all(columns) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  # Assigns manager_id to every non-executive row, choosing a manager or
  # executive from the same country, then writes it in bulk per country.
  # Done as a second pass (after insert) so manager_id can reference the
  # real auto-incremented id rather than a temporary placeholder.
  def link_managers(rows)
    id_by_employee_id = Employee.pluck(:employee_id, :id).to_h

    rows.group_by { |row| row[:country] }.each_value do |country_rows|
      executive_ids = country_rows.select { |r| r[:level] == :executive }.map { |r| id_by_employee_id[r[:employee_id]] }
      manager_ids = country_rows.select { |r| r[:level] == :manager }.map { |r| id_by_employee_id[r[:employee_id]] }
      next if executive_ids.empty?

      updates_by_manager = Hash.new { |h, k| h[k] = [] }

      country_rows.each do |row|
        next if row[:level] == :executive

        pool = row[:level] == :manager ? executive_ids : (manager_ids + executive_ids)
        manager_id = pool.sample
        updates_by_manager[manager_id] << id_by_employee_id[row[:employee_id]]
      end

      updates_by_manager.each do |manager_id, employee_db_ids|
        Employee.where(id: employee_db_ids).update_all(manager_id: manager_id) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
