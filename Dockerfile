# =============================================================================
# Base — shared Node 22 Alpine image; only package manifests copied here
# so that dependency layers are cached independently of source changes.
# =============================================================================
FROM node:22-alpine AS base
WORKDIR /app
COPY package*.json ./

# =============================================================================
# Development — all dependencies (including devDependencies) installed.
# Source code is NOT copied; it is volume-mounted at runtime so that
# `node --watch` can pick up live edits without rebuilding the image.
# =============================================================================
FROM base AS development
ENV NODE_ENV=development
RUN npm ci
EXPOSE 3000
CMD ["node", "--watch", "src/index.js"]

# =============================================================================
# Builder — production dependencies only (no devDependencies).
# =============================================================================
FROM base AS builder
RUN npm ci --omit=dev

# =============================================================================
# Production — lean runtime image.
# Only the compiled/transpiled source and production node_modules are present.
# =============================================================================
FROM node:22-alpine AS production
WORKDIR /app
ENV NODE_ENV=production

# Copy production node_modules from the builder stage
COPY --from=builder /app/node_modules ./node_modules

# Copy application source and config files
COPY src/           ./src/
COPY drizzle.config.js ./
COPY package.json   ./

EXPOSE 3000
CMD ["node", "src/index.js"]
