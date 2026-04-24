# Environment Variables Reference

All environment variables for the NestJS backend are validated at application startup using Joi. Missing or invalid required values will prevent the application from starting.

Place these values in `orionstack-backend--main/.env`.  
**Never commit `.env` to version control.**

---

## Application

| Variable | Required | Default | Description |
|---|---|---|---|
| `NODE_ENV` | ✅ | `development` | Runtime environment: `development` \| `production` \| `test` |
| `PORT` | ❌ | `3000` | HTTP port the NestJS server listens on |
| `API_PREFIX` | ❌ | `api` | URL path prefix for all routes |
| `API_VERSION` | ❌ | `v1` | API version segment (`/api/v1/`) |

```env
NODE_ENV=production
PORT=3000
API_PREFIX=api
API_VERSION=v1
```

---

## Database (PostgreSQL)

| Variable | Required | Description |
|---|---|---|
| `DB_HOST` | ✅ | PostgreSQL hostname. Use `postgres` inside Docker, `localhost` outside |
| `DB_PORT` | ✅ | PostgreSQL port (default `5432`) |
| `DB_USERNAME` | ✅ | PostgreSQL username |
| `DB_PASSWORD` | ✅ | PostgreSQL password (use a strong random value in production) |
| `DB_NAME` | ✅ | Database name |
| `DB_SYNCHRONIZE` | ✅ | **Must be `false` in production.** Use migrations instead |
| `DB_LOGGING` | ❌ | Set `true` to log all SQL queries (development only) |
| `DB_SSL` | ❌ | Set `true` for managed DB with SSL (e.g. AWS RDS, Neon) |

```env
DB_HOST=postgres
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=<strong-random-32-chars>
DB_NAME=promptgenie_prod
DB_SYNCHRONIZE=false
DB_LOGGING=false
DB_SSL=false
```

---

## JWT Authentication

| Variable | Required | Description |
|---|---|---|
| `JWT_SECRET` | ✅ | Secret for signing access tokens. Base64, ≥ 48 chars |
| `JWT_EXPIRES_IN` | ❌ | Access token lifetime (default `7d`) |
| `JWT_REFRESH_SECRET` | ✅ | Secret for signing refresh tokens. **Must differ from JWT_SECRET** |
| `JWT_REFRESH_EXPIRES_IN` | ❌ | Refresh token lifetime (default `30d`) |

```env
JWT_SECRET=<openssl rand -base64 48>
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=<different openssl rand -base64 48>
JWT_REFRESH_EXPIRES_IN=30d
```

Generate values:

```bash
openssl rand -base64 48   # run twice — use separate values for each secret
```

---

## Security

| Variable | Required | Description |
|---|---|---|
| `BCRYPT_ROUNDS` | ❌ | bcrypt salt rounds for password hashing (default `12`) |
| `OTP_EXPIRY_MINUTES` | ❌ | OTP expiry in minutes (default `5`) |
| `PIN_ENCRYPTION_KEY` | ✅ | 32-character hex key for AES-256 PIN encryption |

```env
BCRYPT_ROUNDS=12
OTP_EXPIRY_MINUTES=5
PIN_ENCRYPTION_KEY=<openssl rand -hex 32>
```

---

## Redis

| Variable | Required | Description |
|---|---|---|
| `REDIS_HOST` | ❌ | Redis hostname. Use `redis` in Docker, `localhost` outside (default `localhost`) |
| `REDIS_PORT` | ❌ | Redis port (default `6379`) |
| `REDIS_PASSWORD` | ❌ | Redis AUTH password (empty string if disabled) |
| `REDIS_DB` | ❌ | Redis database index (default `0`) |

```env
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=<strong-random>
REDIS_DB=0
```

---

## Email (SendGrid)

| Variable | Required | Description |
|---|---|---|
| `SENDGRID_API_KEY` | ✅ | SendGrid API key (starts with `SG.`) |
| `EMAIL_FROM` | ✅ | Verified sender email address |
| `EMAIL_FROM_NAME` | ❌ | Display name for outgoing emails (default `PROMPT Genie`) |

```env
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EMAIL_FROM=noreply@promptgenie.com
EMAIL_FROM_NAME=PROMPT Genie
```

---

## SMS (Twilio)

| Variable | Required | Description |
|---|---|---|
| `TWILIO_ACCOUNT_SID` | ✅ | Twilio Account SID (starts with `AC`) |
| `TWILIO_AUTH_TOKEN` | ✅ | Twilio Auth Token |
| `TWILIO_PHONE_NUMBER` | ✅ | Twilio phone number in E.164 format (e.g. `+12125551234`) |

