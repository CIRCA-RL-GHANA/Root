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
| **Hosting provider** (Hostinger, DigitalOcean, or similar) | The Linux server that runs the backend | See Step 3 |
| **Domain registrar** (Namecheap, Cloudflare, GoDaddy, etc.) | Your domain name (e.g. `promptgenie.app`) | See Step 2 |
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
- A verified sender email address in SendGrid (e.g. `noreply@promptgenie.com`)

### Tools on Your Local Computer

You only need a terminal (command line):

- **Mac / Linux:** Terminal is pre-installed.
- **Windows:** Install [Git for Windows](https://git-scm.com/download/win) — it includes Git Bash. Use Git Bash for all commands in this guide.

---

## 2. Buy a Domain Name

If you already have `promptgenie.app` registered, skip to Step 3.

1. Go to [namecheap.com](https://namecheap.com) (or any registrar).
2. Search for your domain name and purchase it.
3. Keep the registrar dashboard open — you will need it in Step 4.

> **Tip:** You need **two** DNS records for PROMPT Genie:
> - `api.promptgenie.app` → points to your VPS (the backend)
> - `promptgenie.app` → points to Vercel (the PWA — handled automatically in Step 13)

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

- A **server IP address** (e.g. `123.45.67.89`)
- A **root password** (or option to set one)
- SSH access on port 22

> **Alternatives:** DigitalOcean Droplet ($24/mo, 4GB RAM), Vultr, Linode — all work fine with this guide.

---

## 4. Point Your Domain at Your Server

This tells the internet that `api.promptgenie.app` lives on your server.

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
nslookup api.promptgenie.app
```
It should eventually return your server IP. Do not proceed to Step 9 (SSL) until it does.

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
1. **API domain:** type `api.promptgenie.app` and press Enter
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

> **Warning — wrong secret names printed at end of script:** The summary printed by `vps-init.sh` will show `VPS_HOST`, `VPS_USER`, etc. as GitHub secret names. **These are wrong.** The actual GitHub Actions workflows in this repo require these exact names: `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_PORT`. Ignore the script's printed names and use the values from Step 15c instead.

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

The `nginx/nginx.conf` file ships with certificate paths already set to `api.promptgenie.app`. Confirm they are correct:

```bash
grep ssl_certificate nginx/nginx.conf
# Expected output:
#   ssl_certificate /etc/letsencrypt/live/api.promptgenie.app/fullchain.pem;
#   ssl_certificate_key /etc/letsencrypt/live/api.promptgenie.app/privkey.pem;
```

> **If you are using a different API domain** (not `api.promptgenie.app`), update those two lines now:
> ```bash
> DOMAIN=api.yourdomain.com   # ← your actual API domain
> sed -i "s|api.promptgenie.app|${DOMAIN}|g" nginx/nginx.conf
> grep ssl_certificate nginx/nginx.conf   # verify
> ```

> **Why this matters:** nginx will refuse to start if the certificate paths do not match files that exist on disk. This is the most common cause of `make deploy` failing at the nginx startup step (see Troubleshooting Step 18 if this happens).

---

## 8. Set Up All Third-Party Services

Before you write your `.env` file, you need to create accounts and collect credentials from every external service PROMPT Genie depends on. Work through each subsection below and keep the values in a temporary secure note (password manager, not a text file).

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
   - **From Email Address:** `noreply@promptgenie.com` (or whatever you want to use)
   - **Reply To:** your personal/business email
   - **Company Address:** your business address
4. Click **Create**.
5. SendGrid sends a verification email to `noreply@promptgenie.com`. Check that inbox and click the link.

> If you do not control the inbox of `noreply@promptgenie.com`, use an address you do control for now (e.g. `yourname@gmail.com`). You can change it later.

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
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx   ← the key you just copied
EMAIL_FROM=noreply@promptgenie.com                       ← must match your verified sender
EMAIL_FROM_NAME=PROMPT Genie
```

#### Test it (optional but recommended)

In the SendGrid dashboard, go to **Email API → Integration Guide → SMTP Relay** and use the SMTP test to send a test email before deploying.

---

### 8.3 Twilio — SMS

Twilio sends OTP verification codes via SMS when users register or log in.

**Cost:** ~$0.0075–$0.05 per SMS depending on country. A trial account gives $15 credit (enough for ~300–2000 test messages). You need a paid account before going live with real users.

#### Create your account

1. Go to [twilio.com](https://twilio.com) and click **Sign Up**.
2. Verify your email address and phone number.
3. On the welcome screen, answer the setup questions:
   - What are you building? → **SMS**
   - What language? → **Node.js** (does not matter, just gets you to the console faster)

#### Get your Account SID and Auth Token

1. From the [Twilio Console homepage](https://console.twilio.com), look at the top panel.
2. You will see:
   - **Account SID** — starts with `AC`, e.g. `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - **Auth Token** — a 32-character string (click the eye icon to reveal it)
3. Copy both values.

#### Get a phone number

1. In the Twilio Console, go to **Phone Numbers → Manage → Buy a Number**.
2. Select your country.
3. Under **Capabilities**, make sure **SMS** is checked.
4. Click **Search** and choose any available number.
5. Click **Buy** (trial accounts get this for free from their credit).
6. Your number is now shown in **Phone Numbers → Manage → Active Numbers**.

> **For Ghana (GHS currency):** Twilio supports Ghana. Search with country filter **Ghana** and select a number there, or use an international number capable of sending to Ghanaian (+233) numbers.

> **Trial account restriction:** Trial accounts can only send SMS to verified phone numbers. Go to **Phone Numbers → Verified Caller IDs** and add the phone numbers you want to test with. Remove this restriction by upgrading your account before going live.

#### Upgrade to a paid account (before going live)

1. Go to **Billing → Upgrade Account**.
2. Add a credit card. Twilio only charges for what you use — there is no monthly fee.

**Your values:**
```
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  ← from Console homepage
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    ← from Console homepage
TWILIO_PHONE_NUMBER=+12025551234                      ← your purchased number in E.164 format
```

E.164 format means: `+` then country code then number, no spaces or dashes. Example: `+12025551234` for a US number, `+447911123456` for UK, `+233201234567` for Ghana.

---

### 8.4 Flutterwave — Payments (Recommended)

Flutterwave is the recommended payment provider for PROMPT Genie, especially for African markets (Ghana, Nigeria, Kenya, etc.). It supports card payments, mobile money (MTN, Vodafone, AirtelTigo), and bank transfers.

**Cost:** No monthly fee. Flutterwave charges a percentage per transaction (typically 1.4% for cards, varies by method and country). See [flutterwave.com/pricing](https://flutterwave.com/pricing).

#### Create your business account

1. Go to [app.flutterwave.com](https://app.flutterwave.com) and click **Create an Account**.
2. Choose **Business Account**.
3. Fill in your business details:
   - Business name, email, phone, country
   - Business type (select what applies — e-commerce, fintech, logistics, etc.)
4. Verify your email address.

#### Complete KYC verification

Flutterwave requires identity verification before you can receive real money. This typically takes 1–3 business days.

1. In your dashboard, go to **Settings → Business Information**.
2. Upload the required documents:
   - Government-issued ID (passport, national ID, driver's licence)
   - Business registration certificate (if a registered business)
   - Director/owner details
3. Submit and wait for approval. You will receive an email when approved.

> **Use test mode while waiting.** Flutterwave gives you test API keys immediately. You can build and test the full payment flow before KYC is approved.

#### Get your API keys

1. In your Flutterwave dashboard, go to **Settings → API Keys**.
2. You will see two environments:

**Test keys (use these first):**
```
PAYMENT_FACILITATOR_SECRET_KEY=FLWSECK_TEST-xxxxxxxxxxxxxxxxxxxx
PAYMENT_FACILITATOR_PUBLIC_KEY=FLWPUBK_TEST-xxxxxxxxxxxxxxxxxxxx
```

**Live keys (use after KYC is approved):**
```
PAYMENT_FACILITATOR_SECRET_KEY=FLWSECK-xxxxxxxxxxxxxxxxxxxx
PAYMENT_FACILITATOR_PUBLIC_KEY=FLWPUBK-xxxxxxxxxxxxxxxxxxxx
```

#### Set up your webhook

Webhooks let Flutterwave notify your server when a payment is completed, even if the user closes their browser.

1. In your dashboard, go to **Settings → Webhooks**.
2. Set the webhook URL to:
   ```
   https://api.promptgenie.app/api/v1/payments/webhook
   ```
3. Under **Secret Hash**, generate a random string and copy it. This is your `PAYMENT_FACILITATOR_WEBHOOK_SECRET`.
4. Save.

#### Find your currency code

| Country | Currency | Code |
|---|---|---|
| Ghana | Ghanaian Cedi | `GHS` |
| Nigeria | Nigerian Naira | `NGN` |
| Kenya | Kenyan Shilling | `KES` |
| United States | US Dollar | `USD` |
| United Kingdom | British Pound | `GBP` |

**Your values:**
```
PAYMENT_FACILITATOR_PROVIDER=flutterwave
PAYMENT_FACILITATOR_SECRET_KEY=FLWSECK-xxxxxxxxxxxxxxxxxxxx
PAYMENT_FACILITATOR_PUBLIC_KEY=FLWPUBK-xxxxxxxxxxxxxxxxxxxx
PAYMENT_FACILITATOR_WEBHOOK_SECRET=your-random-webhook-secret
PAYMENT_FACILITATOR_CURRENCY=GHS
PAYMENT_FACILITATOR_WEBHOOK_URL=https://api.promptgenie.app/api/v1/payments/webhook
```

#### Test card numbers (use in test mode only)

| Card | Number | CVV | Expiry |
|---|---|---|---|
| Successful payment | `5531 8866 5214 2950` | `564` | `09/32` |
| Failed payment | `5258 5874 6254 9680` | `883` | `09/31` |
| Insufficient funds | `4187 4274 1556 4246` | `828` | `09/32` |

---

### 8.5 Paystack — Payments (Alternative)

Use Paystack instead of Flutterwave if you are based in Nigeria and primarily serve Nigerian customers. The setup process is nearly identical.

**Cost:** 1.5% per transaction (+ ₦100 for transactions above ₦2,500). No monthly fee.

#### Create your account

1. Go to [dashboard.paystack.com](https://dashboard.paystack.com) and sign up.
2. Verify your email.
3. Complete the business profile under **Settings → Business Settings**.
4. Submit KYC documents under **Settings → Compliance**.

#### Get your API keys

1. Go to **Settings → API Keys & Webhooks**.
2. Copy:
   - **Test Secret Key** — starts with `sk_test_`
   - **Test Public Key** — starts with `pk_test_`
   - **Live Secret Key** — starts with `sk_live_` (available after KYC approval)
   - **Live Public Key** — starts with `pk_live_`

#### Set up your webhook

1. On the same **API Keys & Webhooks** page, under **Webhook URL**, enter:
   ```
   https://api.promptgenie.app/api/v1/payments/webhook
   ```
2. Save. Paystack does not use a separate webhook secret — it uses your secret key to sign events (the app handles this automatically).

**Your values:**
```
PAYMENT_FACILITATOR_PROVIDER=paystack
PAYMENT_FACILITATOR_SECRET_KEY=sk_live_xxxxxxxxxxxxxxxxxxxx
PAYMENT_FACILITATOR_PUBLIC_KEY=pk_live_xxxxxxxxxxxxxxxxxxxx
PAYMENT_FACILITATOR_WEBHOOK_SECRET=                    ← leave blank for Paystack
PAYMENT_FACILITATOR_CURRENCY=NGN
PAYMENT_FACILITATOR_WEBHOOK_URL=https://api.promptgenie.app/api/v1/payments/webhook
```

---

### 8.6 OpenAI — AI Features (Optional)

OpenAI powers the natural language AI features: sentiment analysis, intent detection, conversation summaries, financial insights, and the AI assistant. The app runs without it — AI features fall back gracefully — but live use requires an API key.

**Cost:** Pay-per-use. `gpt-4o-mini` (the default model) costs approximately $0.15 per 1 million input tokens. For a typical user session, this is fractions of a cent.

#### Create your account

1. Go to [platform.openai.com](https://platform.openai.com) and sign up.
2. Verify your email and phone number.
3. You get $5 in free credits on sign-up (enough for extensive testing).

#### Add billing (required for production)

1. Go to **Settings → Billing → Add payment method**.
2. Add a credit card.
3. Set a **monthly spending limit** under **Billing → Limits**. Start with $20–$50 to prevent surprise bills while you test.

#### Create an API key

1. Go to **API Keys** in the left sidebar (or [platform.openai.com/api-keys](https://platform.openai.com/api-keys)).
2. Click **Create new secret key**.
3. Name it `promptgenie-production`.
4. Click **Create secret key**.
5. **Copy the key immediately** — it starts with `sk-` and is shown only once.

#### Choose your model

The default `gpt-4o-mini` is the right choice for production — it is fast, cheap, and capable enough for all PROMPT Genie features. Do not change `AI_MODEL` unless you have a specific reason.

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

> **If you do not want to use OpenAI yet,** set `AI_API_KEY=` (blank). The app will still work — sentiment analysis, intent detection, and the AI assistant will return empty/default responses instead of erroring.

---

### 8.7 Google Maps — Ride Routing (Optional)

Google Maps is used to calculate ride routes, distances, estimated times, and to geocode addresses. Without it, the ride module still works but cannot show turn-by-turn routing or accurate fares.

**Cost:** $200 free monthly credit (covers ~40,000 map loads or ~100,000 geocoding requests per month). Most early-stage apps stay within the free tier.

#### Create a Google Cloud account

1. Go to [console.cloud.google.com](https://console.cloud.google.com) and sign in with a Google account.
2. Accept the terms of service.
3. Add a billing account under **Billing** (required even for free tier — Google needs a card on file).

#### Create a project

1. Click the project dropdown at the top and select **New Project**.
2. Name it `promptgenie`.
3. Click **Create**.

#### Enable the required APIs

1. Go to **APIs & Services → Library**.
2. Search for and enable each of the following one by one:
   - **Maps JavaScript API**
   - **Geocoding API**
   - **Directions API**
   - **Distance Matrix API**
   - **Places API**

#### Create an API key

1. Go to **APIs & Services → Credentials → Create Credentials → API Key**.
2. Copy the key shown.
3. Click **Restrict Key** (important for security):
   - Under **Application restrictions**, select **IP addresses** and add your server IP.
   - Under **API restrictions**, select **Restrict key** and check only the 5 APIs you enabled above.
4. Save.

**Your value:**
```
GOOGLE_MAPS_API_KEY=AIzaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

> **If you are not launching the ride feature immediately,** leave `GOOGLE_MAPS_API_KEY=` blank and add it later. The app will not crash without it.

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

### Step 9c — Replace every CHANGE_ME with your real values

Use the values you collected in Step 8. Here is the complete file with annotations:

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
# DB_HOST must be "postgres" (the Docker container name) — do not change this
DB_HOST=postgres
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=<paste DB_PASSWORD from Section 8.1>
DB_NAME=promptgenie_prod
# NEVER set DB_SYNCHRONIZE=true in production — it will drop and recreate tables
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
# REDIS_HOST must be "redis" (the Docker container name) — do not change this
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=<paste REDIS_PASSWORD from Section 8.1>
REDIS_DB=0

# ── Email (SendGrid) — see Section 8.2 for setup ──────────────────────────────
SENDGRID_API_KEY=<paste SG.xxxx key from Section 8.2>
EMAIL_FROM=<paste verified sender email from Section 8.2>
EMAIL_FROM_NAME=PROMPT Genie
EMAIL_SUPPORT=support@promptgenie.com

# ── SMS (Twilio) — see Section 8.3 for setup ──────────────────────────────────
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
CORS_ORIGIN=https://promptgenie.app
CORS_CREDENTIALS=true

# ── WebSocket / Socket.IO ──────────────────────────────────────────────────────
# Must match the PWA domain — used for Socket.IO CORS validation
WEBSOCKET_ENABLED=true
WEBSOCKET_CORS_ORIGIN=https://promptgenie.app

# ── Logging ────────────────────────────────────────────────────────────────────
LOG_LEVEL=info
LOG_FILE_PATH=./logs

# ── AI Services — see Section 8.6 for setup ───────────────────────────────────
AI_ENABLED=true
TENSORFLOW_ENABLED=false
# Leave blank if you are not using OpenAI — the app works without it
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

# ── Google Maps — see Section 8.7 for setup ───────────────────────────────────
# Leave blank to disable ride routing — rides still work without it
GOOGLE_MAPS_API_KEY=<paste AIza... key from Section 8.7, or leave blank>

# ── Monitoring ─────────────────────────────────────────────────────────────────
HEALTH_CHECK_TIMEOUT=30000
METRICS_ENABLED=true

# ── Payment Facilitator — see Sections 8.4 / 8.5 for setup ───────────────────
# Use "mock" to test without real payments. Use "flutterwave" or "paystack" for live.
PAYMENT_FACILITATOR_PROVIDER=<flutterwave or paystack or mock>
PAYMENT_FACILITATOR_SECRET_KEY=<paste secret key from Section 8.4 or 8.5>
PAYMENT_FACILITATOR_PUBLIC_KEY=<paste public key from Section 8.4 or 8.5>
PAYMENT_FACILITATOR_WEBHOOK_SECRET=<paste webhook secret from Section 8.4>
PAYMENT_FACILITATOR_CURRENCY=<GHS, NGN, KES, or USD>
PAYMENT_FACILITATOR_WEBHOOK_URL=https://api.promptgenie.app/api/v1/payments/webhook

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

Save the file: `Ctrl+O` → Enter → `Ctrl+X`

### Step 9d — Validate your .env

```bash
cd /opt/promptgenie
./scripts/validate-env.sh --strict
```

Expected output: the **root `.env` section** should be all green checkmarks. The **backend `.env` section** will show yellow warnings — this is normal. The validator auto-creates `orionstack-backend--main/.env` from the backend's `.env.example` file (which contains placeholder values), and those placeholders trigger warnings. In production, Docker reads config from the **root `.env` only** — the backend-specific file is only used for local development outside Docker. You can safely ignore those warnings.

**If the root section shows errors, do not proceed.** Common validation failures and fixes:

| Error | Cause | Fix |
|---|---|---|
| `JWT_SECRET is required` | Variable is missing or empty | Paste the generated value |
| `JWT_SECRET and JWT_REFRESH_SECRET must be different` | You used the same value for both | Regenerate one of them with `openssl rand -base64 48` |
| `PIN_ENCRYPTION_KEY must be 32 hex characters` | Wrong length or wrong format | Run `openssl rand -hex 32` and paste the exact output |
| `SENDGRID_API_KEY must start with SG.` | Wrong key or not copied fully | Re-copy from SendGrid dashboard |
| `EMAIL_FROM must be a valid email` | Typo in the email address | Fix the address |
| `DB_SYNCHRONIZE must be false in production` | Set to `true` | Change to `false` |

---

## 10. Get an SSL Certificate (HTTPS)

> **Skip this step if `vps-init.sh` completed successfully.**
> The server setup script in Step 6 already issued your SSL certificate via Certbot standalone. You can confirm with:
> ```bash
> ls /opt/promptgenie/certbot/conf/live/api.promptgenie.app/
> # If you see fullchain.pem and privkey.pem, skip to the Verify section below.
> ```
> Only run `make ssl` if the cert is missing or expired.

This gives your API the padlock (HTTPS). It is free via Let's Encrypt.

> **Wait** until `nslookup api.promptgenie.app` returns your server IP before running this. The certificate will fail if DNS has not propagated yet.

```bash
cd /opt/promptgenie
make ssl DOMAIN=api.promptgenie.app EMAIL=your@email.com
```

Replace `your@email.com` with your real email. Let's Encrypt sends expiry reminders there.

This takes about 30 seconds. When it succeeds you will see `Successfully received certificate`.

**Verify:**
```bash
ls /etc/letsencrypt/live/api.promptgenie.app/
# You should see: cert.pem  chain.pem  fullchain.pem  privkey.pem
```

---

## 11. Deploy the Backend

One command builds the Docker image, starts all five services (NestJS app, PostgreSQL, Redis, Nginx, Certbot), and waits for a health check.

```bash
cd /opt/promptgenie
make deploy
```

The first build takes 3–6 minutes because it compiles TypeScript and installs Node.js dependencies inside the container.

**What it's doing while you wait:**
1. Validates your `.env`
2. Builds the NestJS Docker image (multi-stage — dev build then production image)
3. Starts PostgreSQL and waits for it to be ready
4. Starts Redis
5. Starts the NestJS app
6. Starts Nginx (reverse proxy on ports 80 and 443)
7. Starts the Certbot renewal service
8. Polls the health endpoint until the app responds

When complete you will see `✓ Deployment complete`.

**Check that all containers are running:**
```bash
make status
# or
docker compose -f docker-compose.prod.yml ps
```

All five containers should show status `Up` or `healthy`:
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

Migrations create all the database tables that the app needs. This only needs to be done once on first deployment (and again when new migrations are added in future updates).

### Step 12a — Pre-seed the AI market-maker account

> **This step is mandatory.** Migration #13 (`CreateQPointsMarketTables`) inserts the AI market-maker's initial Q Points balance into `q_point_market_balances` with a foreign-key reference to the `users` table. If the AI participant row does not exist in `users` when migration #13 runs, the entire migration run will abort with a foreign-key violation and you will need to drop and recreate the database.

The `.env.example` documents this requirement with the comment:
> *"Create the matching users row before running migrations in production."*

Run the following **once on a fresh database, before running migrations**. It is safe to re-run (the `ON CONFLICT` clause makes it idempotent):

```bash
# From /opt/promptgenie on the VPS
# This sources only DB_USERNAME and DB_NAME from your .env into the current shell
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

This runs 25 migrations in order **inside the running Docker container** (the server does not need Node.js installed locally). You will see each migration name print to the console as it applies.

**Verify all migrations ran:**
```bash
export $(grep -E '^(DB_USERNAME|DB_NAME)=' .env | xargs)
docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U "$DB_USERNAME" -d "$DB_NAME" \
  -c "SELECT name FROM migrations ORDER BY id;"
```

The query should return 25 rows — one for each migration name. If a migration is missing, re-run `make migrate-prod`.

> **Note — CI does not run migrations reliably:** The GitHub Actions backend workflow also attempts `npm run migration:run` on each push, but this command requires `ts-node` which is excluded from the production Docker image, so it silently fails. **Always run `make migrate-prod` manually on the server whenever a deployment includes new migration files.**

---

## 13. Verify the API Is Live

Run these from your **local machine** (or any browser):

### Health check — the most important test
```bash
curl https://api.promptgenie.app/api/v1/health
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

### Auth smoke test — confirms routing is working
```bash
curl -i https://api.promptgenie.app/api/v1/auth/me
```
Expected: `HTTP 401 Unauthorized` — this is correct. It means the endpoint exists and is protecting itself.

### Additional health probes (optional)
```bash
# Liveness probe — is the Node.js process alive?
curl https://api.promptgenie.app/api/v1/health/live

# Readiness probe — is the app ready to accept traffic?
curl https://api.promptgenie.app/api/v1/health/ready
```
Both return `HTTP 200` when healthy. These are the same endpoints your load balancer or Kubernetes liveness/readiness probes would call.

### WebSocket smoke test — confirms real-time chat is reachable
```bash
# Check that nginx proxies the Socket.IO handshake (should return HTTP 200 or 400, never 404)
curl -i https://api.promptgenie.app/socket.io/?EIO=4\&transport=polling
```
Any response **other than 404** means nginx is correctly forwarding WebSocket traffic to the NestJS app. A `400 Bad Request` from Socket.IO is the expected response when no auth token is provided — that is correct.

### What a broken deployment looks like
- `curl: (6) Could not resolve host` → DNS has not propagated yet. Wait longer.
- `SSL: no certificate` error → SSL was not issued. Re-run Step 10.
- `502 Bad Gateway` from nginx → The NestJS app is not running. Check logs: `make logs SERVICE=app`
- `{"status":"error"}` in health response → Database connection failed. Check your DB_PASSWORD in `.env` and confirm `promptgenie-postgres` is healthy.

---

## 14. Deploy the PWA to Vercel

The Flutter web app (PWA) is deployed separately to Vercel's global CDN.

### Step 14a — Create a Vercel account

Go to [vercel.com](https://vercel.com) and sign up with your GitHub account.

### Step 14b — Import the Flutter repo

1. In Vercel, click **Add New → Project**.
2. Select the `CIRCA-RL-GHANA/Flutter-Ready` repository.
3. Vercel will detect `vercel.json` in the root and configure the build automatically (`flutter build web --release --web-renderer canvaskit`).
4. Under **Environment Variables**, you only need to add optional services. No variables are required for the default deployment:

   | Variable | Value | Required? |
   |---|---|---|
   | `GOOGLE_MAPS_API_KEY` | Your AIza... key from Section 8.7 | Only if using Maps in the PWA |

   > **Important — API domain is compiled in, not injected:** The Flutter app's backend URL is a compile-time constant defined in `thepg/lib/core/constants/env_config.dart` (hardcoded to `https://api.promptgenie.app/api/v1`). The `API_BASE_URL` variable in `vercel.json` sends a `--dart-define` flag to the build, but `env_config.dart` does **not** read it via `const String.fromEnvironment(...)`. Setting `API_BASE_URL` in the Vercel dashboard therefore has no effect on where the app points.
   >
   > **If you are deploying to a different backend domain**, edit `thepg/lib/core/constants/env_config.dart` directly — change the `production` case in both `baseUrl` (replace `https://api.promptgenie.app/api/v1`) and `webSocketUrl` (replace `wss://api.promptgenie.app`) — commit the change, then re-deploy.
   >
   > If you add `GOOGLE_MAPS_API_KEY` to Vercel and want it embedded in the web build, also add `--dart-define=GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}` to the `buildCommand` in `thepg/vercel.json`.

5. Click **Deploy**.

The first deploy takes about 4 minutes to build the Flutter web app.

### Step 14c — Configure your domain on Vercel

1. In your Vercel project, go to **Settings → Domains**.
2. Add `promptgenie.app`.
3. Vercel will show you the DNS record to add. Go back to your domain registrar and add it:

   | Type | Name | Value |
   |---|---|---|
   | CNAME | `@` | `cname.vercel-dns.com` |
   | or A | `@` | `76.76.19.61` |

4. Back in Vercel, click **Verify**. Once green, your PWA is live at `https://promptgenie.app`.

---

## 15. Set Up Automatic Deployments (GitHub Actions)

Every time you push code to the `main` branch, GitHub will automatically deploy to your server. You need to add SSH credentials as GitHub Secrets.

### Step 15a — Create a deployment SSH key (on your local machine)

```bash
# Generate a NEW key pair just for deployments (do not reuse your personal key)
ssh-keygen -t ed25519 -C "promptgenie-deploy" -f ~/.ssh/promptgenie_deploy

# This creates two files:
# ~/.ssh/promptgenie_deploy      ← private key (goes into GitHub)
# ~/.ssh/promptgenie_deploy.pub  ← public key  (goes onto the server)
```

### Step 15b — Authorize the key on your server

Copy the public key to the server:
```bash
# From your local machine:
ssh-copy-id -i ~/.ssh/promptgenie_deploy.pub promptgenie@YOUR_SERVER_IP
```

If `ssh-copy-id` is not available (Windows):
```bash
# From your local machine — prints the public key
cat ~/.ssh/promptgenie_deploy.pub
```
Then on the server:
```bash
echo "PASTE_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Step 15c — Add secrets to GitHub

> **Secrets vs Variables:** GitHub has two separate concepts.
> - **Secrets** (`Settings → Secrets and variables → Actions → Secrets`) — encrypted values hidden from logs. Used for passwords, keys, tokens.
> - **Variables** (`Settings → Secrets and variables → Actions → Variables`) — plain-text values visible in logs. Used for non-sensitive config like URLs.

#### Root repo & Backend repo — Backend deployment secrets

1. Go to `github.com/CIRCA-RL-GHANA/Root` → **Settings → Secrets and variables → Actions**.
2. Click **New repository secret** and add each of the following:

   | Secret name | Value |
   |---|---|
   | `DEPLOY_HOST` | Your server IP address, e.g. `123.45.67.89` |
   | `DEPLOY_USER` | `promptgenie` |
   | `DEPLOY_SSH_KEY` | Contents of `~/.ssh/promptgenie_deploy` (the private key — starts with `-----BEGIN OPENSSH PRIVATE KEY-----`) |
   | `DEPLOY_PORT` | `22` |

3. Repeat the same 4 secrets for `github.com/CIRCA-RL-GHANA/NestJs-Ready` (the backend repo has its own CI pipeline).

#### Flutter repo — Web (Vercel) secrets

Go to `github.com/CIRCA-RL-GHANA/Flutter-Ready` → **Settings → Secrets and variables → Actions** and add:

   | Secret name | Value | How to get it |
   |---|---|---|
   | `VERCEL_TOKEN` | Vercel API token | vercel.com → Settings → Tokens → Create |
   | `VERCEL_ORG_ID` | Vercel org/team ID | vercel.com → Settings → General → scroll to Team ID |
   | `VERCEL_PROJECT_ID` | Vercel project ID | Your Vercel project → Settings → General → scroll to Project ID |

Also add these **Variables** (not secrets) under the same Actions settings page:

   | Variable name | Value | Notes |
   |---|---|---|
   | `API_BASE_URL` | `https://api.promptgenie.app` | Passed as `--dart-define` to the Flutter build. Has no effect on the compiled app (see Step 14b note), but the CI workflow requires this variable to be set. |
   | `VERCEL_URL` | `https://promptgenie.app` | Used by the post-deploy smoke test in CI |

#### Flutter repo — Android signing secrets

The Android CI build signs the app with your release keystore. You must create this keystore first.

**On your local machine, generate the keystore:**
```bash
# Run in Git Bash / Terminal (requires Java 17 JDK — install from adoptium.net if not present)
# Flutter 3.22 requires Java 17 or higher; earlier versions will produce a build error.
keytool -genkey -v \
  -keystore promptgenie-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias promptgenie \
  -storetype JKS
```

When prompted:
- **Keystore password:** choose a strong password and save it
- **Key password:** choose another strong password (can be the same)
- **First and last name:** your name or org name
- **Organizational unit, Organization, City, State, Country:** fill in as appropriate

This generates `promptgenie-release.jks` in your current directory.

**Base64-encode it for GitHub:**
```bash
# Mac / Linux
base64 -i promptgenie-release.jks | tr -d '\n'

# Git Bash on Windows
base64 -w 0 promptgenie-release.jks
```

Copy the entire output (a long single-line string).

**Copy the keystore file to the right place:**
```bash
cp promptgenie-release.jks thepg/android/keystore/promptgenie-release.jks
# (This file is gitignored — it will NOT be committed)
```

**Add secrets to the Flutter repo:**

   | Secret name | Value |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | The base64 string from above |
   | `ANDROID_KEYSTORE_PASSWORD` | The keystore password you chose |
   | `ANDROID_KEY_PASSWORD` | The key password you chose |
   | `ANDROID_KEY_ALIAS` | `promptgenie` |

#### Flutter repo — iOS signing secrets

iOS signing requires an Apple Developer account ($99/year) and a valid distribution certificate. This is only needed to publish to the App Store. **Skip this section if you are not targeting iOS yet.**

1. **Create an Apple Developer account** at [developer.apple.com](https://developer.apple.com) → Enroll → Individual or Organization.

2. **Create a distribution certificate:**
   - Log in to [developer.apple.com/account](https://developer.apple.com/account) → Certificates, IDs & Profiles → Certificates.
   - Click `+` → Choose **Apple Distribution**.
   - Follow the CSR (Certificate Signing Request) instructions.
   - Download the `.cer` file and double-click to install in Keychain Access.
   - Export from Keychain as `.p12` with a password.

3. **Base64-encode the certificate:**
   ```bash
   base64 -i YourCertificate.p12 | tr -d '\n'
   ```

4. **Create an App Store Connect API key:**
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → Users and Access → Keys → Integrations → App Store Connect API.
   - Click `+` → Name it `promptgenie-ci` → Role: **App Manager**.
   - Download the `.p8` file (shown only once).
   - Note the **Issuer ID** (shown at the top of the Keys page) and **Key ID**.

5. **Update `thepg/ios/ExportOptions.plist`** with your Apple Team ID:
   ```bash
   # Find your Team ID at developer.apple.com → Account → Membership
   # Edit the file and replace YOUR_TEAM_ID with your real Team ID
   nano thepg/ios/ExportOptions.plist
   ```

6. **Add secrets to the Flutter repo:**

   | Secret name | Value |
   |---|---|
   | `IOS_CERTIFICATE_BASE64` | Base64 string from step 3 |
   | `IOS_CERTIFICATE_PASSWORD` | Password you used when exporting the `.p12` |
   | `APPSTORE_ISSUER_ID` | Issuer ID from App Store Connect |
   | `APPSTORE_API_KEY_ID` | Key ID from App Store Connect |
   | `APPSTORE_API_PRIVATE_KEY` | Raw contents of the `.p8` file (open in a text editor and paste) |

> **Important — TestFlight, not direct App Store:** The CI pipeline uploads the iOS build to **TestFlight**, not directly to the App Store production listing. After a successful CI run:
> 1. Open [App Store Connect](https://appstoreconnect.apple.com) → your app → **TestFlight**.
> 2. Wait for the build to finish processing (usually 5–15 minutes).
> 3. To publish to the App Store: go to **App Store → + Version**, select the TestFlight build, fill in release notes, and submit for Apple review.
> Apple review typically takes 1–2 days on first submission.

#### Flutter repo — Google Play secrets

Required to automatically publish Android builds to the Play Store. **Skip if not publishing to Google Play yet.**

1. **Create a Google Play Console account** at [play.google.com/console](https://play.google.com/console) ($25 one-time fee).

2. **Create an app** → name it *PROMPT Genie* → package name `com.promptgenie.app`.

3. **Create a service account for CI uploads:**
   - In Play Console, go to **Setup → API access → Link to a Google Cloud project**.
   - In the linked Google Cloud project, go to **IAM & Admin → Service Accounts → Create Service Account**.
   - Name it `promptgenie-ci`, click Create.
   - Grant the role: **Service Account User**.
   - Click Done → click the service account → **Keys → Add Key → Create new key → JSON**.
   - Download the JSON file.

4. **Grant the service account release access:**
   - Back in Play Console → **Setup → API access** → find your new service account → **Grant access**.
   - Set permissions: **Release** → **Release manager** (for internal/alpha/beta tracks).

5. **Add the secret to the Flutter repo:**

   | Secret name | Value |
   |---|---|
   | `GOOGLE_PLAY_SERVICE_ACCOUNT` | Entire contents of the JSON file you downloaded |

> **Important — Play Store release track:** The CI pipeline uploads to the **internal testing track**, not directly to production. After the first CI run deposits a build in Play Console, you need to manually promote it:
> 1. Open [Play Console](https://play.google.com/console) → your app → **Testing → Internal testing**.
> 2. Verify the build looks correct and passes the pre-launch report.
> 3. Go to **Production → Releases → Create new release**, select the AAB from Internal testing, and submit it for review.
> Subsequent CI builds go to Internal testing automatically; you control promotion to Production.

### Step 15d — Test it

> **Pre-requisite:** Make sure you have completed **Step 12a** (AI participant pre-seed) and **Step 12b** (`make migrate-prod`) before triggering CI. The backend CI workflow attempts `npm run migration:run` on each push, but this command requires `ts-node` which is not present in the production Docker image — so the CI migration step **silently fails**. This is not harmful once migrations have been applied manually (TypeORM is idempotent), but it means you should never rely on CI to apply migrations. **Always run `make migrate-prod` manually on the server when a deployment includes new migration files**.

Push any small change (e.g. add a blank line to `README.md`) to the `main` branch:

```bash
# On your local machine, in the root repo directory
echo "" >> README.md
git add README.md
git commit -m "test: trigger CI/CD pipeline"
git push origin main
```

Go to `github.com/CIRCA-RL-GHANA/Root` → **Actions** tab. You should see a workflow run start within 10 seconds. It will lint, test, rsync code to the server, and deploy — taking about 4–6 minutes total.

---

## 16. Set Up Automated Database Backups

Run this once on the server to create daily automatic database backups.

```bash
# Create the backups directory
sudo mkdir -p /backups
sudo chown promptgenie:promptgenie /backups

# Open the crontab editor
crontab -e
```

Add these two lines at the bottom, then save:

```cron
# Daily database backup at 2am UTC
0 2 * * * docker compose -f /opt/promptgenie/docker-compose.prod.yml exec -T postgres pg_dump -U postgres promptgenie_prod > /backups/db_$(date +\%Y\%m\%d).sql 2>&1

# Delete backups older than 30 days
0 3 * * * find /backups -name "db_*.sql" -mtime +30 -delete
```

**Save:** In nano, press `Ctrl+O` → Enter → `Ctrl+X`.

**Test it manually right now:**
```bash
docker compose -f /opt/promptgenie/docker-compose.prod.yml exec -T postgres \
  pg_dump -U postgres promptgenie_prod > /backups/test_backup.sql

ls -lh /backups/test_backup.sql
# Should show a file greater than 0 bytes
```

### Back up the uploads directory

User-uploaded files (avatars, documents) are stored in a **named Docker volume** (`promptgenie_app_uploads`). Docker named volumes do **not** live at a plain host path — they are managed by Docker at `/var/lib/docker/volumes/`. The correct way to back them up is to mount the volume into a temporary Alpine container:

```bash
crontab -e
```

Add this line:
```cron
# Weekly uploads backup (Sundays at 3:30am UTC)
30 3 * * 0 docker run --rm -v promptgenie_app_uploads:/source:ro -v /backups:/backup alpine tar -czf /backup/uploads_$(date +\%Y\%m\%d).tar.gz -C /source . 2>&1
```

**Test it manually right now:**
```bash
docker run --rm \
  -v promptgenie_app_uploads:/source:ro \
  -v /backups:/backup \
  alpine \
  tar -czf /backup/test_uploads.tar.gz -C /source .

ls -lh /backups/test_uploads.tar.gz
# Non-zero size confirms the volume data is accessible
```

**Restore uploads from backup (if needed):**
```bash
# Stop the app first so nothing writes during restore
docker compose -f /opt/promptgenie/docker-compose.prod.yml stop app

docker run --rm \
  -v promptgenie_app_uploads:/dest \
  -v /backups:/backup \
  alpine \
  tar -xzf /backup/uploads_20260101.tar.gz -C /dest

# Restart the app
docker compose -f /opt/promptgenie/docker-compose.prod.yml start app
```

> **How the volume name is derived:** Docker Compose names volumes as `<project>_<volume>`. With the app directory `/opt/promptgenie/`, Docker Compose uses `promptgenie` as the project name, making the uploads volume `promptgenie_app_uploads`. Confirm with: `docker volume ls | grep uploads`

---

## 17. Final Go-Live Checklist

Run through every item before announcing the app is live.

```
INFRASTRUCTURE
[ ] VPS server is running and accessible via SSH
[ ] docker compose ps shows all 5 containers healthy
[ ] Firewall only allows ports 22, 80, 443 (check with: sudo ufw status)

DNS
[ ] api.promptgenie.app resolves to your server IP
[ ] promptgenie.app resolves to Vercel

SSL
[ ] https://api.promptgenie.app shows padlock in browser
[ ] https://promptgenie.app shows padlock in browser

BACKEND API
[ ] GET /api/v1/health returns HTTP 200 with status "ok"
[ ] GET /api/v1/health shows database: "up"
[ ] GET /api/v1/auth/me returns HTTP 401 (not 502)
[ ] All 25 migrations present (psql query: SELECT name FROM migrations ORDER BY id; — should return 25 rows)

PWA
[ ] https://promptgenie.app loads the app
[ ] App can be added to home screen (PWA install prompt appears)
[ ] Login flow works end-to-end with a real phone number

SECURITY
[ ] DB_SYNCHRONIZE=false in .env
[ ] JWT_SECRET and JWT_REFRESH_SECRET are different values
[ ] .env is NOT committed to git (run: git status — should not show .env)
[ ] https://api.promptgenie.app/api/docs returns 404 (Swagger hidden in production)

CI/CD
[ ] GitHub Actions run successfully on push to main
[ ] A test push deploys without errors

BACKUPS
[ ] /backups/test_backup.sql exists and is not empty
[ ] Crontab is set up for daily backups
```

---

## 18. Troubleshooting Common Problems

### "Permission denied" when running SSH
Your SSH key is not authorized. Re-run Step 15b. Make sure you are using the correct username (`promptgenie`, not `root`).

### make deploy fails immediately — "Too many redirects" or nginx exits at startup
nginx cannot find the SSL certificate. The cert paths in `nginx/nginx.conf` do not match where Certbot stored the certificate. On the server:
```bash
# Check where the cert actually lives
ls /opt/promptgenie/certbot/conf/live/
# Note the directory name shown (e.g. api.promptgenie.app)

# Patch nginx.conf to match
DOMAIN=api.promptgenie.app   # ← replace with the directory name shown above
sed -i "s|/etc/letsencrypt/live/[^/]*/fullchain.pem|/etc/letsencrypt/live/${DOMAIN}/fullchain.pem|g" /opt/promptgenie/nginx/nginx.conf
sed -i "s|/etc/letsencrypt/live/[^/]*/privkey.pem|/etc/letsencrypt/live/${DOMAIN}/privkey.pem|g" /opt/promptgenie/nginx/nginx.conf

# Then redeploy
make deploy
```

### make deploy fails immediately — "DEPLOY_HOST not set"
This only matters for CI. On the server itself, you run `make deploy` directly — it does not need that variable.

### CI pipeline fails — "No such secret" or deployment step is skipped silently
The GitHub Actions workflows expect secrets named exactly `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, and `DEPLOY_PORT`. The `vps-init.sh` script's end-of-run summary incorrectly prints `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`, `VPS_PORT`. If you followed those printed names, the secrets are named incorrectly. Delete them and recreate with the correct names (see Step 15c).

### make deploy fails — "environment variable is not set or has default value"
The `deploy.sh` preflight check detected that one of `DB_PASSWORD`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, or `PIN_ENCRYPTION_KEY` is empty or still contains a `CHANGE_ME` placeholder. Open `.env` and fill in all real values for those four variables.

### Docker build fails with "npm ERR! code ENOTFOUND"
The Docker container cannot reach the internet. Check your server's DNS: `cat /etc/resolv.conf`. Should show `nameserver 8.8.8.8` or similar. If missing: `echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf`

### "502 Bad Gateway" from Nginx
The NestJS app is not running or is still starting up. Wait 30 seconds and try again. If it persists:
```bash
make logs SERVICE=app
```
Look for the error in the last 50 lines. Common causes:
- Missing required `.env` variable: app logs will say `ConfigValidationError`
- Port conflict: something else is using port 3000

### Health check shows `database: "down"`
PostgreSQL is not reachable from the app container.
```bash
docker compose -f docker-compose.prod.yml ps
```
Check that `promptgenie-postgres` shows `healthy`. If it shows `starting`:
```bash
make logs SERVICE=postgres
```
Common cause: wrong `DB_PASSWORD` — the app's password does not match what PostgreSQL was initialised with. Fix: shut everything down, delete the postgres volume (data will be lost), and redeploy.
```bash
docker compose -f docker-compose.prod.yml down -v    # WARNING: deletes all data
make deploy
make migrate-prod
```

### SSL certificate fails — "too many redirects" or "challenge failed"
DNS has not propagated yet. Wait longer, then:
```bash
nslookup api.promptgenie.app    # must return your server IP
make ssl DOMAIN=api.promptgenie.app EMAIL=your@email.com
```

### Migrations fail — "relation already exists"
Part of the database was already created. Check which migrations have been applied:
```bash
export $(grep -E '^(DB_USERNAME|DB_NAME)=' .env | xargs)
docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U "$DB_USERNAME" -d "$DB_NAME" \
  -c "SELECT name FROM migrations ORDER BY id;"
```
Already-applied migrations are tracked in the `migrations` table and TypeORM will skip them automatically on re-run. If you see a genuine conflict that TypeORM cannot resolve, contact your backend developer with the full error message.

### Migrations fail — "violates foreign key constraint" on `q_point_market_balances`
Migration #13 (`CreateQPointsMarketTables`) tried to insert the AI participant's balance row before the matching `users` row existed. Return to **Step 12a** and run the AI participant INSERT, then re-run migrations:
```bash
# Re-run migrations — TypeORM will skip already-applied ones
make migrate-prod
```
If the migration itself was partially applied and left the database in an inconsistent state, you may need to drop the affected tables manually and re-run. In the worst case, recreate the database from scratch with:
```bash
export $(grep -E '^(DB_USERNAME|DB_NAME)=' .env | xargs)
docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U "$DB_USERNAME" -d "$DB_NAME" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
# Then re-run Step 12a, then Step 12b
```

### Vercel build fails — "Flutter version not found"
The `vercel.json` in the Flutter repo pins `flutter-version: 3.22.0`. Make sure you have not changed that value. If Vercel uses an environment variable for it, ensure it matches.

### "Too many login attempts" — SSH locked out
fail2ban banned your IP after too many failed SSH attempts. From a different IP or your hosting provider's web console:
```bash
sudo fail2ban-client set sshd unbanip YOUR_IP
```

---

## Quick Reference — Ongoing Operations

Once live, these are the commands you will use most often:

```bash
# View live application logs
make logs SERVICE=app

# Check all container statuses and resource usage
make status

# Deploy a new code version (after git pull)
make deploy

# Run new migrations after a code update
make migrate-prod

# Restart just the app (without touching the database)
docker compose -f docker-compose.prod.yml restart app

# Restart everything
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

# Rollback app to the previous image (does not revert migrations)
make rollback

# Run pre-deployment preflight checks only (without deploying)
make preflight

# Manual database backup
docker compose -f docker-compose.prod.yml exec postgres \
  pg_dump -U postgres promptgenie_prod > /backups/manual_$(date +%Y%m%d_%H%M%S).sql

# Check SSL certificate expiry
echo | openssl s_client -servername api.promptgenie.app \
  -connect api.promptgenie.app:443 2>/dev/null | \
  openssl x509 -noout -dates
```

---

*For full environment variable reference see [ENVIRONMENT.md](ENVIRONMENT.md).  
For full deployment operations reference see [DEPLOYMENT.md](DEPLOYMENT.md).*
