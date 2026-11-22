# Requirements — ACME Salary Management

## Goal

ACME's HR team currently manages salary data for 10,000 employees across
multiple countries using spreadsheets — a slow, error-prone, and hard-to-query
process. This project replaces that workflow with a web application that lets
a single HR Manager manage employee salary records and get quick, reliable
answers to basic questions about how the organization pays people.

## Persona

**HR Manager** — the only user of this system. There is no self-service
sign-up; the HR Manager's account is provisioned via a database seed, and
access is gated by login.

## Scope & features

- **Authentication**: session/cookie-based login for the single seeded HR
  Manager account. No registration flow.
- **Employee records**: full CRUD (create, view, edit, delete) on employee
  salary records, with these fields: employee ID, name, country, department,
  job title, employment type, hire date, manager (reporting line), base
  salary, currency, and effective date.
- **Employee directory**: server-side paginated, searchable (by name/employee
  ID), and filterable (by country, department, employment type) list view —
  essential at 10,000 rows.
- **Analytics dashboard**: headcount, total payroll, and average/median
  salary, sliceable by country and by department. Figures are always grouped
  by currency (see "Deliberately left out" below) rather than blended into a
  single number.
- **Seed data**: a script generating 10,000 realistic, internally consistent
  employee records (one currency per country) for development and demo use.

## Deliberately left out (and why)

- **Multi-currency FX conversion.** Converting all salaries into one
  reporting currency requires live or historical exchange rates, a decision
  about which rate/date to use, and ongoing maintenance — a significant
  feature on its own. Instead, analytics report figures grouped by currency.
  This avoids the more serious error of silently summing incompatible
  currencies (e.g. USD + INR) into a meaningless total.
- **Payroll processing, tax, and compliance calculations.** Each country has
  its own tax rules, statutory deductions, and payroll cycles. Modeling this
  correctly is a substantial domain on its own and isn't needed to answer the
  stated question ("how does the org pay people").
- **Multi-role permissions.** The brief names one persona (HR Manager). Adding
  roles (e.g. read-only viewer, department manager, employee self-service)
  would require a permissions model with no current requirement driving its
  design.
- **Salary history / audit trail.** Each employee record holds their current
  salary and its effective date, not a history of past changes. Historizing
  every edit is a reasonable future feature but adds schema and UI complexity
  not needed for the current goal.
- **SSO / external auth providers.** A single internal user doesn't justify
  OAuth/SSO integration; a seeded account with session-based login is
  sufficient and simpler to run and review.
- **Charts/data visualization.** The first version of analytics uses numeric
  summary cards and breakdown tables, not charts. This keeps the initial
  dashboard scope small; visualizations are a natural next iteration once the
  underlying aggregates are in place.
- **Bulk CSV import/export.** Employee records are managed one at a time
  through the UI, and the 10,000-employee dataset is produced by a seed
  script rather than an import pipeline. Import/export is a reasonable
  follow-up once core CRUD and analytics are solid.

## Technical constraints (as given)

- Rails (API-only) backend, SQLite database (used in both development and
  the deployed version)
- React (via Vite) frontend, Mantine component library
- RSpec test coverage on the backend
- Fully functional, deployed software, plus a recorded video demo
