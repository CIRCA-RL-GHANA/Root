# How to Go Live — Complete Step-by-Step Guide

This guide takes you from zero to a fully running production deployment of PROMPT Genie. Every step is explained plainly. You do not need prior server experience.

**Time required:** 2–3 hours on your first deployment.

---

## Table of Contents

1. [What You Need Before You Start](#1-what-you-need-before-you-start)
2. [Buy a Domain Name](#2-buy-a-domain-name)
3. [Buy a VPS (Cloud Server)](#3-buy-a-vps-cloud-server)
4. [Point Your Domain at Your Server](#4-point-your-domain-at-your-server)
5. [Connect to Your Server](#5-connect-to-your-server)
6. [Run the Server Setup Script](#6-run-the-server-setup-script)
7. [Clone the Code onto the Server](#7-clone-the-code-onto-the-server)
8. [Set Up All Third-Party Services](#8-set-up-all-third-party-services)
   - [8.1 Generate Cryptographic Secrets](#81-generate-cryptographic-secrets)
   - [8.2 SendGrid — Email](#82-sendgrid--email)
   - [8.3 Twilio — SMS](#83-twilio--sms)
   - [8.4 Flutterwave — Payments (Recommended)](#84-flutterwave--payments-recommended)
   - [8.5 Paystack — Payments (Alternative)](#85-paystack--payments-alternative)
   - [8.6 OpenAI — AI Features (Optional)](#86-openai--ai-features-optional)
   - [8.7 Google Maps — Ride Routing (Optional)](#87-google-maps--ride-routing-optional)
9. [Write Your Complete .env File](#9-write-your-complete-env-file)
10. [Get an SSL Certificate (HTTPS)](#10-get-an-ssl-certificate-https)
11. [Deploy the Backend](#11-deploy-the-backend)
12. [Run Database Migrations](#12-run-database-migrations)
13. [Verify the API Is Live](#13-verify-the-api-is-live)
14. [Deploy the PWA to Vercel](#14-deploy-the-pwa-to-vercel)
15. [Set Up Automatic Deployments (GitHub Actions)](#15-set-up-automatic-deployments-github-actions)
16. [Set Up Automated Database Backups](#16-set-up-automated-database-backups)
17. [Final Go-Live Checklist](#17-final-go-live-checklist)
18. [Troubleshooting Common Problems](#18-troubleshooting-common-problems)

---

## 1. What You Need Before You Start

Gather the following accounts and credentials. You will not be able to complete deployment without them.

### Required Accounts

| Service | What it's for | URL |
|---|---|---|
| **GitHub** | Your code is stored here | github.com |
| **Hostinger** (or DigitalOcean / Vultr) | The Linux server that runs the backend | See Step 3 |
| **Domain registrar** (Namecheap, Cloudflare, GoDaddy, etc.) | Your domain name (`genieinprompt.app`) | See Step 2 |
| **SendGrid** | Sending emails (OTP codes, receipts) | sendgrid.com |
| **Twilio** | Sending SMS (OTP codes) | twilio.com |
| **Flutterwave** or **Paystack** | Processing payments (choose one — see Section 8.4/8.5) | flutterwave.com / paystack.com |
| **Vercel** | Hosting the Flutter PWA (free tier works) | vercel.com |
| **OpenAI** *(optional)* | AI chat assistant and smart analytics | platform.openai.com |
| **Google Cloud** *(optional)* | Maps APIs for ride routing and geocoding | console.cloud.google.com |

### Required Credentials (gather these now)

- SendGrid API key — create one at sendgrid.com → Settings → API Keys
- Twilio Account SID and Auth Token — visible on your Twilio console homepage
- Twilio phone number — purchase one inside the Twilio console
- A verified sender email address in SendGrid (e.g. `noreply@genieinprompt.app`)

### Tools on Your Local Computer

You only need a terminal (command line):

- **Mac / Linux:** Terminal is pre-installed.
- **Windows:** Install [Git for Windows](https://git-scm.com/download/win) — it includes Git Bash. Use Git Bash for all commands in this guide.

---

## 2. Buy a Domain Name

If you already have `genieinprompt.app` registered, skip to Step 3.

1. Go to [namecheap.com](https://namecheap.com) (or any registrar).
2. Search for your domain name and purchase it.
3. Keep the registrar dashboard open — you will need it in Step 4.

> **Tip:** You need **two** DNS records for PROMPT Genie:
> - `api.genieinprompt.app` → points to your VPS (the backend)
> - `genieinprompt.app` → points to Vercel (the PWA — handled automatically in Step 14)

---

## 3. Buy a VPS (Cloud Server)

A VPS is a Linux computer in a data center that stays on 24/7.

### Recommended: Hostinger KVM 2

1. Go to [hostinger.com](https://hostinger.com) → VPS Hosting.
2. Choose **KVM 2** or higher:
   - 2 vCPUs, 8 GB RAM, 100 GB NVMe SSD
   - Operating System: **Ubuntu 22.04 LTS**
3. Choose a data center region closest to your users.
4. Complete purchase and wait for the provisioning email.

### What you'll receive

- A **server IP address** (e.g. `72.61.17.215`)
- A **root password** (or option to set one)
- SSH access on port 22

> **Alternatives:** DigitalOcean Droplet ($24/mo, 4 GB RAM), Vultr, Linode — all work fine with this guide.

---

## 4. Point Your Domain at Your Server

This tells the internet that `api.genieinprompt.app` lives on your server.

1. Log in to your domain registrar (Namecheap, Cloudflare, etc.).
2. Go to **DNS Management** for your domain.
3. Add an **A Record**:

   | Type | Host / Name | Value | TTL |
   |---|---|---|---|
   | A | `api` | `YOUR_SERVER_IP` | 300 (5 min) |

4. Save it.

DNS propagation takes anywhere from 2 minutes to 1 hour. You can check it with:
```bash
# Run this from your local machine
nslookup api.genieinprompt.app
```
It should eventually return your server IP. Do not proceed to Step 10 (SSL) until it does.

---

## 5. Connect to Your Server

SSH lets you type commands on your remote server from your local computer.

### From Mac / Linux / Git Bash (Windows)

```bash
ssh root@YOUR_SERVER_IP
```

You will be asked for the root password from your hosting provider email. Type it (the cursor will not move — that is normal) and press Enter.

### First time only — set up a deploy user

Once logged in as root, run this to create a dedicated non-root user:

```bash
# Create a user named "promptgenie"
adduser promptgenie

# Give it sudo access
usermod -aG sudo promptgenie

# Switch to the new user
su - promptgenie
```

> For the rest of this guide, run commands as the `promptgenie` user unless told otherwise.

---

## 6. Run the Server Setup Script

This single script installs Docker, Git, sets up a firewall, creates the app directory, and hardens the server.

While still connected via SSH:

```bash
# Switch back to root for the setup script
sudo su -

# Download and run the VPS init script from your repo
bash <(curl -s https://raw.githubusercontent.com/CIRCA-RL-GHANA/NestJs-Ready/main/scripts/vps-init.sh)
```

The script will ask you two questions:
1. **API domain:** type `api.genieinprompt.app` and press Enter
2. **SSL email:** type your email address and press Enter

The script will then automatically:
- Update the server operating system
- Create a 2 GB swap file (safety net for low-memory situations)
- Install Docker, Docker Compose, Git, and make
- Configure a firewall (UFW) to allow only ports 22, 80, and 443
- Install fail2ban (blocks brute-force SSH attacks)
- Create the `/opt/promptgenie` directory
- Issue an SSL certificate via Let's Encrypt (Certbot standalone)
- Patch `nginx/nginx.conf` with the correct SSL cert domain
- Register a nightly cron job to auto-renew the SSL certificate
- Configure logrotate for app log files

When it finishes, you will see `✓ VPS initialization complete`.

> **Warning — wrong secret names printed at end of script:** The summary printed by `vps-init.sh` at the end of its run will show `VPS_HOST`, `VPS_USER`, etc. as GitHub secret names. **These are wrong.** The actual GitHub Actions workflows in this repo require these exact names: `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_PORT`. Ignore the script's printed names and use the values from Step 15c instead.

> **CRITICAL — Do not disconnect SSH yet.**
>
> The setup script just disabled root login and password-based SSH authentication. The server now only accepts SSH key-based login. **If you close your terminal without adding your SSH public key for the `promptgenie` user, you will be locked out of the server.**
>
> While still in your current root SSH session, run this now:
> ```bash
> # Print your LOCAL machine's public key
> # (Run this in a second terminal on your local machine, then copy the output)
> cat ~/.ssh/id_ed25519.pub   # or id_rsa.pub if you use RSA
>
> # Back on the server, paste it into the promptgenie user's authorized_keys
> echo "PASTE_YOUR_PUBLIC_KEY_HERE" >> /home/promptgenie/.ssh/authorized_keys
> ```
>
> Test it works **before** closing the root session:
> ```bash
> # From a second terminal on your LOCAL machine
> ssh promptgenie@YOUR_SERVER_IP
> # Should connect without a password
> ```
>
> If it connects successfully, you can safely close the root session.

---

## 7. Clone the Code onto the Server

```bash
# Move to the app directory
cd /opt/promptgenie

# Clone the root repo (which contains docker-compose, nginx, scripts)
git clone https://github.com/CIRCA-RL-GHANA/Root.git .
```

> The `.` at the end clones into the current directory instead of creating a subfolder.

**Verify it worked:**
```bash
ls
# You should see: docker-compose.prod.yml  Makefile  nginx/  scripts/  ...
```

**Verify the nginx.conf SSL paths:**

The `nginx/nginx.conf` file ships with certificate paths set to `api.genieinprompt.app`. Confirm they match:

```bash
grep ssl_certificate nginx/nginx.conf
# Expected output:
#   ssl_certificate /etc/letsencrypt/live/api.genieinprompt.app/fullchain.pem;
#   ssl_certificate_key /etc/letsencrypt/live/api.genieinprompt.app/privkey.pem;
```

> **If you are using a different API domain** (not `api.genieinprompt.app`), update those two lines now:
> ```bash
> DOMAIN=api.yourdomain.com   # ← your actual API domain
> sed -i "s|api.genieinprompt.app|${DOMAIN}|g" nginx/nginx.conf
> grep ssl_certificate nginx/nginx.conf   # verify
> ```

> **Why this matters:** nginx will refuse to start if the certificate paths do not match files that exist on disk. This is the most common cause of `make deploy` failing at the nginx startup step (see Section 18 if this happens).

---

## 8. Set Up All Third-Party Services

Before you write your `.env` file, you need to create accounts and collect credentials from every external service PROMPT Genie depends on. Work through each subsection below and keep the values in a secure note (password manager — not a plain text file).

---

### 8.1 Generate Cryptographic Secrets

These are values you generate yourself — no account needed. Run these commands on your **local machine**.

```bash
# JWT_SECRET — signs access tokens
openssl rand -base64 48

# JWT_REFRESH_SECRET — signs refresh tokens (MUST be a different value)
openssl rand -base64 48

# PIN_ENCRYPTION_KEY — AES-256 key for encrypting transaction PINs (exactly 32 hex chars)
openssl rand -hex 32

# DB_PASSWORD — PostgreSQL password
openssl rand -base64 32 | tr -d '/+=' | head -c 32

# REDIS_PASSWORD — Redis AUTH password
openssl rand -base64 32 | tr -d '/+=' | head -c 32

# PIN_ENCRYPTION_IV — 16-byte AES IV (32 hex characters)
openssl rand -hex 16
```

Run each command separately. Copy each output into your password manager immediately. **If you lose these after deployment, your users cannot log in and all encrypted PINs become unreadable.**

> **Windows users:** Open Git Bash (installed with Git for Windows) to run these commands. PowerShell does not have `openssl` by default.

---

### 8.2 SendGrid — Email

SendGrid sends OTP verification emails, password reset emails, and transaction receipts.

**Cost:** Free tier gives 100 emails/day forever — sufficient for development and early production.

#### Create your account

1. Go to [sendgrid.com](https://sendgrid.com) and click **Start for Free**.
2. Sign up with your business email address.
3. Confirm your email when the verification message arrives.
4. Complete the brief onboarding form. For "What will you primarily use SendGrid for?" choose **Transactional**.

#### Verify your sender identity

You must prove you own the email address (or domain) that emails will come from. SendGrid will reject all sends if sender verification is not done.

**Option A — Single sender (quickest, good enough to start):**

1. In the SendGrid dashboard, go to **Settings → Sender Authentication**.
2. Click **Verify a Single Sender**.
3. Fill in the form:
   - **From Name:** `PROMPT Genie`
   - **From Email Address:** `noreply@genieinprompt.app`
   - **Reply To:** your personal/business email
   - **Company Address:** your business address
4. Click **Create**.
5. SendGrid sends a verification email to `noreply@genieinprompt.app`. Check that inbox and click the link.

**Option B — Domain authentication (recommended for production):**

1. Go to **Settings → Sender Authentication → Authenticate Your Domain**.
2. Select your DNS provider (Namecheap, Cloudflare, etc.).
3. SendGrid gives you 3 CNAME records. Add them to your domain DNS.
4. Click **Verify**. This unlocks better email deliverability.

#### Create an API key

1. Go to **Settings → API Keys → Create API Key**.
2. Name it `promptgenie-production`.
3. Select **Restricted Access**.
4. Under **Mail Send**, enable **Full Access**.
5. Click **Create & View**.
6. **Copy the key immediately** — SendGrid only shows it once. It starts with `SG.`

**Your values:**
```
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EMAIL_FROM=noreply@genieinprompt.app
EMAIL_FROM_NAME=PROMPT Genie
```

---

### 8.3 Twilio — SMS

Twilio sends OTP verification codes via SMS when users register or log in.

**Cost:** ~$0.0075–$0.05 per SMS depending on country. A trial account gives $15 credit. You need a paid account before going live with real users.

#### Create your account

1. Go to [twilio.com](https://twilio.com) and click **Sign Up**.
2. Verify your email address and phone number.

#### Get your Account SID and Auth Token

1. From the [Twilio Console homepage](https://console.twilio.com), look at the top panel.
2. Copy:
   - **Account SID** — starts with `AC`
   - **Auth Token** — click the eye icon to reveal it

#### Get a phone number

1. Go to **Phone Numbers → Manage → Buy a Number**.
2. Select your country, ensure **SMS** capability is checked, and purchase.

> **For Ghana:** Search with country filter **Ghana** and select a number with `+233` prefix, or use an international number capable of sending to Ghanaian numbers.

> **Trial account restriction:** Trial accounts can only send SMS to verified phone numbers. Add test numbers under **Phone Numbers → Verified Caller IDs**. Upgrade billing before going live.

**Your values:**
```
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+12025551234
```

E.164 format: `+` then country code then number, no spaces or dashes. Example: `+233201234567` for Ghana.

---

### 8.4 Flutterwave — Payments (Recommended)

Flutterwave is the recommended payment provider for PROMPT Genie, especially for African markets (Ghana, Nigeria, Kenya). It supports card payments, mobile money (MTN, Vodafone, AirtelTigo), and bank transfers.

**Cost:** No monthly fee. Typically 1.4% per card transaction; varies by method and country.

#### Create your business account

1. Go to [app.flutterwave.com](https://app.flutterwave.com) and click **Create an Account**.
2. Choose **Business Account** and fill in your business details.
3. Verify your email address.

#### Complete KYC verification

KYC is required before you can receive real money (1–3 business days). You can use test keys immediately while waiting.

1. Go to **Settings → Business Information**.
2. Upload government-issued ID, business registration certificate (if applicable), and director details.

#### Get your API keys

1. Go to **Settings → API Keys**.

**Test keys (use first):**
```
PAYMENT_FACILITATOR_SECRET_KEY=FLWSECK_TEST-xxxxxxxxxxxxxxxxxxxx
PAYMENT_FACILITATOR_PUBLIC_KEY=FLWPUBK_TEST-xxxxxxxxxxxxxxxxxxxx
```

**Live keys (after KYC approval):**
```
PAYMENT_FACILITATOR_SECRET_KEY=FLWSECK-xxxxxxxxxxxxxxxxxxxx
PAYMENT_FACILITATOR_PUBLIC_KEY=FLWPUBK-xxxxxxxxxxxxxxxxxxxx
```

#### Set up your webhook

1. Go to **Settings → Webhooks**.
2. Set the webhook URL to:
   ```
   https://api.genieinprompt.app/api/v1/payments/webhook
   ```
3. Generate a random **Secret Hash** string — this is your `PAYMENT_FACILITATOR_WEBHOOK_SECRET`.
4. Save.

#### Currency codes

| Country | Currency | Code |
|---|---|---|
| Ghana | Ghanaian Cedi | `GHS` |
| Nigeria | Nigerian Naira | `NGN` |
| Kenya | Kenyan Shilling | `KES` |
| United States | US Dollar | `USD` |

**Your values:**
```
PAYMENT_FACILITATOR_PROVIDER=flutterwave
PAYMENT_FACILITATOR_SECRET_KEY=FLWSECK-xxxxxxxxxxxxxxxxxxxx
PAYMENT_FACILITATOR_PUBLIC_KEY=FLWPUBK-xxxxxxxxxxxxxxxxxxxx
PAYMENT_FACILITATOR_WEBHOOK_SECRET=your-random-webhook-secret
PAYMENT_FACILITATOR_CURRENCY=GHS
PAYMENT_FACILITATOR_WEBHOOK_URL=https://api.genieinprompt.app/api/v1/payments/webhook
```

#### Test card numbers (test mode only)

| Card | Number | CVV | Expiry |
|---|---|---|---|
| Successful payment | `5531 8866 5214 2950` | `564` | `09/32` |
| Failed payment | `5258 5874 6254 9680` | `883` | `09/31` |
| Insufficient funds | `4187 4274 1556 4246` | `828` | `09/32` |

---

### 8.5 Paystack — Payments (Alternative)

Use Paystack if you are primarily serving Nigerian customers.

**Cost:** 1.5% per transaction (+ ₦100 for transactions above ₦2,500). No monthly fee.

#### Create your account and get API keys

1. Go to [dashboard.paystack.com](https://dashboard.paystack.com) and sign up.
2. Go to **Settings → API Keys & Webhooks**.
3. Copy your **Secret Key** and **Public Key** (test and live versions).

#### Set up your webhook

Under **API Keys & Webhooks → Webhook URL**, enter:
```
https://api.genieinprompt.app/api/v1/payments/webhook
```

**Your values:**
```
PAYMENT_FACILITATOR_PROVIDER=paystack
PAYMENT_FACILITATOR_SECRET_KEY=sk_live_xxxxxxxxxxxxxxxxxxxx
PAYMENT_FACILITATOR_PUBLIC_KEY=pk_live_xxxxxxxxxxxxxxxxxxxx
PAYMENT_FACILITATOR_WEBHOOK_SECRET=
PAYMENT_FACILITATOR_CURRENCY=NGN
PAYMENT_FACILITATOR_WEBHOOK_URL=https://api.genieinprompt.app/api/v1/payments/webhook
```

---

### 8.6 OpenAI — AI Features (Optional)

OpenAI powers natural language features: sentiment analysis, intent detection, conversation summaries, financial insights, and the AI assistant. The app runs without it — all AI features fall back gracefully.

**Cost:** Pay-per-use. `gpt-4o-mini` costs ~$0.15 per million input tokens — fractions of a cent per user session.

#### Create your account and API key

1. Go to [platform.openai.com](https://platform.openai.com) and sign up.
2. Go to **Settings → Billing → Add payment method**. Set a monthly spending limit.
3. Go to **API Keys → Create new secret key** → name it `promptgenie-production`.
4. **Copy the key immediately** — it starts with `sk-` and is shown only once.

**Your values:**
```
AI_ENABLED=true
TENSORFLOW_ENABLED=false
AI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AI_BASE_URL=https://api.openai.com/v1
AI_MODEL=gpt-4o-mini
AI_MAX_TOKENS=2048
AI_TEMPERATURE=0.7
AI_TOP_P=0.9
AI_REQUEST_TIMEOUT=30000
```

> If you do not want to use OpenAI yet, set `AI_API_KEY=` (blank). The app will start normally — AI features return empty/default responses instead of erroring.

---

### 8.7 Google Maps — Ride Routing (Optional)

Used to calculate ride routes, distances, and estimated times. Without it, the ride module works but cannot show turn-by-turn routing or accurate fare estimates.

**Cost:** $200 free monthly credit — covers ~40,000 map loads or ~100,000 geocoding requests per month.

#### Enable APIs and create a key

1. Go to [console.cloud.google.com](https://console.cloud.google.com) and create a project named `promptgenie`.
2. Go to **APIs & Services → Library** and enable:
   - Maps JavaScript API, Geocoding API, Directions API, Distance Matrix API, Places API
3. Go to **Credentials → Create Credentials → API Key**. Copy the key.
4. Click **Restrict Key** — add your server IP under Application restrictions; restrict to the 5 APIs above under API restrictions.

**Your value:**
```
GOOGLE_MAPS_API_KEY=AIzaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

> Leave blank to disable ride routing. The app will not crash without it.

---

## 9. Write Your Complete .env File

You now have all the values you need. Create the `.env` file on the server.

### Step 9a — Copy the template

> **Important:** The `.env` file must sit in `/opt/promptgenie/` (the same directory as `docker-compose.prod.yml`). Docker Compose reads it from there. Do **not** put it inside `orionstack-backend--main/`.

```bash
cd /opt/promptgenie
cp .env.example .env
```

### Step 9b — Open for editing

```bash
nano .env
```

`nano` is a simple text editor. Arrow keys to navigate. `Ctrl+O` to save. `Ctrl+X` to exit.

### Step 9c — Fill in all values

```env
# ── Application ───────────────────────────────────────────────────────────────
NODE_ENV=production
APP_VERSION=1.0.0
PORT=3000
BACKEND_PORT=3000
FRONTEND_PORT=5000
API_PREFIX=api
API_VERSION=v1

# ── Database ───────────────────────────────────────────────────────────────────
# DB_HOST must be "postgres" (the Docker container name) — do not change
DB_HOST=postgres
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=<paste DB_PASSWORD from Section 8.1>
DB_NAME=promptgenie_prod
# NEVER set DB_SYNCHRONIZE=true in production
DB_SYNCHRONIZE=false
DB_LOGGING=false
DB_SSL=false

# ── JWT Authentication ─────────────────────────────────────────────────────────
JWT_SECRET=<paste JWT_SECRET from Section 8.1>
JWT_EXPIRES_IN=7d
# JWT_REFRESH_SECRET must be a DIFFERENT value from JWT_SECRET
JWT_REFRESH_SECRET=<paste JWT_REFRESH_SECRET from Section 8.1>
JWT_REFRESH_EXPIRES_IN=30d

# ── Security ───────────────────────────────────────────────────────────────────
BCRYPT_ROUNDS=12
OTP_EXPIRY_MINUTES=5
PIN_ENCRYPTION_KEY=<paste PIN_ENCRYPTION_KEY from Section 8.1>
PIN_ENCRYPTION_IV=<paste PIN_ENCRYPTION_IV from Section 8.1>

# ── Redis ──────────────────────────────────────────────────────────────────────
# REDIS_HOST must be "redis" (the Docker container name) — do not change
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=<paste REDIS_PASSWORD from Section 8.1>
REDIS_DB=0

# ── Email (SendGrid) — see Section 8.2 ────────────────────────────────────────
SENDGRID_API_KEY=<paste SG.xxxx key from Section 8.2>
EMAIL_FROM=noreply@genieinprompt.app
EMAIL_FROM_NAME=PROMPT Genie
EMAIL_SUPPORT=support@genieinprompt.app

# ── SMS (Twilio) — see Section 8.3 ────────────────────────────────────────────
TWILIO_ACCOUNT_SID=<paste AC... value from Section 8.3>
TWILIO_AUTH_TOKEN=<paste auth token from Section 8.3>
TWILIO_PHONE_NUMBER=<paste +E.164 number from Section 8.3>

# ── File Uploads ───────────────────────────────────────────────────────────────
MAX_FILE_SIZE=10485760
UPLOAD_DESTINATION=./uploads

# ── Rate Limiting ──────────────────────────────────────────────────────────────
THROTTLE_TTL=60
THROTTLE_LIMIT=100
AUTH_RATE_LIMIT=5

# ── CORS ───────────────────────────────────────────────────────────────────────
# Must exactly match your PWA domain — no trailing slash
CORS_ORIGIN=https://genieinprompt.app
CORS_CREDENTIALS=true

# ── WebSocket / Socket.IO ──────────────────────────────────────────────────────
WEBSOCKET_ENABLED=true
WEBSOCKET_CORS_ORIGIN=https://genieinprompt.app

# ── Logging ────────────────────────────────────────────────────────────────────
LOG_LEVEL=info
LOG_FILE_PATH=./logs

# ── AI Services — see Section 8.6 ─────────────────────────────────────────────
AI_ENABLED=true
TENSORFLOW_ENABLED=false
AI_API_KEY=<paste sk-... key from Section 8.6, or leave blank>
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

# ── Google Maps — see Section 8.7 ─────────────────────────────────────────────
GOOGLE_MAPS_API_KEY=<paste AIza... key from Section 8.7, or leave blank>

# ── Monitoring ─────────────────────────────────────────────────────────────────
HEALTH_CHECK_TIMEOUT=30000
METRICS_ENABLED=true

# ── Payment Facilitator — see Sections 8.4 / 8.5 ─────────────────────────────
# Use "mock" for testing without real payments
PAYMENT_FACILITATOR_PROVIDER=<flutterwave or paystack or mock>
PAYMENT_FACILITATOR_SECRET_KEY=<paste secret key from Section 8.4 or 8.5>
PAYMENT_FACILITATOR_PUBLIC_KEY=<paste public key from Section 8.4 or 8.5>
PAYMENT_FACILITATOR_WEBHOOK_SECRET=<paste webhook secret from Section 8.4>
PAYMENT_FACILITATOR_CURRENCY=<GHS, NGN, KES, or USD>
PAYMENT_FACILITATOR_WEBHOOK_URL=https://api.genieinprompt.app/api/v1/payments/webhook

# ── Q Points AI Market Maker ───────────────────────────────────────────────────
# Leave AI_MARKET_ENABLED=false until fully tested
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

Save: `Ctrl+O` → Enter → `Ctrl+X`

### Step 9d — Validate your .env

```bash
cd /opt/promptgenie
./scripts/validate-env.sh --strict
```

The **root `.env` section** should be all green checkmarks. The **backend `.env` section** will show yellow warnings — this is expected. The validator auto-creates `orionstack-backend--main/.env` from the backend's `.env.example` (which contains placeholder values). In production, Docker reads config from the **root `.env` only**. You can safely ignore the backend section warnings.

**Common validation failures:**

| Error | Cause | Fix |
|---|---|---|
| `JWT_SECRET is required` | Variable is missing or empty | Paste the generated value |
| `JWT_SECRET and JWT_REFRESH_SECRET must be different` | Same value used for both | Regenerate one: `openssl rand -base64 48` |
| `PIN_ENCRYPTION_KEY must be 32 hex characters` | Wrong length or format | Run `openssl rand -hex 32` and paste exact output |
| `SENDGRID_API_KEY must start with SG.` | Wrong key pasted | Re-copy from SendGrid dashboard |
| `EMAIL_FROM must be a valid email` | Typo in email address | Fix the address |
| `DB_SYNCHRONIZE must be false in production` | Set to `true` | Change to `false` |

---

## 10. Get an SSL Certificate (HTTPS)

> **Skip this step if `vps-init.sh` completed successfully.**
> The server setup script in Step 6 already issued your SSL certificate via Certbot. Confirm with:
> ```bash
> ls /opt/promptgenie/certbot/conf/live/api.genieinprompt.app/
> # If you see fullchain.pem and privkey.pem, skip to Step 11.
> ```

> **Wait** until `nslookup api.genieinprompt.app` returns your server IP before running this.

```bash
cd /opt/promptgenie
make ssl DOMAIN=api.genieinprompt.app EMAIL=your@email.com
```

Replace `your@email.com` with your real email. Let's Encrypt sends expiry reminders there.

**Verify:**
```bash
ls /etc/letsencrypt/live/api.genieinprompt.app/
# You should see: cert.pem  chain.pem  fullchain.pem  privkey.pem
```

---

## 11. Deploy the Backend

One command builds the Docker image, starts all five services (NestJS app, PostgreSQL, Redis, Nginx, Certbot), and waits for a health check.

```bash
cd /opt/promptgenie
make deploy
```

The first build takes 3–6 minutes (compiles TypeScript, installs Node.js dependencies inside the container).

**What happens while you wait:**
1. Validates your `.env`
2. Builds the NestJS Docker image (multi-stage build)
3. Starts PostgreSQL and waits for it to be healthy
4. Starts Redis
5. Starts the NestJS app
6. Starts Nginx (ports 80 and 443)
7. Starts the Certbot renewal service
8. Polls the health endpoint until the app responds

When complete you will see `✓ Deployment complete`.

**Verify containers are running:**
```bash
make status
```

All five containers should show `Up` or `healthy`:
```
NAME                   STATUS
promptgenie-app        Up (healthy)
promptgenie-postgres   Up (healthy)
promptgenie-redis      Up (healthy)
promptgenie-nginx      Up (healthy)
promptgenie-certbot    Up
```

---

## 12. Run Database Migrations

Migrations create all the database tables. Run once on first deployment (and again when new migrations are added).

### Step 12a — Pre-seed the AI market-maker account

> **This step is mandatory.** Migration #13 (`CreateQPointsMarketTables`) inserts the AI market-maker's initial Q Points balance with a foreign-key reference to the `users` table. If the AI participant row does not exist when migration #13 runs, the entire migration run aborts with a foreign-key violation.

Run the following **once, on a fresh database, before running migrations**:

```bash
# From /opt/promptgenie on the VPS
export $(grep -E '^(DB_USERNAME|DB_NAME)=' .env | xargs)

docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U "$DB_USERNAME" -d "$DB_NAME" -c \
  "INSERT INTO users (id, email, phone_number, password_hash,
                      first_name, last_name, user_type,
                      account_status, is_email_verified, is_phone_verified)
   VALUES ('00000000-0000-0000-0000-000000000001',
           'ai-participant@system.internal', NULL,
           'SYSTEM-ACCOUNT-NO-LOGIN',
           'AI', 'Participant', 'ADMIN', 'ACTIVE', TRUE, TRUE)
   ON CONFLICT (id) DO NOTHING;"
```

**Verify the row was inserted:**
```bash
docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U "$DB_USERNAME" -d "$DB_NAME" -c \
  "SELECT id, email, user_type FROM users WHERE id = '00000000-0000-0000-0000-000000000001';"
```
Expected: one row with `email = ai-participant@system.internal` and `user_type = ADMIN`.

### Step 12b — Run all migrations

```bash
cd /opt/promptgenie
make migrate-prod
```

This runs 25 migrations in order inside the Docker container — no Node.js needed on the host. You will see each migration name print as it applies.

**Verify all migrations ran:**
```bash
export $(grep -E '^(DB_USERNAME|DB_NAME)=' .env | xargs)
docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U "$DB_USERNAME" -d "$DB_NAME" \
  -c "SELECT name FROM migrations ORDER BY id;"
```

Should return 25 rows. If a migration is missing, re-run `make migrate-prod`.

> **Note:** The GitHub Actions backend workflow also attempts `npm run migration:run` on each push, but this requires `ts-node` which is excluded from the production Docker image and silently fails. **Always run `make migrate-prod` manually on the server** whenever a deployment includes new migration files.

---

## 13. Verify the API Is Live

Run these from your **local machine** (or any browser):

### Health check
```bash
curl https://api.genieinprompt.app/api/v1/health
```
Expected response:
```json
{
  "status": "ok",
  "info": {
    "database": { "status": "up" },
    "memory_heap": { "status": "up" },
    "storage": { "status": "up" }
  }
}
```

### Auth smoke test
```bash
curl -i https://api.genieinprompt.app/api/v1/auth/me
```
Expected: `HTTP 401 Unauthorized` — this is correct. The endpoint exists and is protected.

### Additional health probes
```bash
# Liveness probe
curl https://api.genieinprompt.app/api/v1/health/live

# Readiness probe
curl https://api.genieinprompt.app/api/v1/health/ready
```
Both should return `HTTP 200`.

### WebSocket smoke test
```bash
curl -i "https://api.genieinprompt.app/socket.io/?EIO=4&transport=polling"
```
Any response other than 404 means nginx is correctly forwarding to the NestJS app. A `400 Bad Request` from Socket.IO (no auth token) is the expected result.

### What a broken deployment looks like

| Symptom | Likely cause | Fix |
|---|---|---|
| `Could not resolve host` | DNS not propagated | Wait longer |
| SSL certificate error | SSL not issued | Re-run Step 10 |
| `502 Bad Gateway` | NestJS app not running | `make logs SERVICE=app` |
| `{"status":"error"}` in health | Database connection failed | Check `DB_PASSWORD` in `.env` |

---

## 14. Deploy the PWA to Vercel

The Flutter web app (PWA) is deployed to Vercel's global CDN.

### Step 14a — Create a Vercel account

Go to [vercel.com](https://vercel.com) and sign up with your GitHub account.

### Step 14b — Import the Flutter repo

1. In Vercel, click **Add New → Project**.
2. Select the `CIRCA-RL-GHANA/Flutter-Ready` repository.
3. Vercel detects `vercel.json` in the root and configures the build automatically.
4. No environment variables are required for the default deployment.

   > **Note — API domain is a compile-time constant:** The Flutter app's backend URL is hardcoded in `thepg/lib/core/constants/env_config.dart` to `https://api.genieinprompt.app/api/v1`. The `API_BASE_URL` variable in `vercel.json` passes `--dart-define` to the build, but `env_config.dart` does **not** read it via `String.fromEnvironment(...)` — it uses a hard-coded value directly. Setting `API_BASE_URL` in the Vercel dashboard therefore has no effect.
   >
   > **If you deploy to a different backend domain**, edit `thepg/lib/core/constants/env_config.dart` — change the `production` case in both `baseUrl` (replace `https://api.genieinprompt.app/api/v1`) and `webSocketUrl` (replace `wss://api.genieinprompt.app`) — commit the change, then redeploy.

5. Click **Deploy**. First deploy takes about 4 minutes.

### Step 14c — Configure your domain on Vercel

1. In your Vercel project, go to **Settings → Domains**.
2. Add `genieinprompt.app`.
3. Add the DNS record Vercel shows you at your domain registrar:

   | Type | Name | Value |
   |---|---|---|
   | CNAME | `@` | `cname.vercel-dns.com` |
   | or A | `@` | `76.76.19.61` |

4. Back in Vercel, click **Verify**. Once green, your PWA is live at `https://genieinprompt.app`.

---

## 15. Set Up Automatic Deployments (GitHub Actions)

Every push to `main` deploys automatically. You need to add credentials as GitHub Secrets.

### Step 15a — Create a deployment SSH key (on your local machine)

```bash
# Generate a NEW key pair just for deployments — do not reuse your personal key
ssh-keygen -t ed25519 -C "promptgenie-deploy" -f ~/.ssh/promptgenie_deploy
```

This creates:
- `~/.ssh/promptgenie_deploy` — private key (goes into GitHub)
- `~/.ssh/promptgenie_deploy.pub` — public key (goes onto the server)

### Step 15b — Authorize the key on your server

```bash
# From your local machine:
ssh-copy-id -i ~/.ssh/promptgenie_deploy.pub promptgenie@YOUR_SERVER_IP
```

If `ssh-copy-id` is not available (Windows):
```bash
# Print the public key
cat ~/.ssh/promptgenie_deploy.pub
# Then on the server:
echo "PASTE_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Step 15c — Add secrets to GitHub

> **Secrets vs Variables:** Secrets (`Settings → Secrets and variables → Actions → Secrets`) are encrypted and hidden from logs. Variables (`Actions → Variables`) are plain-text and visible in logs. Use secrets for credentials; variables for non-sensitive config like URLs.

#### Root repo & Backend repo — Backend deployment secrets

Add these to both `github.com/CIRCA-RL-GHANA/Root` and `github.com/CIRCA-RL-GHANA/NestJs-Ready`:

| Secret name | Value |
|---|---|
| `DEPLOY_HOST` | Your server IP, e.g. `72.61.17.215` |
| `DEPLOY_USER` | `promptgenie` |
| `DEPLOY_SSH_KEY` | Contents of `~/.ssh/promptgenie_deploy` (starts with `-----BEGIN OPENSSH PRIVATE KEY-----`) |
| `DEPLOY_PORT` | `22` |

#### Flutter repo — Web (Vercel) secrets

Add to `github.com/CIRCA-RL-GHANA/Flutter-Ready`:

| Secret name | Value | How to get it |
|---|---|---|
| `VERCEL_TOKEN` | Vercel API token | vercel.com → Settings → Tokens → Create |
| `VERCEL_ORG_ID` | Vercel org/team ID | vercel.com → Settings → General → Team ID |
| `VERCEL_PROJECT_ID` | Vercel project ID | Vercel project → Settings → General → Project ID |

Also add these **Variables** (not secrets):

| Variable name | Value |
|---|---|
| `API_BASE_URL` | `https://api.genieinprompt.app` |
| `VERCEL_URL` | `https://genieinprompt.app` |

#### Flutter repo — Android signing secrets

**Generate the keystore (once on your local machine):**
```bash
keytool -genkey -v \
  -keystore promptgenie-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias promptgenie -storetype JKS
```

**Base64-encode for GitHub:**
```bash
# Mac / Linux
base64 -i promptgenie-release.jks | tr -d '\n'

# Git Bash on Windows
base64 -w 0 promptgenie-release.jks
```

**Copy to the correct location (gitignored):**
```bash
cp promptgenie-release.jks thepg/android/keystore/promptgenie-release.jks
```

**Add secrets to the Flutter repo:**

| Secret name | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | The base64 string above |
| `ANDROID_KEYSTORE_PASSWORD` | The keystore password you chose |
| `ANDROID_KEY_PASSWORD` | The key password you chose |
| `ANDROID_KEY_ALIAS` | `promptgenie` |

#### Flutter repo — iOS signing secrets

Only needed for App Store publishing. Requires an Apple Developer account ($99/year).

1. Create a distribution certificate at [developer.apple.com](https://developer.apple.com) → Certificates, IDs & Profiles.
2. Export as `.p12` from Keychain Access, then base64-encode: `base64 -i YourCert.p12 | tr -d '\n'`
3. Create an App Store Connect API key at [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → Users and Access → Keys.
4. Update `thepg/ios/ExportOptions.plist` with your Apple Team ID.

| Secret name | Value |
|---|---|
| `IOS_CERTIFICATE_BASE64` | Base64-encoded `.p12` |
| `IOS_CERTIFICATE_PASSWORD` | `.p12` export password |
| `APPSTORE_ISSUER_ID` | Issuer ID from App Store Connect |
| `APPSTORE_API_KEY_ID` | Key ID from App Store Connect |
| `APPSTORE_API_PRIVATE_KEY` | Raw contents of the `.p8` file |

> CI uploads to **TestFlight**. After processing (5–15 min), promote in App Store Connect → App Store → + Version → select the build → submit for review (1–2 days).

#### Flutter repo — Google Play secrets

Only needed for Play Store publishing. Requires a Google Play Console account ($25 one-time fee).

1. Create an app in Play Console with package name `com.promptgenie.app`.
2. Create a service account in the linked Google Cloud project with the **Release Manager** role.
3. Download the service account JSON key.

| Secret name | Value |
|---|---|
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | Full contents of the JSON key file |

> CI uploads to the **internal testing track**. Promote to production manually in Play Console.

### Step 15d — Test the pipeline

Push any small change to `main`:
```bash
echo "" >> README.md
git add README.md
git commit -m "test: trigger CI/CD pipeline"
git push origin main
```

Go to your repo → **Actions** tab. The workflow should start within 10 seconds and complete in 4–6 minutes.

---

## 16. Set Up Automated Database Backups

```bash
# Create the backups directory
sudo mkdir -p /backups
sudo chown promptgenie:promptgenie /backups

# Open the crontab editor
crontab -e
```

Add these lines, then save:

```cron
# Daily database backup at 2am UTC
0 2 * * * docker compose -f /opt/promptgenie/docker-compose.prod.yml exec -T postgres pg_dump -U postgres promptgenie_prod > /backups/db_$(date +\%Y\%m\%d).sql 2>&1

# Delete backups older than 30 days
0 3 * * * find /backups -name "db_*.sql" -mtime +30 -delete

# Weekly uploads backup (Sundays at 3:30am UTC)
30 3 * * 0 docker run --rm -v promptgenie_app_uploads:/source:ro -v /backups:/backup alpine tar -czf /backup/uploads_$(date +\%Y\%m\%d).tar.gz -C /source . 2>&1
```

**Test the database backup manually:**
```bash
docker compose -f /opt/promptgenie/docker-compose.prod.yml exec -T postgres \
  pg_dump -U postgres promptgenie_prod > /backups/test_backup.sql

ls -lh /backups/test_backup.sql
# Should show a file greater than 0 bytes
```

**Test the uploads backup:**
```bash
docker run --rm \
  -v promptgenie_app_uploads:/source:ro \
  -v /backups:/backup \
  alpine \
  tar -czf /backup/test_uploads.tar.gz -C /source .

ls -lh /backups/test_uploads.tar.gz
```

**Restore uploads from backup (if needed):**
```bash
docker compose -f /opt/promptgenie/docker-compose.prod.yml stop app

docker run --rm \
  -v promptgenie_app_uploads:/dest \
  -v /backups:/backup \
  alpine \
  tar -xzf /backup/uploads_20260401.tar.gz -C /dest

docker compose -f /opt/promptgenie/docker-compose.prod.yml start app
```

> The uploads volume name is `promptgenie_app_uploads`. Confirm with: `docker volume ls | grep uploads`

---

## 17. Final Go-Live Checklist

```
INFRASTRUCTURE
[ ] VPS server is running and accessible via SSH
[ ] docker compose ps shows all 5 containers healthy
[ ] Firewall only allows ports 22, 80, 443  →  sudo ufw status

DNS
[ ] api.genieinprompt.app resolves to your server IP
[ ] genieinprompt.app resolves to Vercel

SSL
[ ] https://api.genieinprompt.app shows padlock in browser
[ ] https://genieinprompt.app shows padlock in browser

BACKEND API
[ ] GET /api/v1/health returns HTTP 200 with status "ok"
[ ] GET /api/v1/health shows database: "up"
[ ] GET /api/v1/auth/me returns HTTP 401 (not 502)
[ ] All 25 migrations present (SELECT name FROM migrations ORDER BY id; — 25 rows)

PWA
[ ] https://genieinprompt.app loads the app
[ ] App can be installed to home screen (PWA install prompt appears)
[ ] Login flow works end-to-end with a real phone number

SECURITY
[ ] DB_SYNCHRONIZE=false in .env
[ ] JWT_SECRET and JWT_REFRESH_SECRET are different values
[ ] .env is NOT committed to git  →  git status (must not show .env)
[ ] https://api.genieinprompt.app/api/docs returns 404 (Swagger hidden in production)

CI/CD
[ ] GitHub Actions runs successfully on push to main
[ ] A test push deploys without errors

BACKUPS
[ ] /backups/test_backup.sql exists and is not empty
[ ] Crontab is set up for daily backups
```

---

## 18. Troubleshooting Common Problems

### "Permission denied" when running SSH
Your SSH key is not authorized on the server. Re-run Step 15b. Ensure you are connecting as `promptgenie`, not `root`.

### make deploy fails — nginx exits at startup
nginx cannot find the SSL certificate. The cert paths in `nginx/nginx.conf` do not match where Certbot stored them.
```bash
# Check where the cert actually lives
ls /opt/promptgenie/certbot/conf/live/

# Patch to match (replace api.genieinprompt.app with the directory name shown above if different)
DOMAIN=api.genieinprompt.app
sed -i "s|/etc/letsencrypt/live/[^/]*/fullchain.pem|/etc/letsencrypt/live/${DOMAIN}/fullchain.pem|g" /opt/promptgenie/nginx/nginx.conf
sed -i "s|/etc/letsencrypt/live/[^/]*/privkey.pem|/etc/letsencrypt/live/${DOMAIN}/privkey.pem|g" /opt/promptgenie/nginx/nginx.conf
make deploy
```

### CI pipeline fails — deployment step is skipped silently
The workflows expect secrets named exactly `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, and `DEPLOY_PORT`. The `vps-init.sh` script end-of-run summary incorrectly prints `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`, `VPS_PORT`. Delete any incorrectly named secrets and recreate with the correct names (see Step 15c).

### make deploy fails — "environment variable is not set or has default value"
The preflight check detected that `DB_PASSWORD`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, or `PIN_ENCRYPTION_KEY` is empty or still a placeholder. Open `.env` and fill in real values.

### Docker build fails with "npm ERR! code ENOTFOUND"
The Docker container cannot reach the internet. Check DNS: `cat /etc/resolv.conf`. If `nameserver` is missing:
```bash
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

### "502 Bad Gateway" from Nginx
The NestJS app is not running. Check logs:
```bash
make logs SERVICE=app
```
Common causes: missing required `.env` variable (`ConfigValidationError` in logs) or port conflict.

### Health check shows `database: "down"`
PostgreSQL is not reachable.
```bash
docker compose -f docker-compose.prod.yml ps
make logs SERVICE=postgres
```
Common cause: `DB_PASSWORD` in `.env` does not match what PostgreSQL was initialised with. To fix (will **delete all data**):
```bash
docker compose -f docker-compose.prod.yml down -v
make deploy
make migrate-prod
```

### SSL certificate fails
DNS has not propagated yet. Wait, then:
```bash
nslookup api.genieinprompt.app   # must return your server IP
make ssl DOMAIN=api.genieinprompt.app EMAIL=your@email.com
```

### Migrations fail — "relation already exists"
Already-applied migrations are tracked in the `migrations` table and TypeORM skips them automatically. If there is a genuine conflict, check which migrations have been applied:
```bash
export $(grep -E '^(DB_USERNAME|DB_NAME)=' .env | xargs)
docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U "$DB_USERNAME" -d "$DB_NAME" \
  -c "SELECT name FROM migrations ORDER BY id;"
```

### Migrations fail — "violates foreign key constraint" on q_point_market_balances
Migration #13 ran before the AI participant user was inserted. Return to **Step 12a** and run the SQL INSERT, then:
```bash
make migrate-prod
```
If the database is in an inconsistent state:
```bash
export $(grep -E '^(DB_USERNAME|DB_NAME)=' .env | xargs)
docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U "$DB_USERNAME" -d "$DB_NAME" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
# Then re-run Step 12a, then Step 12b
```

### "Too many login attempts" — SSH locked out
fail2ban banned your IP. From a different IP or your hosting provider's web console:
```bash
sudo fail2ban-client set sshd unbanip YOUR_IP
```

### Vercel build fails — "Flutter version not found"
The `vercel.json` build command pins Flutter 3.22.0. Confirm you have not altered the `buildCommand` in `thepg/vercel.json`.

---

## Quick Reference — Ongoing Operations

```bash
# View live application logs
make logs SERVICE=app

# Check container statuses and resource usage
make status

# Deploy a new code version (after git pull)
make deploy

# Run new migrations after a code update
make migrate-prod

# Restart just the app container
docker compose -f docker-compose.prod.yml restart app

# Restart everything
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

# Rollback app to the previous image (does not revert migrations)
make rollback

# Run preflight checks only (no deployment)
make preflight

# Manual database backup
docker compose -f docker-compose.prod.yml exec postgres \
  pg_dump -U postgres promptgenie_prod > /backups/manual_$(date +%Y%m%d_%H%M%S).sql

# Check SSL certificate expiry
echo | openssl s_client -servername api.genieinprompt.app \
  -connect api.genieinprompt.app:443 2>/dev/null | \
  openssl x509 -noout -dates
```

---

*For full environment variable reference see [ENVIRONMENT.md](ENVIRONMENT.md).
For full deployment operations reference see [DEPLOYMENT.md](DEPLOYMENT.md).*
