# PROMPT Genie

**Version:** 1.0.0 · **Status:** Production  
Multi-role super-app for West Africa (Ghana, Nigeria) — combining financial services, ride-hailing, e-commerce, and social features in a single platform.

---

## Architecture Overview

| Layer | Technology |
|---|---|
| Backend API | NestJS 10 · TypeScript 5 · Node.js 18 |
| Database | PostgreSQL 15 |
| Cache / Queues | Redis 7 |
| Real-time | Socket.io 4 (NestJS Gateway) |
| ORM | TypeORM 0.3 |
| Mobile / Web | Flutter 3.2+ |
| State Management | Provider 6 + Riverpod 2 |
| Reverse Proxy | Nginx 1.25 |
| Containerisation | Docker + Docker Compose |
| TLS | Let's Encrypt (Certbot) |

---

## Repository Layout

```
thedep/
├── orionstack-backend--main/   # NestJS API server
│   ├── src/
│   │   ├── app.module.ts       # Root module (27 feature modules)
│   │   ├── main.ts             # Bootstrap, Helmet, CORS, Swagger
│   │   ├── config/             # Env validation (Joi), TypeORM factory
│   │   ├── database/           # Data source, migrations (13), seeds
│   │   ├── gateway/            # WebSocket chat gateway (Socket.io)
│   │   ├── common/             # Filters, interceptors, guards, DTOs
│   │   └── modules/            # 27 feature modules (see below)
│   ├── Dockerfile              # Multi-stage production image
│   └── docker-compose.yml      # Dev stack (postgres, redis, app)
├── thepg/                      # Flutter mobile + PWA app
│   ├── lib/
│   │   ├── main.dart           # App entry point
│   │   ├── core/               # Network, routing, theme, providers
│   │   ├── features/           # 12 feature modules (~180 screens)
│   │   ├── models/             # Shared data models
│   │   ├── services/           # Business logic services
│   │   └── widgets/            # Reusable UI components
│   └── pubspec.yaml
├── nginx/                      # Nginx config + conf.d/
├── docker-compose.prod.yml     # Production full-stack compose
├── Makefile                    # Operational commands
└── scripts/                    # Setup, SSL, env-validation scripts
```

---

## Backend Modules

| Module | Purpose |
|---|---|
| `auth` | JWT authentication, OTP, biometric, token refresh |
| `users` | User accounts, staff, audit logs, OTP tracking |
| `entities` | Individual / business entities, multi-branch support |
| `profiles` | Profile metadata, visibility & interaction settings |
| `entity-profiles` | Entity-extended profile data |
| `market-profiles` | Seller / market-specific profiles |
| `qpoints` | Loyalty points ledger, transfers, fraud detection |
| `subscriptions` | Subscription plan assignment |
| `wallets` | Multi-currency (GHS / NGN / USD) digital wallets |
| `payments` | Payment processing, refunds, AI fraud scoring |
| `go` | GO wallet orchestration (wallets + payments + QPoints) |
| `products` | Product catalogue, inventory, discount tiers, delivery zones |
| `orders` | Order lifecycle, fulfilment, delivery, returns |
| `rides` | Ride-hailing: booking, driver assignment, SOS, PIN verification |
| `vehicles` | Fleet management, bands, assignments, pricing |
| `favorite-drivers` | Saved driver preferences |
| `social` | Chat, posts, reactions, real-time messaging |
| `ai` | NLP, dynamic pricing, fraud, recommendations, search |
| `health` | Terminus health checks (liveness / readiness) |
| `calendar` | Event scheduling |
| `planner` | Financial planning and goals |
| `statement` | Account statements (PDF / CSV) |
| `wishlist` | Saved items |
| `files` | File upload and storage |
| `interests` | User interest tags |
| `places` | Geolocation, saved addresses |
| `gateway` | WebSocket gateway (Socket.io — real-time chat) |

---

## Flutter Feature Modules

