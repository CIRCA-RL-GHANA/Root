# Deployment Guide

This document covers production deployment for the PROMPT Genie platform using Docker Compose, Nginx, and Let's Encrypt SSL on a Linux server.

---

## Table of Contents

1. [Infrastructure Requirements](#infrastructure-requirements)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Server Preparation](#server-preparation)
4. [Environment Configuration](#environment-configuration)
5. [SSL / TLS Setup](#ssl--tls-setup)
6. [Database Bootstrap](#database-bootstrap)
7. [Deploy](#deploy)
8. [Post-Deployment Verification](#post-deployment-verification)
9. [Zero-Downtime Updates](#zero-downtime-updates)
10. [Rollback Procedure](#rollback-procedure)
11. [Monitoring & Logs](#monitoring--logs)
12. [Backup & Recovery](#backup--recovery)
13. [CI/CD Integration](#cicd-integration)

---

## Infrastructure Requirements

### Minimum (staging / small production)

| Resource | Minimum |
|---|---|
| CPU | 2 vCPUs |
| RAM | 4 GB |
| Storage | 40 GB SSD |
| OS | Ubuntu 22.04 LTS |
| Outbound | 443, 80 open |
| Inbound | 22 (SSH), 80, 443 |

### Recommended (production)

| Resource | Recommended |
|---|---|
| CPU | 4 vCPUs |
| RAM | 8 GB |
| Storage | 80 GB SSD |
| Database | Separate managed PostgreSQL 15 |
| Cache | Separate managed Redis 7 |

### Software Dependencies

| Software | Version |
|---|---|
| Docker | ≥ 24.0 |
| Docker Compose | ≥ 2.20 (V2 CLI plugin) |
| Git | ≥ 2.40 |
| make | system package |

---

## Pre-Deployment Checklist

```
[ ] Domain DNS A record points to server IP
[ ] Ports 80 and 443 are open in firewall / security groups
[ ] Docker and Docker Compose V2 are installed
[ ] .env file is populated with all required values
[ ] SSL email address is set (for Certbot notifications)
[ ] DB_PASSWORD, JWT_SECRET, JWT_REFRESH_SECRET are strong random values
[ ] PIN_ENCRYPTION_KEY is a 32-character hex string
[ ] SENDGRID_API_KEY and Twilio credentials are valid
[ ] CORS_ORIGIN includes your production frontend domain
[ ] DB_SYNCHRONIZE is set to false
```

---

## Server Preparation

### 1. Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Install Docker Compose Plugin

```bash
sudo apt-get install -y docker-compose-plugin
docker compose version   # must be v2.x
```

### 3. Install make

```bash
sudo apt-get install -y make
```

### 4. Clone Repository

```bash
git clone <repo-url> /opt/promptgenie
cd /opt/promptgenie
```

### 5. Set Script Permissions

```bash
chmod +x scripts/*.sh deploy.sh setup-production.sh
```

---

## Environment Configuration

```bash
cp orionstack-backend--main/.env.example orionstack-backend--main/.env
nano orionstack-backend--main/.env
```

All **required** variables must be set before deployment. See [ENVIRONMENT.md](ENVIRONMENT.md) for the full reference.

### Generate Secure Secrets

```bash
# JWT secret
openssl rand -base64 48

# JWT refresh secret (must differ from JWT_SECRET)
openssl rand -base64 48

# AES-256 PIN encryption key (32 hex chars)
openssl rand -hex 32

# PostgreSQL password
openssl rand -base64 32 | tr -d '/+=' | head -c 32
```

### Validate Environment

```bash
./scripts/validate-env.sh --strict
```

This script checks that all required variables are present and not left as placeholder values.

---

## SSL / TLS Setup

SSL must be provisioned before starting the full stack (Nginx requires valid certs).

```bash
make ssl DOMAIN=api.genieinprompt.app EMAIL=admin@genieinprompt.app
```

This runs Certbot in standalone mode, issues a Let's Encrypt certificate, and places it at `/etc/letsencrypt/live/api.genieinprompt.app/`.

### Auto-Renewal

Certbot renewal is handled by the `certbot` service in `docker-compose.prod.yml`, which checks for renewal every 12 hours.

**Verify renewal works:**

```bash
docker compose -f docker-compose.prod.yml run --rm certbot renew --dry-run
```

---

## Database Bootstrap

### First Deployment Only

```bash
# Start only postgres and redis first
docker compose -f docker-compose.prod.yml up -d postgres redis

# Wait for postgres to be healthy
docker compose -f docker-compose.prod.yml ps

# Run all migrations
make migrate
```

### Migration Commands

```bash
# Apply all pending migrations
make migrate

# Or directly via npm inside container
docker compose -f docker-compose.prod.yml exec app npm run migration:run

# Check migration status
docker compose -f docker-compose.prod.yml exec app npm run migration:status

# Revert last migration (use only in emergency)
docker compose -f docker-compose.prod.yml exec app npm run migration:revert
```

**Never set `DB_SYNCHRONIZE=true` in production.** Always use migrations.

---

## Deploy

### Full Production Deployment

```bash
make deploy
```

The `make deploy` target performs these steps in order:

1. Validates `.env` file exists and is not empty
2. Checks Docker and Docker Compose are available
3. Pulls latest base images
4. Builds the NestJS application image (multi-stage Dockerfile)
5. Stops any running containers
6. Starts all services: `postgres`, `redis`, `app`, `nginx`, `certbot`
7. Waits up to 30 health-check polls for the app to become ready
8. Runs pending database migrations
9. Prints final health status

### Manual Deploy (step by step)

```bash
# Build image
docker compose -f docker-compose.prod.yml build app

# Start all services
docker compose -f docker-compose.prod.yml up -d

# Run migrations
docker compose -f docker-compose.prod.yml exec app npm run migration:run

# Verify health
curl https://api.genieinprompt.app/api/v1/health
```

---

## Post-Deployment Verification

### Health Endpoints

```bash
# Overall health (database, memory, disk)
curl https://api.genieinprompt.app/api/v1/health

# Liveness probe (quick — is the process alive?)
curl https://api.genieinprompt.app/api/v1/health/live

# Readiness probe (is the app ready to serve traffic?)
curl https://api.genieinprompt.app/api/v1/health/ready
```

All return `HTTP 200` with JSON body when healthy.

### Container Status

```bash
make status
# or
docker compose -f docker-compose.prod.yml ps
```

### Smoke Test

```bash
# Should return 401 (auth required) — confirms routing is working
curl -i https://api.genieinprompt.app/api/v1/auth/me

# Should return 200 with app info
curl https://api.genieinprompt.app/api/v1/health
```

---

## Zero-Downtime Updates

```bash
# 1. Pull latest code
git pull origin main

# 2. Build new image (without stopping running containers)
docker compose -f docker-compose.prod.yml build app

# 3. Recreate only the app container
docker compose -f docker-compose.prod.yml up -d --no-deps app

# 4. Run any new migrations
docker compose -f docker-compose.prod.yml exec app npm run migration:run

# 5. Verify
curl https://api.genieinprompt.app/api/v1/health/live
```

Nginx continues serving requests during app container restart. Downtime is limited to the container startup time (~5–10 seconds).

---

## Rollback Procedure

### Application Rollback

```bash
# Identify previous image tag
docker images promptgenie-app --format "table {{.Tag}}\t{{.CreatedAt}}"

# Roll back to previous image
docker compose -f docker-compose.prod.yml stop app
docker tag promptgenie-app:<previous-tag> promptgenie-app:latest
docker compose -f docker-compose.prod.yml up -d app
```

### Database Rollback

```bash
# Revert last migration
docker compose -f docker-compose.prod.yml exec app npm run migration:revert

# Verify
docker compose -f docker-compose.prod.yml exec app npm run migration:status
```

Only revert one migration at a time and verify application behaviour after each revert.

---

## Monitoring & Logs

### View Logs

```bash
make logs SERVICE=app        # Application logs (live tail)
make logs SERVICE=postgres   # Database logs
make logs SERVICE=nginx      # Nginx access + error logs
make logs SERVICE=redis       # Redis logs
```

### Log Files (inside containers)

| File | Contents |
|---|---|
| `logs/error.log` | Error-level logs only (JSON) |
| `logs/combined.log` | All log levels (JSON) |
| `/var/log/nginx/access.log` | All HTTP requests |
| `/var/log/nginx/error.log` | Nginx errors |

### Resource Usage

```bash
make status
# or
docker stats
```

### Service Health Check

```bash
make healthcheck
```

---

## Backup & Recovery

### Database Backup

```bash
# Manual backup
docker compose -f docker-compose.prod.yml exec postgres \
  pg_dump -U $DB_USERNAME -d $DB_NAME > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore
docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U $DB_USERNAME -d $DB_NAME < backup_20240101_120000.sql
```

### Automated Backup Schedule

Add to crontab (`crontab -e`):

```cron
# Daily database backup at 2am
0 2 * * * docker compose -f /opt/promptgenie/docker-compose.prod.yml exec -T postgres pg_dump -U postgres promptgenie_prod > /backups/db_$(date +\%Y\%m\%d).sql 2>&1

# Keep last 30 days
0 3 * * * find /backups -name "db_*.sql" -mtime +30 -delete
```

### File Uploads Backup

```bash
# Backup uploads directory
tar -czf uploads_$(date +%Y%m%d).tar.gz orionstack-backend--main/uploads/
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/promptgenie
            git pull origin main
            make deploy
```

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `SERVER_HOST` | Production server IP / hostname |
| `SERVER_USER` | SSH username |
| `SSH_PRIVATE_KEY` | Private key for server access |

---

## Service Architecture in Production

```
Internet
    │
    ▼
Nginx :443 (TLS termination, rate limiting, gzip)
    │  ├── /api/v1/*      → NestJS app:3000
    │  ├── /pwa/*         → Flutter Web static files
    │  └── /.well-known/* → Certbot ACME challenge
    │
    ▼
NestJS (app:3000)
    │  ├── PostgreSQL :5432  (TypeORM, 25 migrations)
    │  ├── Redis :6379        (Bull queues, cache)
    │  └── Socket.io /chat   (WebSocket gateway)
```

---

## Nginx Rate Limits

| Zone | Rate | Applied to |
|---|---|---|
| `api_limit` | 30 req/s | `/api/*` |
| `auth_limit` | 5 req/s | `/api/v1/auth/*` |
| `static_limit` | 100 req/s | `/pwa/*`, `/static/*` |

---

## Troubleshooting

### App fails to start

```bash
docker compose -f docker-compose.prod.yml logs app --tail 100
```

Common causes:
- Missing required environment variable (check `validate-env.sh` output)
- PostgreSQL not yet ready — app health check retries automatically
- Migration error — check `logs/error.log`

### Database connection refused

```bash
docker compose -f docker-compose.prod.yml ps postgres
docker compose -f docker-compose.prod.yml logs postgres --tail 50
```

Ensure `DB_HOST=postgres` (Docker service name, not `localhost`) in production `.env`.

### SSL certificate not found

```bash
ls /etc/letsencrypt/live/api.genieinprompt.app/
```

Rerun `make ssl` if certificates are missing or expired.

### Migration fails

```bash
docker compose -f docker-compose.prod.yml exec app npm run migration:status
```

Check for pending migrations and run `make migrate` again. If a migration fails partway, manually resolve the DB state before retrying.
