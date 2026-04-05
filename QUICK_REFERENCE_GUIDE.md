# Quick Reference Guide

Concise commands, patterns, and lookups for day-to-day development and operations.

---

## Table of Contents

- [Local Development](#local-development)
- [Make Commands](#make-commands)
- [Docker Commands](#docker-commands)
- [Database / Migrations](#database--migrations)
- [Backend npm Scripts](#backend-npm-scripts)
- [Flutter Commands](#flutter-commands)
- [API Endpoints Cheatsheet](#api-endpoints-cheatsheet)
- [Auth Flow Summary](#auth-flow-summary)
- [Environment Variable Checklist](#environment-variable-checklist)
- [AI Service Methods](#ai-service-methods)
- [WebSocket Events](#websocket-events)
- [Error Response Shape](#error-response-shape)
- [Deployment Checklist](#deployment-checklist)
- [AI Fraud Thresholds](#ai-fraud-thresholds)
- [Dynamic Pricing Formula](#dynamic-pricing-formula)
- [Key Port Reference](#key-port-reference)
- [Log Files](#log-files)

---

## Local Development

### Backend (NestJS)

```bash
cd orionstack-backend--main
docker compose up -d           # Start postgres + redis
npm run migration:run           # Apply migrations
npm run start:dev               # Hot-reload dev server → http://localhost:3000
```

### Flutter App

```bash
cd thepg
flutter pub get
flutter run                     # Interactive device selection
flutter run -d chrome           # PWA in browser
```

**Swagger UI (dev only):** http://localhost:3000/api/docs
**Health check:** http://localhost:3000/api/v1/health

---

## Make Commands

| Command | Description |
|---|---|
| `make deploy` | Full production deployment (preflight + build + deploy + healthcheck) |
| `make preflight` | Run pre-deployment checks without deploying |
| `make rollback` | Roll app container back to previous image (does not revert migrations) |
| `make restart` | Restart all containers |
| `make restart-app` | Rebuild and restart app container only |
| `make down` | Stop all production services |
| `make healthcheck` | Check all service health |
| `make status` | View container status and resource usage |
| `make logs SERVICE=app` | Tail application logs |
| `make logs SERVICE=postgres` | Tail database logs |
| `make logs SERVICE=nginx` | Tail Nginx logs |
| `make migrate` | Run migrations locally (requires Node.js + ts-node) |
| `make migrate-revert` | Revert last migration locally |
| `make migrate-prod` | Run migrations inside production container (compiled JS) |
| `make ssl DOMAIN=<d> EMAIL=<e>` | Provision Let's Encrypt SSL |
| `make build-backend` | Compile NestJS TypeScript only |
| `make build-docker` | Rebuild production Docker image without deploying |
| `make build-apk` | Build Android APK (release, obfuscated) |
| `make build-aab` | Build Android App Bundle for Play Store |
| `make build-ios` | Build iOS IPA |
| `make build-web` | Build Flutter PWA |
| `make setup` | Install all dependencies (backend + frontend) |
| `make dev-backend` | Start NestJS in dev mode |
| `make dev-db` | Start dev postgres + redis only |
| `make test` | Run all tests |
| `make lint` | Lint everything |
| `make clean` | Clean all build artifacts |
| `make clean-docker` | Remove all Docker containers, volumes, images |

---

## Docker Commands

```bash
# Production stack
docker compose -f docker-compose.prod.yml up -d       # Start all services
docker compose -f docker-compose.prod.yml down         # Stop all services
docker compose -f docker-compose.prod.yml ps           # Container status
docker compose -f docker-compose.prod.yml build app    # Rebuild app image

# View logs
docker compose -f docker-compose.prod.yml logs app --tail 100 -f
docker compose -f docker-compose.prod.yml logs postgres --tail 50

# Exec into container
docker compose -f docker-compose.prod.yml exec app sh
docker compose -f docker-compose.prod.yml exec postgres psql -U postgres -d ${DB_NAME:-promptgenie_prod}

# Dev stack
docker compose up -d            # Start postgres + redis (dev)
docker compose down             # Stop dev stack
```

---

## Database / Migrations

```bash
npm run migration:run           # Apply all pending migrations (local dev — requires ts-node)
npm run migration:revert        # Revert the last applied migration
npm run migration:generate      # Preview migration from current entity state
# Usage: npm run migration:generate -- -d src/database/data-source.ts -n src/database/migrations/MyMigrationName
```

**Production migration commands (run on the VPS):**
```bash
make migrate-prod               # Run migrations inside the production container

# Check which migrations have been applied:
export $(grep -E '^(DB_USERNAME|DB_NAME)=' .env | xargs)
docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U "$DB_USERNAME" -d "$DB_NAME" \
  -c "SELECT name FROM migrations ORDER BY id;"
```

> `npm run migration:run` uses `ts-node` (dev dependency) and only works locally. Use `make migrate-prod` for production.

**Initial seed (optional — creates admin user + sample data):**
```bash
cd orionstack-backend--main && npm run seed
```

### Migration Order (25 total)

1. InitialSchema
2. CreateUsersTable
3. CreateVehiclesTable
4. CreateOrdersTable
5. CreatePaymentsTable
6. CreateWalletsTable
7. CreateQPointsTable
8. CreateProductsTable
9. CreateSubscriptionsTable
10. CreateRidesTable
11. CreateSocialInteractionsTable
12. CreateIndexesAndConstraints
13. CreateQPointsMarketTables
14. CreateFacilitatorAccountsTable
15. AddUpdatedAtTriggers
16. CreateSubscriptionEntityTables
17. CreateProfileStaffAuthTables
18. CreateAITables
19. CreateSocialTables
20. CreateOrderDetailTables
21. CreateQPointsDetailTables
22. CreateVehicleDetailTables
23. CreateRideDetailTables
24. CreateProductDetailTables
25. CreateMiscTables

**Never use `DB_SYNCHRONIZE=true` in production.**

---

## Backend npm Scripts

| Script | Description |
|---|---|
| `npm run start:dev` | Development with hot reload |
| `npm run start:debug` | Debug mode (port 9229) |
| `npm run build` | Compile TypeScript → dist/ |
| `npm run start:prod` | Run compiled production build |
| `npm run lint` | ESLint with auto-fix |
| `npm test` | Unit tests |
| `npm run test:e2e` | End-to-end tests |
| `npm run test:cov` | Test coverage |

---

## Flutter Commands

```bash
flutter pub get                          # Install dependencies
flutter pub upgrade                      # Upgrade dependencies
flutter build apk --release              # Android APK
flutter build appbundle --release        # Android App Bundle (Play Store)
flutter build ios --release              # iOS
flutter build web --release              # PWA
flutter analyze                          # Dart static analysis
flutter test                             # Run unit tests
dart run build_runner build --delete-conflicting-outputs   # Code generation
./build-all.sh                           # Build all targets
```

---

## API Endpoints Cheatsheet

**Base:** `https://api.genieinprompt.app/api/v1`
**Auth:** `Authorization: Bearer <token>`

### Auth
```
POST  /auth/login              Phone + password → tokens
POST  /auth/refresh            Refresh token → new tokens
GET   /auth/me                 Current user
POST  /auth/logout             Invalidate session
```

### Products
```
POST  /products                Create product
GET   /products                List (filter: branchId, category, status, isFeatured)
GET   /products/search?q=      AI-powered search
GET   /products/:id            Get one
PUT   /products/:id            Replace
PATCH /products/:id            Partial update
DELETE /products/:id           Delete
POST  /products/:id/media      Upload media (multipart)
```

### Orders
```
POST  /orders                          Create order
GET   /orders/:id                      Get order
GET   /orders/user/:userId             User's orders
PATCH /orders/:id/status               Update status
POST  /orders/:id/fulfillment/start    Start fulfilment
POST  /orders/:id/returns              Request return
```

### Rides
```
POST  /rides                           Request ride
GET   /rides/:id                       Get ride
PATCH /rides/:id/assign-driver         Assign driver
PATCH /rides/:id/status                Update status
POST  /rides/:id/verify-rider-pin      Verify PIN
POST  /rides/:id/verify-driver-pin     Verify PIN
POST  /rides/:id/feedback              Submit rating
POST  /rides/:id/sos                   Emergency alert
```

### Vehicles
```
POST  /vehicles                        Register vehicle
GET   /vehicles                        List vehicles
PATCH /vehicles/:id/status             Change status
POST  /vehicles/bands                  Create service band
POST  /vehicles/assignments            Assign driver
PUT   /vehicles/assignments/:id/end    End assignment
POST  /vehicles/pricing                Set band pricing
```

### AI
```
POST  /ai/inferences                   Run model inference
POST  /ai/recommendations              Get recommendations
GET   /ai/models                       List models
GET   /ai/workflows/:id/status         Workflow status
```

### Payments & Wallet
```
POST  /payments                        Process payment
POST  /payments/:id/refund             Refund
GET   /payments/history                Payment history
GET   /wallets/me                      Wallet details
GET   /wallets/balance                 Balance only
```

### Health
```
GET   /health                          Full health check (DB, memory, disk)
GET   /health/live                     Liveness probe
GET   /health/ready                    Readiness probe
```

---

## Auth Flow Summary

```
1. POST /auth/login  { identifier, password }
   → { user, tokens: { accessToken, refreshToken } }

2. Every request: Authorization: Bearer <accessToken>

3. On 401: POST /auth/refresh  { refreshToken }
   → { tokens: { accessToken, refreshToken } }

4. POST /auth/logout → 204

JWT payload: { sub (userId), phoneNumber, socialUsername, wireId, iat, exp }
Access token: 7 days | Refresh token: 30 days
```

---

## Environment Variable Checklist

Required before deployment:

```
✅ NODE_ENV=production
✅ DB_HOST=postgres, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_NAME
✅ DB_SYNCHRONIZE=false
✅ JWT_SECRET (≥48 base64 chars, openssl rand -base64 48)
✅ JWT_REFRESH_SECRET (different from JWT_SECRET)
✅ PIN_ENCRYPTION_KEY (32 hex chars, openssl rand -hex 32)
✅ REDIS_HOST=redis, REDIS_PORT, REDIS_PASSWORD
✅ SENDGRID_API_KEY, EMAIL_FROM=noreply@genieinprompt.app
✅ TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER
✅ CORS_ORIGIN=https://genieinprompt.app
```

Generate secrets:
```bash
openssl rand -base64 48                              # JWT_SECRET / JWT_REFRESH_SECRET
openssl rand -hex 32                                 # PIN_ENCRYPTION_KEY
openssl rand -base64 32 | tr -d '/+=' | head -c 32  # DB_PASSWORD / REDIS_PASSWORD
```

---

## AI Service Methods (Flutter)

```dart
// Dynamic ride pricing
AiService.instance.getDynamicPricing(context)

// Fraud detection score
AiService.instance.getFraudScore(transactionData)

// Product recommendations
AiService.instance.getProductRecommendations(userId)

// Ride recommendations
AiService.instance.getRideRecommendations(userId)

// Semantic search
AiService.instance.semanticSearch(query)

// Sentiment analysis
AiService.instance.analyzeMessageSentiment(text)

// Intent detection
AiService.instance.detectMessageIntent(text)

// Financial insights
AiService.instance.getFinancialInsights(userId)

// Spending patterns
AiService.instance.getSpendingPattern(userId)

// Discount recommendation
AiService.instance.getRecommendedDiscount(userId)

// Subscription plan recommendation
AiService.instance.getRecommendedPlan(userId)

// Conversation summary
AiService.instance.summarizeConversation(sessionId)
```

### AI Insights Widget Pattern

```dart
Consumer<AIInsightsNotifier>(
  builder: (context, ai, _) {
    if (ai.insights.isEmpty) return const SizedBox.shrink();
    return Container(
      color: kModuleColor.withOpacity(0.07),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        const Icon(Icons.auto_awesome, size: 14, color: kModuleColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text('AI: ${ai.insights.first['title'] ?? ''}',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  },
),
```

---

## WebSocket Events

**URL:** `wss://api.genieinprompt.app/socket.io/chat`
**Namespace:** `/chat`

### Connect

```javascript
const socket = io('wss://api.genieinprompt.app/chat', {
  auth: { token: 'Bearer <accessToken>' }
});
```

### Client → Server

| Event | Payload |
|---|---|
| `chat:message` | `{ recipientId, content, attachments? }` |
| `chat:typing` | `{ recipientId, isTyping }` |
| `chat:read` | `{ messageId }` |

### Server → Client

| Event | Payload |
|---|---|
| `connection:confirmed` | `{ userId, socketId }` |
| `chat:message` | Message object |
| `chat:typing` | `{ senderId, isTyping }` |
| `chat:read` | `{ messageId, readAt }` |
| `presence:online` | `{ userId }` |
| `presence:offline` | `{ userId }` |

---

## Error Response Shape

```json
{
  "statusCode": 400,
  "timestamp": "2026-04-05T09:30:00.000Z",
  "path": "/api/v1/orders",
  "method": "POST",
  "error": "Bad Request",
  "message": ["amount must be a positive number"]
}
```

| Code | Meaning |
|---|---|
| 400 | Validation error |
| 401 | Missing / invalid / expired token |
| 403 | Insufficient permissions |
| 404 | Resource not found |
| 409 | Conflict (duplicate) |
| 429 | Rate limit exceeded |
| 500 | Server error |

---

## Deployment Checklist

```
[ ] DNS A record → server IP (api.genieinprompt.app)
[ ] Ports 80 + 443 open in firewall
[ ] .env populated and validated (./scripts/validate-env.sh --strict)
[ ] SSL provisioned (make ssl DOMAIN=api.genieinprompt.app EMAIL=...)
[ ] DB_SYNCHRONIZE=false
[ ] AI participant user pre-seeded (Step 12a of GO_LIVE_GUIDE — insert after migration #2 applies, before migration #13)
[ ] Migrations applied (make migrate-prod) — 25 rows in SELECT name FROM migrations
[ ] make deploy completed successfully
[ ] Health check passing (curl https://api.genieinprompt.app/api/v1/health)
[ ] Smoke test: expected 401 → curl https://api.genieinprompt.app/api/v1/auth/me
[ ] PWA live at https://genieinprompt.app
[ ] GitHub Actions secrets configured (DEPLOY_HOST, DEPLOY_USER, DEPLOY_SSH_KEY, DEPLOY_PORT)
[ ] Database backups cron configured (/backups/test_backup.sql exists and is non-empty)
```

---

## AI Fraud Thresholds

| Threshold | Value | Action |
|---|---|---|
| Block | ≥ 0.85 | Transaction auto-declined |
| Review | ≥ 0.55 | Flagged for manual review |
| Clean | < 0.55 | Allowed |

High-risk payment methods: `virtual_card`, `prepaid`, `gift_card`

---

## Dynamic Pricing Formula

```
baseFare = 5.00 + (distanceKm × 2.50) + (estimatedMinutes × 0.35)
platformFee = baseFare × 0.08
totalFare = (baseFare + platformFee) × surgeMultiplier

surgeMultiplier range: 1.0 – 3.5×
Peak hours (UTC): 07:00–09:00, 17:00–20:00
Late night (UTC): 23:00–04:00 → +20% surge floor
```

---

## Key Port Reference

| Service | Port |
|---|---|
| NestJS API | 3000 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| Nginx HTTP | 80 |
| Nginx HTTPS | 443 |

---

## Log Files

| File | Contents |
|---|---|
| `logs/error.log` | Error-level only (JSON) |
| `logs/combined.log` | All log levels (JSON) |
| `/var/log/nginx/access.log` | HTTP access log |
| `/var/log/nginx/error.log` | Nginx errors |
