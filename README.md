# ACME Salary Management

A web application for the ACME HR Manager to manage salary data for 10,000
employees across multiple countries, replacing a spreadsheet-based workflow.

See [`docs/requirements.md`](docs/requirements.md) for the one-page
requirements document (goal, scope, and what's deliberately left out).

## For reviewers: quick start

**Live demo**: https://salarymanagement.fly.dev/login

| | |
|---|---|
| Email | `hr-manager@acme.test` |
| Password | `password123` |

The deployed instance has 10,000 seeded employees across 8 countries, so
the employee directory, search/filter, and dashboard analytics all have
real data to look at immediately - no setup required to review the live
app.

To run it locally instead (e.g. to step through the code while it runs),
see **Running locally** below.

## Stack

- **Backend**: Ruby on Rails (API-only), SQLite
- **Frontend**: React (Vite), Mantine, React Query, React Router
- **Testing**: RSpec (backend)

## Project layout

```
backend/   Rails API-only application
frontend/  React (Vite) single-page application
docs/      Requirements and deployment notes
fly.toml   Fly.io deployment config (see docs/deployment.md)
```

## Prerequisites

- Ruby 3.3.3 (managed via `rbenv`; `backend/.ruby-version` pins this automatically)
- Node.js 20.x and npm
- SQLite3

## Running locally

Two servers run side by side in development: Rails on port 3000, Vite on
port 5173. The Vite dev server proxies `/api/*` requests to Rails (see
`frontend/vite.config.js`), so the frontend always calls relative paths.

**Backend**

```bash
cd backend
bundle install
bin/rails db:prepare
bin/rails db:seed      # HR Manager account + 10,000 demo employees
bin/rails server -p 3000
```

**Frontend** (in a separate terminal)

```bash
cd frontend
npm install
npm run dev
```

Visit `http://localhost:5173` and sign in with `hr-manager@acme.test` /
`password123` (override via `HR_MANAGER_EMAIL`/`HR_MANAGER_PASSWORD`
before seeding).

## Running tests

**Backend (RSpec)**

```bash
cd backend
bundle exec rspec
```

86 examples covering authentication, employee validations, the seed
script, the Employees API (CRUD, search, filter, pagination), and the
analytics service.

## Deployment

Deployed to Fly.io from `backend/Dockerfile`, which builds the React
frontend and Rails backend into a single image; Rails serves the built
SPA itself from the same origin. SQLite persists on a Fly volume rather
than switching to Postgres - see `docs/requirements.md` for the
reasoning. Full deploy steps: [`docs/deployment.md`](docs/deployment.md).

## Status

All planned features are implemented: authentication, employee CRUD with
search/filter/pagination, and an analytics dashboard, backed by a
10,000-employee seed dataset, deployed and live. See `docs/` for design
decisions and reasoning.