```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+12125551234
```

---

## File Uploads

| Variable | Required | Description |
|---|---|---|
| `MAX_FILE_SIZE` | ❌ | Maximum upload size in bytes (default `10485760` = 10 MB) |
| `UPLOAD_DESTINATION` | ❌ | Upload directory path (default `./uploads`) |

```env
MAX_FILE_SIZE=10485760
UPLOAD_DESTINATION=./uploads
```

---

## Rate Limiting

| Variable | Required | Description |
|---|---|---|
| `THROTTLE_TTL` | ❌ | Time window in seconds (default `60`) |
| `THROTTLE_LIMIT` | ❌ | Max requests per window per IP (default `100`) |

```env
THROTTLE_TTL=60
THROTTLE_LIMIT=100
```

---

## CORS

| Variable | Required | Description |
|---|---|---|
| `CORS_ORIGIN` | ❌ | Comma-separated list of allowed origins, or `*` |
| `CORS_CREDENTIALS` | ❌ | Allow credentials (`true` / `false`, default `true`) |

```env
CORS_ORIGIN=https://genieinprompt.app
CORS_CREDENTIALS=true
```

---

## Logging

| Variable | Required | Description |
|---|---|---|
| `LOG_LEVEL` | ❌ | Minimum log level: `error` \| `warn` \| `info` \| `debug` \| `verbose` (default `info`) |
| `LOG_FILE_PATH` | ❌ | Directory for log files (default `./logs`) |

```env
LOG_LEVEL=info
LOG_FILE_PATH=./logs
```

Log files written:
- `logs/error.log` — error-level only (JSON)
- `logs/combined.log` — all levels (JSON)

---

## AI Services

| Variable | Required | Default | Description |
|---|---|---|---|
| `AI_ENABLED` | ❌ | `true` | Enable/disable AI services globally |
| `TENSORFLOW_ENABLED` | ❌ | `false` | Enable TensorFlow.js model inference |
| `AI_API_KEY` | ❌ | — | OpenAI API key (`sk-…`). Optional — core AI features work without it |
| `AI_BASE_URL` | ❌ | `https://api.openai.com/v1` | OpenAI-compatible API base URL |
| `AI_MODEL` | ❌ | `gpt-4o-mini` | OpenAI model identifier |
| `AI_MAX_TOKENS` | ❌ | `2048` | Max tokens per completion request |
| `AI_TEMPERATURE` | ❌ | `0.7` | Sampling temperature (0.0 – 2.0) |
| `AI_TOP_P` | ❌ | `0.9` | Nucleus sampling probability mass (0.0 – 1.0) |
| `AI_REQUEST_TIMEOUT` | ❌ | `30000` | Request timeout in milliseconds |
| `AI_FRAUD_BLOCK_THRESHOLD` | ❌ | `0.85` | Risk score ≥ this → auto-block transaction |
| `AI_FRAUD_REVIEW_THRESHOLD` | ❌ | `0.55` | Risk score ≥ this → flag for manual review |
| `AI_SURGE_MAX_MULTIPLIER` | ❌ | `3.5` | Maximum surge pricing multiplier for rides |
| `AI_PLATFORM_FEE_PCT` | ❌ | `8` | Platform fee percentage applied to ride fares |
| `ML_MODEL_PATH` | ❌ | `./ml-models` | Path to serialised ML model files |
| `FEATURE_STORE_UPDATE_INTERVAL` | ❌ | `300000` | Feature store refresh interval in milliseconds (5 min) |

```env
AI_ENABLED=true
TENSORFLOW_ENABLED=false
AI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AI_BASE_URL=https://api.openai.com/v1
AI_MODEL=gpt-4o-mini
AI_MAX_TOKENS=2048
AI_TEMPERATURE=0.7
AI_TOP_P=0.9
AI_REQUEST_TIMEOUT=30000
AI_FRAUD_BLOCK_THRESHOLD=0.85
AI_FRAUD_REVIEW_THRESHOLD=0.55
AI_SURGE_MAX_MULTIPLIER=3.5
AI_PLATFORM_FEE_PCT=8
ML_MODEL_PATH=./ml-models
FEATURE_STORE_UPDATE_INTERVAL=300000
```

---

## Google Maps

| Variable | Required | Description |
|---|---|---|
| `GOOGLE_MAPS_API_KEY` | ❌ | Google Maps API key for ride routing and geocoding. Leave empty to disable |

