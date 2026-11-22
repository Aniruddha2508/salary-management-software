# ACME Salary Management

A web application for the ACME HR Manager to manage salary data for 10,000
employees across multiple countries, replacing a spreadsheet-based workflow.

See [`docs/requirements.md`](docs/requirements.md) for the one-page
requirements document (goal, scope, and what's deliberately left out).

## Stack

- **Backend**: Ruby on Rails (API-only), SQLite
- **Frontend**: React (Vite), Mantine, React Query, React Router
- **Testing**: RSpec (backend)

## Project layout

```
backend/   Rails API-only application
frontend/  React (Vite) single-page application
docs/      Requirements, architecture, trade-offs, AI usage notes
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

## Deployment

See [`docs/deployment.md`](docs/deployment.md) for building the
production Docker image and deploying to Fly.io (or Render).

## Status

All planned features are implemented: authentication, employee CRUD with
search/filter/pagination, and an analytics dashboard, backed by a
10,000-employee seed dataset. See `docs/` for design decisions and
reasoning.
