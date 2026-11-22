# syntax=docker/dockerfile:1
# check=error=true

# Production image for the whole app: Rails API + the built React SPA,
# served from the same origin (see docs/architecture notes in README).
#
# Build from the repo root:   docker build -f backend/Dockerfile -t salary-app .
# Run:                        docker run -p 3000:3000 -e RAILS_MASTER_KEY=<key> salary-app

ARG RUBY_VERSION=3.3.3
ARG NODE_VERSION=20

# ---- Stage 1: build the React frontend -------------------------------
FROM docker.io/library/node:${NODE_VERSION}-slim AS frontend-build
WORKDIR /frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# ---- Stage 2: Rails base ----------------------------------------------
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS base
WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# ---- Stage 3: install gems and precompile -----------------------------
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libvips libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY backend/Gemfile backend/Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY backend/ ./
# The built SPA is served as Rails' own public assets - see
# config/routes.rb's catch-all route and ApplicationController.
COPY --from=frontend-build /frontend/dist ./public/

RUN bundle exec bootsnap precompile -j 1 --gemfile && \
    bundle exec bootsnap precompile -j 1 app/ lib/

# ---- Stage 4: final runtime image -------------------------------------
FROM base

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