```env
GOOGLE_MAPS_API_KEY=
```

---

## Monitoring

| Variable | Required | Default | Description |
|---|---|---|---|
| `HEALTH_CHECK_TIMEOUT` | ❌ | `30000` | Timeout in milliseconds for health check probes |
| `METRICS_ENABLED` | ❌ | `true` | Enable Prometheus-style metrics endpoint |

```env
HEALTH_CHECK_TIMEOUT=30000
METRICS_ENABLED=true
```

---

## Payment Facilitator

| Variable | Required | Default | Description |
|---|---|---|---|
| `PAYMENT_FACILITATOR_PROVIDER` | ❌ | `mock` | Payment provider: `mock` \| `flutterwave` \| `paystack` |
| `PAYMENT_FACILITATOR_SECRET_KEY` | ❌ | `mock_key` | Secret key from your payment provider |
| `PAYMENT_FACILITATOR_PUBLIC_KEY` | ❌ | — | Public key from your payment provider |
| `PAYMENT_FACILITATOR_WEBHOOK_SECRET` | ❌ | — | Webhook signing secret for verifying provider callbacks |
| `PAYMENT_FACILITATOR_CURRENCY` | ❌ | `NGN` | Default currency code (e.g. `GHS`, `NGN`, `USD`) |
| `PAYMENT_FACILITATOR_WEBHOOK_URL` | ❌ | — | Publicly reachable URL for your webhook endpoint |

```env
PAYMENT_FACILITATOR_PROVIDER=flutterwave
PAYMENT_FACILITATOR_SECRET_KEY=CHANGE_ME
PAYMENT_FACILITATOR_PUBLIC_KEY=CHANGE_ME
PAYMENT_FACILITATOR_WEBHOOK_SECRET=CHANGE_ME
PAYMENT_FACILITATOR_CURRENCY=GHS
PAYMENT_FACILITATOR_WEBHOOK_URL=https://api.genieinprompt.app/api/v1/payments/webhook
```

---

## Q Points AI Market Maker

These variables configure the autonomous AI participant that provides liquidity in the Q Points marketplace. Leave `AI_MARKET_ENABLED=false` in production until the market maker has been fully tested.

| Variable | Required | Default | Description |
|---|---|---|---|
| `AI_MARKET_ENABLED` | ❌ | `false` | Enable the AI market-maker participant |
| `AI_PARTICIPANT_USER_ID` | ❌ | `00000000-…0001` | UUID of the AI bot's user account |
| `AI_TARGET_INVENTORY` | ❌ | `250000000000000` | Target Q Points inventory level |
| `AI_MIN_INVENTORY` | ❌ | `50000000000000` | Minimum inventory before bot stops selling |
| `AI_MAX_INVENTORY` | ❌ | `490000000000000` | Maximum inventory before bot stops buying |
| `AI_TARGET_SPREAD_PCT` | ❌ | `2.0` | Target bid/ask spread percentage |
| `AI_ORDER_BASE_QTY` | ❌ | `500` | Base order size in Q Points |
| `AI_MAX_ORDER_QTY` | ❌ | `2500` | Maximum order size per trade |
| `AI_MAX_OPEN_ORDERS` | ❌ | `10` | Maximum simultaneous open orders |
| `AI_ORDER_TTL_SECONDS` | ❌ | `300` | Time-to-live for unfilled orders (seconds) |
| `AI_RUN_INTERVAL_SECONDS` | ❌ | `30` | How often the market maker re-evaluates (seconds) |
| `AI_MIN_CASH_RESERVE_USD` | ❌ | `5000` | Minimum USD cash reserve; bot pauses buying if below this |

```env
AI_MARKET_ENABLED=false
AI_PARTICIPANT_USER_ID=00000000-0000-0000-0000-000000000001
AI_TARGET_INVENTORY=250000000000000
AI_MIN_INVENTORY=50000000000000
AI_MAX_INVENTORY=490000000000000
AI_TARGET_SPREAD_PCT=2.0
AI_ORDER_BASE_QTY=500
AI_MAX_ORDER_QTY=2500
AI_MAX_OPEN_ORDERS=10
AI_ORDER_TTL_SECONDS=300
AI_RUN_INTERVAL_SECONDS=30
AI_MIN_CASH_RESERVE_USD=5000
```

---

## Complete `.env` Template

