# Trade-offs and known rough edges

Scope trade-offs (what's deliberately left out and why) are covered in
`docs/requirements.md`. This document covers technical/implementation
trade-offs made while building.

## Dependency version pins

- **Vite pinned to 5.4.x, not the latest major (8.x).** Vite 8 ships a
  Rolldown-based bundler with native binaries that failed to load on the
  development Node version (20.12.2) with a `Cannot find module` error on
  every build. Vite 5 is still a current, widely-used stable line.
- **Mantine pinned to 7.17.x, not 9.x.** Mantine 9 requires React 19;
  this project is on React 18 (chosen to pair with the Vite 5 pin above).
  `@mantine/charts` is pinned to the exact same `7.17.8` patch version as
  `@mantine/core`, since it's a peer dependency with an exact-version
  requirement.
- Two Dependabot PRs (Vite 8, Mantine/core 9) should **not** be merged
  without re-doing this compatibility work first.
- `recharts` is on the 2.x line (not 3.x) because `@mantine/charts@7`
  requires it as a peer dependency. 2.x is in maintenance mode upstream;
  this is accepted for now since swapping would mean dropping Mantine's
  chart wrapper entirely.

## Performance

- Adding charts (`@mantine/charts` + `recharts`) roughly doubled the
  frontend JS bundle (498KB -> 927KB minified, 157KB -> 274KB gzipped).
  Not code-split, since this is a single-page internal tool rather than
  a public site sensitive to first-load size on slow connections - would
  revisit with dynamic `import()` if that changed.
- The employees list is always paginated server-side (default 25/page,
  capped at 100) rather than loading all 10,000 rows into the browser.

## Manager assignment UX

The employee create/edit form takes the manager's **internal database
id** (a plain number) rather than an autocomplete/search picker by name.
Building a proper picker means a second lookup API call, debounced
search-as-you-type, and a selection UI - reasonable scope for a future
iteration, not justified for the first version given the HR Manager can
see any employee's internal id on their detail page.

## Testing

- RSpec on the backend only (86 examples); no frontend test suite. This
  was an explicit scope choice, not an oversight - confirmed early in
  planning. Manual verification of UI changes was done with scripted
  Playwright checks (installed temporarily, removed after each use) and
  real screenshots rather than skipped entirely.
- Model/request specs use FactoryBot, not fixtures - easier to vary one
  field per test without maintaining a shared fixture file.

## Security

- No rate limiting or brute-force lockout on login. Single internal user,
  not internet-facing in the sense of needing to defend against
  credential-stuffing at scale; would add if this became multi-tenant.
- CSRF protection is custom-wired rather than using Rails' default view-
  based token embedding, since this is an API-only app with a JS client:
  the SPA fetches a token from `/api/v1/csrf_token` once and attaches it
  as `X-CSRF-Token` on every mutating request. `ActionController::API`
  omits `RequestForgeryProtection` by default; it's re-included in
  `ApplicationController` specifically for this.
- `RAILS_MASTER_KEY` is never committed; it's read from `config/master.key`
  locally (gitignored) and set as a Fly.io secret in production - not
  baked into `backend/Dockerfile`, even though that would have been a few
  minutes faster when debugging a failed deploy.

## Things a real bug turned up mid-build (see docs/ai-usage.md for how
these were caught)

- A header-merge bug in the frontend's `apiClient.js` silently dropped
  `Content-Type: application/json` on every mutating request, making
  every real login attempt fail with "Invalid email or password" even
  with correct credentials.
- `salary_range.to_a.sample` in the seed script materialized a
  multi-million-element array per row for large salary ranges, making
  `db:seed` take minutes instead of seconds.
- Leftover Vite starter CSS (`body { display: flex; place-items: center }`)
  silently made every full-width layout shrink-wrap to its content,
  invisible until the login page redesign needed real width.
- `faker` was scoped to the `development, test` Gemfile group, which
  would have crashed `db:seed` in production with an uninitialized
  constant error - production never has dev/test gems installed.
