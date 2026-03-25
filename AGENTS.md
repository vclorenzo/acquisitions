# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Commands

```bash
# Start dev server with file watching
npm run dev

# Lint
npm run lint
npm run lint:fix

# Format
npm run format
npm run format:check

# Database (requires DATABASE_URL in .env)
npm run db:generate   # generate migrations from schema changes
npm run db:migrate    # apply pending migrations
npm run db:studio     # open Drizzle Studio UI
```

There is no test suite configured yet (the eslint config referencing Jest globals is commented out).

## Environment Setup

Copy `.env.example` to `.env` and fill in:
- `DATABASE_URL` — Neon PostgreSQL connection string
- `PORT` — defaults to 3000
- `NODE_ENV` — `development` or `production`
- `LOG_LEVEL` — e.g. `info`, `debug`
- `JWT_SECRET` — secret used to sign JWTs (falls back to `'test'` if missing)

## Architecture

This is an Express 5 REST API backed by a Neon serverless PostgreSQL database, using Drizzle ORM. It is an ESM project (`"type": "module"`).

### Request Lifecycle

```
HTTP Request
  → Express middlewares (helmet, cors, morgan, cookieParser)
  → Routes (src/routes/*.routes.js)
  → Controllers (src/controllers/*.controller.js)   ← Zod validation here
  → Services (src/services/*.service.js)             ← business logic + DB access
  → Drizzle ORM (src/config/database.js → Neon)
```

### Path Aliases

Internal imports use Node `imports` aliases (defined in `package.json`) rather than relative paths:

| Alias | Maps to |
|---|---|
| `#config/*` | `src/config/*` |
| `#controllers/*` | `src/controllers/*` |
| `#middleware/*` | `src/middleware/*` |
| `#models/*` | `src/models/*` |
| `#routes/*` | `src/routes/*` |
| `#services/*` | `src/services/*` |
| `#utils/*` | `src/utils/*` |
| `#validations/*` | `src/validations/*` |

### Key Files

- `src/app.js` — Express app setup, middleware registration, route mounting
- `src/config/database.js` — Drizzle + Neon client (exports `db` and `sql`)
- `src/config/logger.js` — Winston logger; writes to `logs/error.log` and `logs/combined.log`, console in non-production
- `drizzle.config.js` — Drizzle Kit config; schema glob is `src/models/*.js`, output is `drizzle/`

### Auth Flow

- **Sign-up** (`POST /api/auth/sign-up`): validates with Zod → hashes password with bcrypt (10 rounds) → inserts user → signs JWT → sets `token` cookie (15 min, `httpOnly`, `sameSite: strict`)
- **Sign-in / Sign-out** (`POST /api/auth/sign-in|sign-out`): stubs only — not yet implemented
- JWT is signed/verified via `src/utils/jwt.js` (`jwtToken.sign` / `jwtToken.verify`); secret from `JWT_SECRET` env var, expires in 1 day

### Database Schema

Only one table exists: `users` (defined in `src/models/user.model.js`) with columns `id`, `name`, `email`, `password`, `role` (default `'user'`), `created_at`, `updated_at`. Migrations live in `drizzle/`.

### Conventions

- Validation schemas live in `src/validations/` and use Zod. Validation errors are formatted via `src/utils/format.js#formatValidationError`.
- Cookie helpers are centralised in `src/utils/cookies.js` (use `cookies.set`, `cookies.get`, `cookies.clear`).
- All logging goes through the Winston logger from `#config/logger.js` — do not use `console.log` except in `src/server.js`.
- When adding a new resource, follow the pattern: model → validation → service → controller → route → mount in `app.js`.
