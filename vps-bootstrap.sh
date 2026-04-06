#!/usr/bin/env bash
# =============================================================================
# vps-bootstrap.sh — One-command deploy for PROMPT Genie on a Hostinger VPS
#
# Usage (run as root or a sudo-enabled user):
#   curl -fsSL https://raw.githubusercontent.com/CIRCA-RL-GHANA/Root/main/vps-bootstrap.sh | bash
#
# What it does:
#   1. Installs Docker Engine + Docker Compose plugin (Debian/Ubuntu)
#   2. Clones the repo (or git-pulls if it already exists)
#   3. Scaffolds a .env from .env.example if one doesn't exist
#   4. Brings the stack up with docker compose
# =============================================================================
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${GREEN}[✔]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✘]${NC} $*" >&2; exit 1; }
step()  { echo -e "\n${BLUE}▶ $*${NC}"; }

# ── Config ────────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/CIRCA-RL-GHANA/Root.git"
REPO_BRANCH="main"
DEPLOY_DIR="/opt/promptgenie"
COMPOSE_FILE="docker-compose.prod.yml"

# ── Root check ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  warn "Not running as root — will use sudo where needed."
  SUDO="sudo"
else
  SUDO=""
fi

# ── 1. Install Docker if missing ──────────────────────────────────────────────
step "Checking Docker installation"
if command -v docker &>/dev/null; then
  info "Docker already installed: $(docker --version)"
else
  warn "Docker not found — installing..."
  if ! command -v apt-get &>/dev/null; then
    error "This script supports Debian/Ubuntu only. Install Docker manually and re-run."
  fi
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq ca-certificates curl gnupg lsb-release
  $SUDO install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
  # shellcheck disable=SC1091
  CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
    | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
  $SUDO systemctl enable --now docker
  info "Docker installed: $(docker --version)"
fi

# Ensure the docker compose sub-command (v2) is available
if ! docker compose version &>/dev/null; then
  error "docker compose (v2 plugin) not found. Install docker-compose-plugin and retry."
fi
info "Docker Compose: $(docker compose version)"

# ── 2. Clone / update the repository ─────────────────────────────────────────
step "Fetching repository → ${DEPLOY_DIR}"
if [[ -d "${DEPLOY_DIR}/.git" ]]; then
  info "Repo already cloned — pulling latest from ${REPO_BRANCH}..."
  git -C "${DEPLOY_DIR}" fetch --all --prune
  git -C "${DEPLOY_DIR}" checkout "${REPO_BRANCH}"
  git -C "${DEPLOY_DIR}" pull --ff-only origin "${REPO_BRANCH}"
else
  $SUDO mkdir -p "${DEPLOY_DIR}"
  $SUDO chown "${USER:-$(id -un)}":"${USER:-$(id -un)}" "${DEPLOY_DIR}"
  git clone --branch "${REPO_BRANCH}" --depth 1 "${REPO_URL}" "${DEPLOY_DIR}"
fi
cd "${DEPLOY_DIR}"
info "Working directory: $(pwd)"

# ── 3. Scaffold .env ──────────────────────────────────────────────────────────
step "Checking environment file"
if [[ -f ".env" ]]; then
  info ".env already exists — skipping scaffold."
else
  if [[ -f ".env.example" ]]; then
    cp .env.example .env
    warn ".env created from .env.example."
    warn "⚠  IMPORTANT: Edit ${DEPLOY_DIR}/.env and fill in your secrets before the stack"
    warn "   will work correctly (DB passwords, JWT secrets, API keys, etc.)."
    warn ""
    warn "   Minimum required changes:"
    warn "     DB_PASSWORD       – set a strong password"
    warn "     REDIS_PASSWORD    – set a strong password"
    warn "     JWT_SECRET        – run: openssl rand -base64 64"
    warn "     JWT_REFRESH_SECRET – run: openssl rand -base64 64"
    warn ""
    warn "   Press ENTER to continue with placeholder values (only for testing),"
    warn "   or Ctrl-C now and edit .env first, then re-run this script."
    # Only prompt interactively when stdin is a terminal
    if [[ -t 0 ]]; then
      read -r -p ""
    fi
  else
    error ".env.example not found. Cannot scaffold .env — aborting."
  fi
fi

# ── 4. Bring the stack up ─────────────────────────────────────────────────────
step "Starting services (docker compose up)"
docker compose -f "${COMPOSE_FILE}" pull --ignore-pull-failures || true
docker compose -f "${COMPOSE_FILE}" build --no-cache
docker compose -f "${COMPOSE_FILE}" up -d

# ── 5. Wait for health ────────────────────────────────────────────────────────
step "Waiting for the API to become healthy (up to 90 s)"
MAX=18; ATTEMPT=0; HEALTHY=false
while [[ $ATTEMPT -lt $MAX ]]; do
  STATUS=$(docker compose -f "${COMPOSE_FILE}" ps --format json \
    | grep -o '"Health":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
  if docker compose -f "${COMPOSE_FILE}" ps | grep -qE "(healthy)"; then
    HEALTHY=true; break
  fi
  echo "  Waiting... (${ATTEMPT}/${MAX})"
  sleep 5
  (( ATTEMPT++ ))
done

if $HEALTHY; then
  info "Stack is healthy."
else
  warn "Stack did not reach healthy state within 90 s — check logs below."
  docker compose -f "${COMPOSE_FILE}" ps
fi

# ── 6. Quick smoke-test ───────────────────────────────────────────────────────
step "Smoke-testing the API"
VPS_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
  "http://localhost/api/v1/health/live" 2>/dev/null || echo "unreachable")
if [[ "$API_STATUS" == "200" ]]; then
  info "Health endpoint responded 200 ✔"
else
  warn "Health endpoint returned: ${API_STATUS} — the app may still be starting."
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        🚀  DEPLOYMENT COMPLETE                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Deploy directory : ${DEPLOY_DIR}"
echo "  API (via nginx)  : http://${VPS_IP}/api/v1"
echo "  Health check     : http://${VPS_IP}/api/v1/health/live"
echo ""
echo "  Useful commands:"
echo "    docker compose -f ${DEPLOY_DIR}/${COMPOSE_FILE} ps"
echo "    docker compose -f ${DEPLOY_DIR}/${COMPOSE_FILE} logs -f app"
echo "    docker compose -f ${DEPLOY_DIR}/${COMPOSE_FILE} down"
echo ""
echo -e "  ${YELLOW}After pointing your domain and running Certbot, activate HTTPS:${NC}"
echo "    mv ${DEPLOY_DIR}/nginx/conf.d/ssl.conf.disabled \\"
echo "       ${DEPLOY_DIR}/nginx/conf.d/ssl.conf"
echo "    docker compose -f ${DEPLOY_DIR}/${COMPOSE_FILE} exec nginx nginx -s reload"
echo ""
