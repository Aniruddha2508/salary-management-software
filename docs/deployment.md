# Deployment

The deployed version uses the same stack as development: Rails API +
SQLite, with the built React SPA served by Rails itself from the same
origin (see `docs/architecture.md` decision #6). SQLite's single file
persists on a Fly.io volume rather than switching to Postgres - see
`docs/requirements.md` for the reasoning.

## How the production image is built

`backend/Dockerfile` is a multi-stage build:

1. **frontend-build** - a Node image runs `npm run build` on `frontend/`,
   producing static JS/CSS/`index.html`.
2. The Rails image copies that build output into `public/`, so Rails
   serves it directly. `config/routes.rb` has a catch-all route
   (`StaticController#index`) that serves `public/index.html` for any
   non-API GET request, so client-side routes like `/employees/42` work
   correctly on a full page load.
3. The final image runs `bin/rails server` on port 3000. The entrypoint
   script (`bin/docker-entrypoint`) runs `rails db:prepare` on boot,
   applying migrations against the persisted SQLite file.

Because the build context needs both `frontend/` and `backend/`, build
from the **repo root**, not from inside `backend/`:

```bash
docker build -f backend/Dockerfile -t salary-app .
docker run -p 3000:3000 -e RAILS_MASTER_KEY=<value from backend/config/master.key> salary-app
```

## Deploying to Fly.io

`fly.toml` (repo root) is already configured: it points at
`backend/Dockerfile`, sets `RAILS_ENV=production`, and mounts a
persistent volume at `/rails/storage` so the SQLite file survives
deploys and restarts.

```bash
# One-time setup
fly auth login
fly launch --no-deploy        # creates the app from fly.toml, skip the first deploy prompt
fly volumes create salary_management_data --region iad --size 1
fly secrets set RAILS_MASTER_KEY=$(cat backend/config/master.key)

# Deploy
fly deploy

# Seed the HR Manager account and the 10,000 demo employees once, after
# the first successful deploy
fly ssh console -C "/rails/bin/rails db:seed"
```

Set a real HR Manager password rather than the local dev default before
seeding in production:

```bash
fly secrets set HR_MANAGER_PASSWORD='a-real-password' HR_MANAGER_EMAIL='hr-manager@acme.test'
```

## Deploying to Render (alternative)

Render's Docker-based "Web Service" works the same way: point it at
`backend/Dockerfile` with the repo root as the build context, attach a
persistent disk mounted at `/rails/storage`, and set `RAILS_MASTER_KEY`
(and optionally `HR_MANAGER_EMAIL`/`HR_MANAGER_PASSWORD`) as environment
variables. Run the seed command once via Render's shell after the first
deploy, the same as the `fly ssh console` step above.

## Verifying a deploy

```bash
curl https://<your-app>.fly.dev/api/v1/health   # {"status":"ok"}
curl https://<your-app>.fly.dev/up              # Rails' own health check
```

Then visit the app in a browser and sign in with the HR Manager
credentials to confirm the full flow end to end.
