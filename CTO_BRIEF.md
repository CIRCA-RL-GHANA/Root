# CTO Brief — PROMPT Genie Platform

**Version:** 1.0.0 · **Status:** Production-ready  
**Date:** April 2026  
**Audience:** Technical leadership, engineering management

---

## Executive Summary

PROMPT Genie is a NestJS + Flutter super-app targeting the West African market (Ghana, Nigeria). It combines four primary product verticals — digital wallets, ride-hailing, e-commerce, and social commerce — on a single platform with unified identity, loyalty currency (QPoints), and an embedded AI layer.

The v1.0 monorepo is deployable to a single VPS with minimal external dependencies and designed to scale horizontally behind a load balancer as traffic grows.

---

## System Architecture

### Component Overview

```
Mobile / Web Clients (Flutter 3.2 — Android, iOS, PWA)
                │
                ▼
        Nginx 1.25 (TLS, rate-limiting, gzip)
                │
         ┌──────┴──────┐
         │             │
  NestJS API       Flutter Web
  (port 3000)    static files
         │
    ┌────┴────────────────────┐
    │                         │
PostgreSQL 15            Redis 7
(TypeORM, 25 migrations)  (Bull queues, cache)
```

### Technology Decisions

| Decision | Rationale |
|---|---|
| NestJS (TypeScript) | Enterprise-grade, decorator-driven, DI, testable, active ecosystem |
| PostgreSQL | ACID compliance critical for financial operations; JSON columns for flexibility |
| Redis + Bull | Async job processing (OTP delivery, notifications) without blocking API |
| Socket.io | WebSocket with HTTP fallback; built-in rooms for user-scoped broadcasting |
| Flutter | Single codebase → Android + iOS + PWA; high performance; no WebView |
| Docker Compose | Simple orchestration; low operational overhead vs Kubernetes at current scale |
| Nginx | SSL termination, rate-limiting, static file serving, minimal memory footprint |
| Let's Encrypt | Zero-cost SSL with automated renewal |

---

## Codebase Metrics

| Metric | Value |
|---|---|
| Backend modules | 27 NestJS feature modules |
| Backend entities | ~77 TypeORM entities |
| DB migrations | 25 ordered migrations |
| Flutter screens | 180 screens across 12 feature modules |
| Flutter dependencies | ~30 packages |
| External runtime dependencies | PostgreSQL, Redis, SendGrid, Twilio, (optional OpenAI) |

---

## Key Technical Properties

### Security Posture

- JWT access tokens (7d) + refresh tokens (30d), separate signing secrets
- bcrypt 12-round password hashing
- AES-256 transaction PIN encryption
- Helmet middleware (CSP, HSTS, X-Frame-Options)
- Global `JwtAuthGuard` — all routes protected by default; opt-out via `@Public()`
- Joi env-var validation at startup — app refuses to start with missing secrets
- Nginx rate-limiting: 30 req/s (API), 5 req/s (auth), 100 req/s (static)
- OTP expiry: 5 minutes

### Observability

- Winston structured logging (`logs/error.log`, `logs/combined.log`)
- `LoggingInterceptor` records every HTTP request with latency
- Terminus health checks: `/health`, `/health/live`, `/health/ready`
- Docker health checks on all containers
- Nginx access logs

### Reliability

- All DB operations via TypeORM repositories with transactional support
- Bull queues for resilient async jobs (retry on failure)
- Multi-stage Docker build (non-root user, minimal attack surface)
- `synchronize: false` enforced — schema managed exclusively via migrations
- Soft-deletes on all primary entities (no data loss on delete)

### AI Layer

The platform ships with a built-in AI layer requiring no external services for core functionality:

| Capability | Implementation |
|---|---|
| NLP (intent, NER, sentiment) | `natural` + `compromise` (npm, runs locally) |
| Dynamic pricing | Rule-based surge model (demand/supply/time) |
| Fraud detection | Statistical scoring (velocity, amount anomaly, method risk) |
| Recommendations | Collaborative filtering (in-process) |
| Search | Hybrid keyword + semantic ranking |
| ML inference | TensorFlow.js (`@tensorflow/tfjs-node`) — runs in-process |

**Optional:** OpenAI API integration via `AI_API_KEY` for generative features.

---

## External Service Dependencies

| Service | Use | Critical |
|---|---|---|
| PostgreSQL | Primary data store | Yes |
| Redis | Job queues, cache | Yes |
| Twilio | OTP SMS delivery | Yes (onboarding) |
| SendGrid | Transactional email | Yes (notifications) |
| OpenAI API | Enhanced AI features | No (optional) |

---

## Scalability Path

### Current (single VPS)

- All services in one `docker-compose.prod.yml`
- Suitable for ~500 concurrent users

### Horizontal Scale (next stage)

1. Move PostgreSQL to managed instance (AWS RDS / Neon / Supabase)
2. Move Redis to managed instance (AWS ElastiCache / Upstash)
3. Add `PM2` or replicate NestJS containers behind Nginx upstream pool
4. Use S3-compatible storage for file uploads (replace `./uploads`)
5. Add APM (Datadog / New Relic / OpenTelemetry)

### Kubernetes (future)

The Docker images are Kubernetes-ready today. Migrate `docker-compose.prod.yml` to Helm chart when scale demands it.

---

## Risk Register

| Risk | Severity | Mitigation |
|---|---|---|
| Single DB instance failure | High | Managed DB with automated backups + point-in-time recovery |
| Redis failure | Medium | Bull queues retry failed jobs; app degrades but doesn't fail |
| Twilio outage | Medium | Add secondary SMS gateway (e.g. Termii for Africa) |
| JWT secret exposure | Critical | Rotate secrets via env var update + container restart |
| DB migration failure | High | Migration has `revert` command; test in staging first |
| File storage loss | Medium | Mount `./uploads` on persistent volume; add S3 sync |

---

## Deployment Runbook Summary

```bash
# 1. Validate environment
./scripts/validate-env.sh --strict

# 2. Provision SSL
make ssl DOMAIN=api.genieinprompt.app EMAIL=admin@genieinprompt.app

# 3. Deploy
make deploy

# 4. Verify
curl https://api.genieinprompt.app/api/v1/health
```

Full details in [DEPLOYMENT.md](DEPLOYMENT.md).

---

## Roadmap (Technical)

| Priority | Item |
|---|---|
| P1 | Managed database migration (PostgreSQL → AWS RDS) |
| P1 | S3-compatible file storage (replace local uploads) |
| P2 | Add distributed tracing (OpenTelemetry) |
| P2 | Staging environment (mirror of production) |
| P3 | Horizontal NestJS scaling (multiple replicas) |
| P3 | Load balancer (AWS ALB or HAProxy) |
| P4 | Kubernetes migration |
| P4 | OpenAI feature expansion (GPT-4 assistant integration) |
