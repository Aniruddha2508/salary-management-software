# AI usage notes

This project was built with Kiro (an agentic AI coding assistant) end to
end: requirements clarification, planning, implementation, and
deployment troubleshooting. This document describes how, not just that.

## Workflow

1. **Clarify before building.** Before any code was written, the AI
   asked structured questions about scope (persona, currency handling,
   auth model, tech stack, testing framework) rather than assuming
   defaults. Answers are captured in `docs/requirements.md`, including
   what was deliberately left out and why.
2. **Plan as a task list, not a single prompt.** The build was broken
   into 13 sequential tasks (scaffolding -> auth -> employee model ->
   seed data -> CRUD API -> CRUD UI -> analytics -> dashboard ->
   hardening -> deployment -> docs), each one a working, demoable
   increment rather than a big-bang implementation.
3. **One git branch per task, merged after verification.** Each task's
   work happened on its own branch (`feat/employees-api`,
   `feat/dashboard-ui`, `chore/polish-hardening`, etc.), verified, then
   merged into `main` - so the commit history shows how the solution
   evolved rather than one monolithic commit.
4. **Verify against the real system, not just "looks right."** The AI
   ran the actual RSpec suite, hit real HTTP endpoints with `curl`
   (including a full session-cookie login flow), and - for UI changes -
   temporarily installed Playwright to drive a real Chromium browser,
   take screenshots, and check for console errors, rather than asserting
   correctness from reading code alone. Playwright was removed again
   after each verification pass to keep it out of the shipped
   dependency tree, since frontend testing was explicitly out of scope.

## Specific bugs the AI caught through this verification, not by inspection

- **Login silently failing in the browser only.** `curl`-based checks of
  the login endpoint passed, but logging in through the actual rendered
  UI failed with "Invalid email or password" on correct credentials.
  Driving a real browser and inspecting the actual request payload (not
  just the endpoint in isolation) found a header-merge order bug in
  `apiClient.js` that was dropping `Content-Type: application/json`.
- **Seed script that "worked" at small scale but hung at 10,000 rows.**
  Timing each phase of the seeder in isolation (rather than assuming
  "it's just slow") found `range.to_a.sample` materializing a
  multi-million-element array per row for large salary ranges.
- **A CSRF rescue handler that would have silently done nothing.** While
  adding a catch-all error handler for hardening, a check against Rails'
  own documented `rescue_from` resolution order (most-recently-declared
  wins, not most-specific-class) caught that declaring `StandardError`
  last would have made it intercept exceptions meant for the more
  specific CSRF handler declared earlier - fixed by re-reading the order
  from the framework source before shipping it, not by assumption.
- **A production deploy that would have booted with zero employees.**
  Running the actual production Docker build and `db:seed` locally
  before ever touching Fly.io surfaced that `faker` was scoped to the
  `development, test` Gemfile group, which production never installs.
- **A login page redesign where elements visually overlapped.** The
  AI's own first attempt had a Mantine grid column collapse to near-zero
  width; caught by taking an actual screenshot and inspecting the
  real computed CSS widths in a headless browser, which traced the root
  cause to leftover `create-vite` boilerplate CSS from the very first
  scaffolding step, not the new component.

## Tools used

- **Kiro** (agentic coding assistant) for planning, implementation,
  debugging, and git/GitHub operations.
- **RSpec + FactoryBot** for backend tests (86 examples).
- **Playwright** (installed and removed per verification pass) for
  real-browser UI checks: login flows, CRUD operations, responsive
  layout at desktop and mobile viewports, and console-error detection.
- **Fly.io** for deployment; debugging a real `Missing secret_key_base`
  production error live via deploy logs.