| Feature | Screens | Purpose |
|---|---|---|
| Onboarding | 14 | Phone → OTP → registration → biometric → role → permissions |
| PROMPT | 1 | AI assistant hub (main dashboard) |
| GO | 24 | Wallet: balance, top-up, transfer, tax, reports, batch payments |
| Market | 17 | E-commerce: browse, cart, checkout, order tracking |
| Live | 23 | Fulfilment & driver operations, delivery tracking, SOS |
| QualChat | 16 | Messaging: conversations, group chat, media |
| APRIL | 7 | Finance calendar: planner, statement, wishlist |
| Updates | 13 | Social feed: posts, reactions, follow, notifications |
| Setup Dashboard | 34 | Business onboarding wizard |
| User Details | 9 | Profile, security, privacy, KYC verification |
| Utility | 9 | Settings, help, system info |
| Alerts | 12 | Notifications, system alerts, announcements |

---

## Quick Start (Development)

### Prerequisites
- Docker ≥ 24, Docker Compose ≥ 2.20
- Node.js 18+, npm 9+
- Flutter 3.2+

### Backend

```bash
cd orionstack-backend--main
cp .env.example .env         # fill in required values
docker compose up -d         # starts postgres + redis
npm install
npm run migration:run
npm run start:dev
# API available at http://localhost:3000
# Swagger docs at http://localhost:3000/api/docs (dev only)
```

### Flutter App

```bash
cd thepg
flutter pub get
flutter run                  # iOS/Android emulator or device
flutter run -d chrome        # PWA (web)
```

---

## Production Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for full step-by-step production deployment.

```bash
# Quick deploy
make deploy
```

---

## API Reference

See [API.md](API.md) for the complete REST API reference.

- **Base URL:** `https://api.example.com/api/v1`
- **Auth:** Bearer JWT (Authorization header)
- **Docs (dev):** `http://localhost:3000/api/docs`

---

## Environment Configuration

See [ENVIRONMENT.md](ENVIRONMENT.md) for all environment variable definitions and example values.

---

## Key Ports

| Service | Port |
|---|---|
| NestJS API | 3000 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| Nginx HTTP | 80 |
| Nginx HTTPS | 443 |
| WebSocket | wss://host/socket.io/chat |

---

## AI Features

The platform includes a built-in AI layer with zero external dependencies for core functionality:

- **Dynamic Pricing** — surge multiplier (1× – 3.5×) based on demand/supply/time
- **Fraud Detection** — velocity checks, amount anomalies, auto-block at risk score ≥ 0.85
- **NLP** — intent recognition, entity extraction, sentiment analysis (via `natural` + `compromise`)
- **ML Inference** — in-process model predictions via `@tensorflow/tfjs-node`
- **Recommendations** — product and ride-type collaborative filtering
- **Semantic Search** — hybrid vector + keyword product search
- **Financial Insights** — spending patterns, forecasts, financial health scoring

Optional OpenAI integration via `AI_API_KEY` environment variable.

---

## Security

- Helmet (CSP, HSTS, XSS protection)
- JWT access tokens (7d) + refresh tokens (30d)
- bcrypt 12 rounds for passwords
- AES-256 for PIN encryption
- Rate limiting: 30 req/s (API), 5 req/s (auth), 100 req/s (static)
- OTP via Twilio SMS (5-minute expiry)
- Global `JwtAuthGuard` (opt-out with `@Public()`)

---

## Makefile Commands

```bash
make deploy          # Full production deployment
make healthcheck     # Check all service health
make status          # Service status and resource usage
make logs SERVICE=app          # Tail application logs
make migrate         # Run pending DB migrations
make ssl DOMAIN=... EMAIL=...  # Provision/renew SSL certificate
```

---

## Developer Documentation

- [Backend Developer Documentation](BACKEND_DEVELOPER_DOCUMENTATION.md)
- [Frontend Developer Documentation](FRONTEND_DEVELOPER_DOCUMENTATION.md)
- [API Reference](API.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Environment Variables](ENVIRONMENT.md)
- [Quick Reference Guide](QUICK_REFERENCE_GUIDE.md)
