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
8. [Fill in Your Environment Variables (.env)](#8-fill-in-your-environment-variables-env)
9. [Get an SSL Certificate (HTTPS)](#9-get-an-ssl-certificate-https)
10. [Deploy the Backend](#10-deploy-the-backend)
11. [Run Database Migrations](#11-run-database-migrations)
12. [Verify the API Is Live](#12-verify-the-api-is-live)
13. [Deploy the PWA to Vercel](#13-deploy-the-pwa-to-vercel)
14. [Set Up Automatic Deployments (GitHub Actions)](#14-set-up-automatic-deployments-github-actions)
15. [Set Up Automated Database Backups](#15-set-up-automated-database-backups)
16. [Final Go-Live Checklist](#16-final-go-live-checklist)
17. [Troubleshooting Common Problems](#17-troubleshooting-common-problems)

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
| **Vercel** | Hosting the Flutter PWA (free tier works) | vercel.com |

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

When it finishes, you will see `✓ VPS initialization complete`.

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

---

## 8. Fill in Your Environment Variables (.env)

The backend needs a configuration file called `.env` that contains all your secrets and settings. This file is never committed to GitHub — you create it on the server only.

### Step 8a — Copy the template

```bash
cd /opt/promptgenie
cp orionstack-backend--main/.env.example orionstack-backend--main/.env
```

### Step 8b — Open the file for editing

```bash
nano orionstack-backend--main/.env
```

> `nano` is a simple text editor. Use arrow keys to move. `Ctrl+O` saves. `Ctrl+X` exits.

### Step 8c — Generate your secrets

Open a second terminal on your **local machine** and run these commands to generate strong random values. Copy each output and paste it into the `.env` file.

```bash
# Generate JWT_SECRET (run this once)
openssl rand -base64 48

# Generate JWT_REFRESH_SECRET (run again — must be a DIFFERENT value)
openssl rand -base64 48

# Generate PIN_ENCRYPTION_KEY (exactly 32 hex characters)
openssl rand -hex 32

# Generate DB_PASSWORD
openssl rand -base64 32 | tr -d '/+=' | head -c 32

# Generate REDIS_PASSWORD
openssl rand -base64 32 | tr -d '/+=' | head -c 32
```

### Step 8d — Fill in each value

Here is every value you need to change. Lines starting with `#` are comments — leave them as-is.

```env
NODE_ENV=production
PORT=3000
API_PREFIX=api
API_VERSION=v1

# ── Database ──────────────────────────────────────────────────────────────────
DB_HOST=postgres
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=<paste DB_PASSWORD from Step 8c>
DB_NAME=promptgenie_prod
DB_SYNCHRONIZE=false
DB_LOGGING=false
DB_SSL=false

# ── JWT ───────────────────────────────────────────────────────────────────────
JWT_SECRET=<paste JWT_SECRET from Step 8c>
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=<paste JWT_REFRESH_SECRET from Step 8c — DIFFERENT value>
JWT_REFRESH_EXPIRES_IN=30d

# ── Security ──────────────────────────────────────────────────────────────────
BCRYPT_ROUNDS=12
OTP_EXPIRY_MINUTES=5
PIN_ENCRYPTION_KEY=<paste PIN_ENCRYPTION_KEY from Step 8c>

# ── Redis ─────────────────────────────────────────────────────────────────────
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=<paste REDIS_PASSWORD from Step 8c>
REDIS_DB=0

# ── Email (SendGrid) ──────────────────────────────────────────────────────────
# Get this from: sendgrid.com → Settings → API Keys → Create API Key
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EMAIL_FROM=noreply@promptgenie.com   # must be a verified address in your SendGrid account
EMAIL_FROM_NAME=PROMPT Genie

# ── SMS (Twilio) ──────────────────────────────────────────────────────────────
# Get these from: console.twilio.com → Account Info (top left panel)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Your Twilio phone number in +E.164 format, e.g. +14155552671
TWILIO_PHONE_NUMBER=+1XXXXXXXXXX

# ── CORS ──────────────────────────────────────────────────────────────────────
CORS_ORIGIN=https://promptgenie.app
CORS_CREDENTIALS=true

# ── Payments ──────────────────────────────────────────────────────────────────
# Change to flutterwave or paystack when you have live keys
PAYMENT_FACILITATOR_PROVIDER=mock
PAYMENT_FACILITATOR_SECRET_KEY=mock_key
PAYMENT_FACILITATOR_CURRENCY=GHS
PAYMENT_FACILITATOR_WEBHOOK_URL=https://api.promptgenie.app/api/v1/payments/webhook

# ── AI (optional — works without this) ───────────────────────────────────────
AI_ENABLED=true
TENSORFLOW_ENABLED=false
AI_API_KEY=                     # leave blank if you are not using OpenAI
AI_MODEL=gpt-4o-mini
AI_FRAUD_BLOCK_THRESHOLD=0.85
AI_FRAUD_REVIEW_THRESHOLD=0.55
AI_SURGE_MAX_MULTIPLIER=3.5
AI_PLATFORM_FEE_PCT=8
AI_MARKET_ENABLED=false        # leave false until fully tested

# ── Logging ───────────────────────────────────────────────────────────────────
LOG_LEVEL=info
LOG_FILE_PATH=./logs

# ── Rate Limiting ─────────────────────────────────────────────────────────────
THROTTLE_TTL=60
THROTTLE_LIMIT=100
```

Save the file: `Ctrl+O` → Enter → `Ctrl+X`

### Step 8e — Validate your .env

```bash
cd /opt/promptgenie
./scripts/validate-env.sh --strict
```

You should see all green checkmarks. Fix any errors it reports before continuing.

---

## 9. Get an SSL Certificate (HTTPS)

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

## 10. Deploy the Backend

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

## 11. Run Database Migrations

Migrations create all the database tables that the app needs. This only needs to be done once on first deployment (and again when new migrations are added in future updates).

```bash
cd /opt/promptgenie
make migrate
```

This runs 25 migrations in order. You will see each migration name print to the console as it applies.

**Verify all migrations ran:**
```bash
docker compose -f docker-compose.prod.yml exec app npm run migration:status
```

Every migration should show `[X]` (applied). None should show `[ ]` (pending).

---

## 12. Verify the API Is Live

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

### What a broken deployment looks like
- `curl: (6) Could not resolve host` → DNS has not propagated yet. Wait longer.
- `SSL: no certificate` error → SSL was not issued. Re-run Step 9.
- `502 Bad Gateway` from nginx → The NestJS app is not running. Check logs: `make logs SERVICE=app`
- `{"status":"error"}` in health response → Database connection failed. Check your DB_PASSWORD in `.env` and confirm `promptgenie-postgres` is healthy.

---

## 13. Deploy the PWA to Vercel

The Flutter web app (PWA) is deployed separately to Vercel's global CDN.

### Step 13a — Create a Vercel account

Go to [vercel.com](https://vercel.com) and sign up with your GitHub account.

### Step 13b — Import the Flutter repo

1. In Vercel, click **Add New → Project**.
2. Select the `CIRCA-RL-GHANA/Flutter-Ready` repository.
3. Vercel will detect `vercel.json` in the root and configure automatically.
4. Under **Environment Variables**, add:

   | Variable | Value |
   |---|---|
   | `API_BASE_URL` | `https://api.promptgenie.app` |
   | `ENVIRONMENT` | `production` |

5. Click **Deploy**.

The first deploy takes about 4 minutes to build the Flutter web app.

### Step 13c — Configure your domain on Vercel

1. In your Vercel project, go to **Settings → Domains**.
2. Add `promptgenie.app`.
3. Vercel will show you the DNS record to add. Go back to your domain registrar and add it:

   | Type | Name | Value |
   |---|---|---|
   | CNAME | `@` | `cname.vercel-dns.com` |
   | or A | `@` | `76.76.19.61` |

4. Back in Vercel, click **Verify**. Once green, your PWA is live at `https://promptgenie.app`.

---

## 14. Set Up Automatic Deployments (GitHub Actions)

Every time you push code to the `main` branch, GitHub will automatically deploy to your server. You need to add SSH credentials as GitHub Secrets.

### Step 14a — Create a deployment SSH key (on your local machine)

```bash
# Generate a NEW key pair just for deployments (do not reuse your personal key)
ssh-keygen -t ed25519 -C "promptgenie-deploy" -f ~/.ssh/promptgenie_deploy

# This creates two files:
# ~/.ssh/promptgenie_deploy      ← private key (goes into GitHub)
# ~/.ssh/promptgenie_deploy.pub  ← public key  (goes onto the server)
```

### Step 14b — Authorize the key on your server

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

### Step 14c — Add secrets to GitHub

1. Go to `github.com/CIRCA-RL-GHANA/Root` → **Settings → Secrets and variables → Actions**.
2. Click **New repository secret** and add each of the following:

   | Secret name | Value |
   |---|---|
   | `DEPLOY_HOST` | Your server IP address, e.g. `123.45.67.89` |
   | `DEPLOY_USER` | `promptgenie` |
   | `DEPLOY_SSH_KEY` | Contents of `~/.ssh/promptgenie_deploy` (the private key — starts with `-----BEGIN OPENSSH PRIVATE KEY-----`) |
   | `DEPLOY_PORT` | `22` |

3. Repeat for `github.com/CIRCA-RL-GHANA/NestJs-Ready` (backend repo) with the same secrets.

4. For the Flutter repo (`CIRCA-RL-GHANA/Flutter-Ready`), also go to **Settings → Secrets** and add:

   | Secret name | Value |
   |---|---|
   | `VERCEL_TOKEN` | Your Vercel API token — get it at vercel.com → Settings → Tokens |
   | `VERCEL_ORG_ID` | Found in your Vercel project settings |
   | `VERCEL_PROJECT_ID` | Found in your Vercel project settings |

### Step 14d — Test it

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

## 15. Set Up Automated Database Backups

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

---

## 16. Final Go-Live Checklist

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
[ ] All 25 migrations show [X] in migration:status

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

## 17. Troubleshooting Common Problems

### "Permission denied" when running SSH
Your SSH key is not authorized. Re-run Step 14b. Make sure you are using the correct username (`promptgenie`, not `root`).

### make deploy fails immediately — "DEPLOY_HOST not set"
This only matters for CI. On the server itself, you run `make deploy` directly — it does not need that variable.

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
make migrate
```

### SSL certificate fails — "too many redirects" or "challenge failed"
DNS has not propagated yet. Wait longer, then:
```bash
nslookup api.promptgenie.app    # must return your server IP
make ssl DOMAIN=api.promptgenie.app EMAIL=your@email.com
```

### Migrations fail — "relation already exists"
Part of the database was already created. Check what has run:
```bash
docker compose -f docker-compose.prod.yml exec app npm run migration:status
```
Skip already-applied ones — the migration runner handles this automatically. If you see a genuine conflict, contact your backend developer with the full error message.

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
make migrate

# Restart just the app (without touching the database)
docker compose -f docker-compose.prod.yml restart app

# Restart everything
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

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
