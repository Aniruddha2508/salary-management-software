# Computes salary aggregates (headcount, total/average/median pay) for the
# HR Manager dashboard.
#
# Figures are always grouped by currency, never blended across currencies
# (see docs/requirements.md - "no blended total payroll figure"). A country
# or department can in principle contain more than one currency (e.g. a
# department spans multiple countries, or someone manually created a mixed
# record), so every grouping includes currency as part of the group key
# rather than assuming a 1:1 mapping.
#
# Median is computed in Ruby rather than SQL: neither SQLite nor many other
# databases have a portable built-in median, and at this data size (10k
# rows) pulling the raw (group_key, currency, base_salary) tuples and
# aggregating in memory is both simpler and fast enough.
class AnalyticsService
  def summary
    rows = Employee.pluck(:currency, :base_salary).map { |currency, salary| [currency, currency, salary] }

    {
      overall_headcount: Employee.count,
      by_currency: aggregate(rows).map { |row| row.except(:group_key).merge(currency: row[:group_key]) },
    }
  end

  def by_country
    rows = Employee.pluck(:country, :currency, :base_salary)
    { by_country: aggregate(rows).map { |row| row.merge(country: row.delete(:group_key)) } }
  end

  def by_department
    rows = Employee.pluck(:department, :currency, :base_salary)
    { by_department: aggregate(rows).map { |row| row.merge(department: row.delete(:group_key)) } }
  end

  private

  # rows: Array of [group_key, currency, base_salary]
  def aggregate(rows)
    rows
      .group_by { |group_key, currency, _salary| [group_key, currency] }
      .map { |(group_key, currency), entries| summarize(group_key, currency, entries) }
      .sort_by { |row| [row[:group_key].to_s, row[:currency].to_s] }
  end

  def summarize(group_key, currency, entries)
    salaries = entries.map { |_, _, salary| salary.to_d }.sort
    total = salaries.sum

    {
      group_key: group_key,
      currency: currency,
      headcount: salaries.size,
      total_salary: total.to_s,
      average_salary: (total / salaries.size).round(2).to_s,
      median_salary: median(salaries).to_s,
    }
  end

  def median(sorted_values)
    n = sorted_values.size
    return BigDecimal("0") if n.zero?

    mid = n / 2
    if n.odd?
      sorted_values[mid]
    else
      ((sorted_values[mid - 1] + sorted_values[mid]) / 2).round(2)
    end
  end
end