```env
# ── Application ──────────────────────────────────────────────
NODE_ENV=production
PORT=3000
API_PREFIX=api
API_VERSION=v1

# ── Database ─────────────────────────────────────────────────
DB_HOST=postgres
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=CHANGE_ME
DB_NAME=promptgenie_prod
DB_SYNCHRONIZE=false
DB_LOGGING=false
DB_SSL=false

# ── JWT ──────────────────────────────────────────────────────
JWT_SECRET=CHANGE_ME
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=CHANGE_ME_DIFFERENT
JWT_REFRESH_EXPIRES_IN=30d

# ── Security ─────────────────────────────────────────────────
BCRYPT_ROUNDS=12
OTP_EXPIRY_MINUTES=5
PIN_ENCRYPTION_KEY=CHANGE_ME_32_HEX_CHARS

# ── Redis ────────────────────────────────────────────────────
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=CHANGE_ME
REDIS_DB=0

# ── Email (SendGrid) ─────────────────────────────────────────
SENDGRID_API_KEY=SG.CHANGE_ME
EMAIL_FROM=noreply@promptgenie.com
EMAIL_FROM_NAME=PROMPT Genie

# ── SMS (Twilio) ─────────────────────────────────────────────
TWILIO_ACCOUNT_SID=CHANGE_ME
TWILIO_AUTH_TOKEN=CHANGE_ME
TWILIO_PHONE_NUMBER=+1XXXXXXXXXX

# ── File Uploads ─────────────────────────────────────────────
MAX_FILE_SIZE=10485760
UPLOAD_DESTINATION=./uploads

# ── Rate Limiting ────────────────────────────────────────────
THROTTLE_TTL=60
THROTTLE_LIMIT=100

# ── CORS ─────────────────────────────────────────────────────
CORS_ORIGIN=https://genieinprompt.app
CORS_CREDENTIALS=true

# ── Logging ──────────────────────────────────────────────────
LOG_LEVEL=info
LOG_FILE_PATH=./logs

# ── AI Services ──────────────────────────────────────────────
AI_ENABLED=true
TENSORFLOW_ENABLED=false
AI_API_KEY=
AI_BASE_URL=https://api.openai.com/v1
AI_MODEL=gpt-4o-mini
AI_MAX_TOKENS=2048
AI_TEMPERATURE=0.7
AI_TOP_P=0.9
AI_REQUEST_TIMEOUT=30000
AI_FRAUD_BLOCK_THRESHOLD=0.85
AI_FRAUD_REVIEW_THRESHOLD=0.55
AI_SURGE_MAX_MULTIPLIER=3.5
AI_PLATFORM_FEE_PCT=8
ML_MODEL_PATH=./ml-models
FEATURE_STORE_UPDATE_INTERVAL=300000

# ── Google Maps ──────────────────────────────────────────────
GOOGLE_MAPS_API_KEY=

# ── Monitoring ───────────────────────────────────────────────
HEALTH_CHECK_TIMEOUT=30000
METRICS_ENABLED=true

# ── Payment Facilitator ───────────────────────────────────────
PAYMENT_FACILITATOR_PROVIDER=flutterwave
PAYMENT_FACILITATOR_SECRET_KEY=CHANGE_ME
PAYMENT_FACILITATOR_PUBLIC_KEY=CHANGE_ME
PAYMENT_FACILITATOR_WEBHOOK_SECRET=CHANGE_ME
PAYMENT_FACILITATOR_CURRENCY=GHS
PAYMENT_FACILITATOR_WEBHOOK_URL=https://api.genieinprompt.app/api/v1/payments/webhook

# ── Q Points AI Market Maker ──────────────────────────────────
AI_MARKET_ENABLED=false
AI_PARTICIPANT_USER_ID=00000000-0000-0000-0000-000000000001
AI_TARGET_INVENTORY=250000000000000
AI_MIN_INVENTORY=50000000000000
AI_MAX_INVENTORY=490000000000000
AI_TARGET_SPREAD_PCT=2.0
AI_ORDER_BASE_QTY=500
AI_MAX_ORDER_QTY=2500
AI_MAX_OPEN_ORDERS=10
AI_ORDER_TTL_SECONDS=300
AI_RUN_INTERVAL_SECONDS=30
AI_MIN_CASH_RESERVE_USD=5000
```

---

## Validation

The app validates all environment variables using Joi at startup (`src/config/validation.schema.ts`). If validation fails, the process exits immediately with a descriptive error.

Run the standalone validation script before deployment:

```bash
./scripts/validate-env.sh --strict
```
