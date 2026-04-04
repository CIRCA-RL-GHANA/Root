#!/bin/bash
# ============================================================
# VPS Initial Setup — Hostinger Ubuntu 22.04
# Run once as root immediately after provisioning.
# Usage: bash scripts/vps-init.sh [--domain api.promptgenie.app] [--email admin@promptgenie.app]
# Recovery (locked out): bash scripts/vps-init.sh --recover --pubkey 'ssh-ed25519 AAAA...'
# ============================================================
set -euo pipefail

# ── Parse args ──────────────────────────────────────────────────────────────
DOMAIN=""
EMAIL=""
APP_DIR="/opt/promptgenie"
DEPLOY_USER="promptgenie"
RECOVER_MODE=false
CLI_PUBKEY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)  DOMAIN="$2";     shift 2 ;;
    --email)   EMAIL="$2";      shift 2 ;;
    --recover) RECOVER_MODE=true; shift ;;
    --pubkey)  CLI_PUBKEY="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Recovery mode: restore SSH access without running full setup ─────────────
if [[ "$RECOVER_MODE" == "true" ]]; then
  [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
  SSH_DIR="/home/$DEPLOY_USER/.ssh"
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  touch "$SSH_DIR/authorized_keys"
  chmod 600 "$SSH_DIR/authorized_keys"

  if [[ -n "$CLI_PUBKEY" ]]; then
    echo "$CLI_PUBKEY" >> "$SSH_DIR/authorized_keys"
  else
    echo "Paste your public key and press Enter:"
    read -r PUBKEY || true
    [[ -n "$PUBKEY" ]] && echo "$PUBKEY" >> "$SSH_DIR/authorized_keys"
  fi

  # Also add to root's authorized_keys so root login works for this session
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
  touch /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  if [[ -n "$CLI_PUBKEY" ]]; then
    grep -qxF "$CLI_PUBKEY" /root/.ssh/authorized_keys 2>/dev/null || echo "$CLI_PUBKEY" >> /root/.ssh/authorized_keys
  fi

  # Temporarily re-allow root login and pubkey auth
  sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
  sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/'  /etc/ssh/sshd_config
  systemctl reload sshd
  chown -R "$DEPLOY_USER:$DEPLOY_USER" "$SSH_DIR"
  echo "[✓] Recovery complete. Try: ssh $DEPLOY_USER@<ip>  OR  ssh root@<ip>"
  echo "[!] Re-run without --recover to finish full hardening once you're in."
  exit 0
fi

if [[ -z "$DOMAIN" || -z "$EMAIL" ]]; then
  read -rp "API domain (e.g. api.promptgenie.app): " DOMAIN || true
  read -rp "SSL/Let's Encrypt contact email:        " EMAIL || true
fi

[[ -n "$DOMAIN" ]] || { echo "Domain is required (--domain)"; exit 1; }
[[ -n "$EMAIL"  ]] || { echo "Email is required (--email)";  exit 1; }

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()   { echo -e "${BLUE}[›]${NC} $*"; }
ok()    { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
die()   { echo -e "${RED}[✗]${NC} $*"; exit 1; }

[[ $EUID -eq 0 ]] || die "Run this script as root (sudo bash vps-init.sh)"  # (already checked in --recover path)

# ── System update ────────────────────────────────────────────────────────────
log "Updating system packages..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
ok "System up to date"

# ── Essential packages ───────────────────────────────────────────────────────
log "Installing essential packages..."
apt-get install -y -qq \
  curl wget git unzip htop ufw fail2ban \
  apt-transport-https ca-certificates gnupg lsb-release \
  software-properties-common rsync jq
ok "Packages installed"

# ── Swap (safety net for 2–4 GB VPS) ────────────────────────────────────────
if ! swapon --show | grep -q '/swapfile'; then
  log "Creating 2 GB swap..."
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile -q
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  sysctl -w vm.swappiness=10 >/dev/null
  echo 'vm.swappiness=10' >> /etc/sysctl.conf
  ok "Swap created"
fi

# ── Docker ───────────────────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  log "Installing Docker..."
  curl -fsSL https://get.docker.com | bash -s -- --quiet
  systemctl enable docker --quiet
  systemctl start docker
  ok "Docker $(docker --version) installed"
else
  ok "Docker already installed: $(docker --version)"
fi

# ── Docker Compose v2 ────────────────────────────────────────────────────────
if ! docker compose version &>/dev/null; then
  log "Installing Docker Compose v2 plugin..."
  apt-get install -y -qq docker-compose-plugin
fi
ok "Docker Compose $(docker compose version --short)"

# ── Deploy user ──────────────────────────────────────────────────────────────
if ! id "$DEPLOY_USER" &>/dev/null; then
  log "Creating deploy user: $DEPLOY_USER"
  useradd -m -s /bin/bash "$DEPLOY_USER"
  usermod -aG docker "$DEPLOY_USER"
  ok "User $DEPLOY_USER created"
fi

# ── App directory ────────────────────────────────────────────────────────────
mkdir -p "$APP_DIR"/{logs,uploads,certbot/conf,certbot/www}
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$APP_DIR"
ok "App directory: $APP_DIR"

# ── GitHub Actions deploy key ────────────────────────────────────────────────
SSH_DIR="/home/$DEPLOY_USER/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ ! -f "$SSH_DIR/authorized_keys" ]]; then
  touch "$SSH_DIR/authorized_keys"
fi
chmod 600 "$SSH_DIR/authorized_keys"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$SSH_DIR"

warn "ACTION REQUIRED: Add your GitHub Actions deploy public key to:"
warn "  $SSH_DIR/authorized_keys"
warn "  Command: echo 'ssh-ed25519 AAAA... github-actions-deploy' >> $SSH_DIR/authorized_keys"

# ── UFW Firewall ─────────────────────────────────────────────────────────────
log "Configuring UFW firewall..."
ufw --force reset >/dev/null
ufw default deny incoming  >/dev/null
ufw default allow outgoing >/dev/null
ufw allow 22/tcp    comment 'SSH'
ufw allow 80/tcp    comment 'HTTP'
ufw allow 443/tcp   comment 'HTTPS'
ufw --force enable  >/dev/null
ok "Firewall configured (22, 80, 443 open)"

# ── Fail2ban ─────────────────────────────────────────────────────────────────
log "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5
backend  = systemd

[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF
systemctl enable fail2ban --quiet
systemctl restart fail2ban
ok "fail2ban active"

# ── SSH hardening ────────────────────────────────────────────────────────────
log "Hardening SSH..."

# Safety: never lock out password auth until the deploy user has at least one key.
if [[ ! -s "$SSH_DIR/authorized_keys" ]]; then
  if [[ -s /root/.ssh/authorized_keys ]]; then
    # Inherit the key that was used to log in as root
    cp /root/.ssh/authorized_keys "$SSH_DIR/authorized_keys"
    chown "$DEPLOY_USER:$DEPLOY_USER" "$SSH_DIR/authorized_keys"
    chmod 600 "$SSH_DIR/authorized_keys"
    ok "Copied root SSH key(s) → $SSH_DIR/authorized_keys"
  else
    warn "No SSH key found for $DEPLOY_USER. Paste your public key now (or press Enter to skip full hardening):"
    read -r PUBKEY || true
    if [[ -n "$PUBKEY" ]]; then
      echo "$PUBKEY" >> "$SSH_DIR/authorized_keys"
      chown "$DEPLOY_USER:$DEPLOY_USER" "$SSH_DIR/authorized_keys"
      chmod 600 "$SSH_DIR/authorized_keys"
      ok "Public key added for $DEPLOY_USER"
    else
        warn "No key provided — skipping PermitRootLogin/PasswordAuthentication hardening."
      warn "Add a key to $SSH_DIR/authorized_keys then re-run to complete hardening."
      warn "Or run:  bash vps-init.sh --recover --pubkey 'ssh-ed25519 AAAA...'"
      sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
      sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/'                   /etc/ssh/sshd_config
      systemctl reload sshd
      ok "SSH partially hardened (key auth enabled; root + password left open until key is added)"
      SKIP_SSH_HARDEN=true
    fi
  fi
fi

if [[ "${SKIP_SSH_HARDEN:-false}" != "true" ]]; then
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/'          /etc/ssh/sshd_config
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/'   /etc/ssh/sshd_config
  sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/'                  /etc/ssh/sshd_config
  systemctl reload sshd
  ok "SSH hardened (key-only, no root login)"
fi

# ── Kernel network tuning ────────────────────────────────────────────────────
log "Tuning kernel network params..."
cat > /etc/sysctl.d/99-promptgenie.conf <<'EOF'
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
vm.overcommit_memory = 1
EOF
sysctl -p /etc/sysctl.d/99-promptgenie.conf >/dev/null
ok "Kernel tuning applied"

# ── SSL via Let's Encrypt (Certbot standalone) ────────────────────────────────
log "Issuing SSL certificate for $DOMAIN..."
if [[ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
  docker run --rm -p 80:80 \
    -v /opt/promptgenie/certbot/conf:/etc/letsencrypt \
    -v /opt/promptgenie/certbot/www:/var/www/certbot \
    certbot/certbot certonly \
      --standalone \
      --agree-tos \
      --no-eff-email \
      -m "$EMAIL" \
      -d "$DOMAIN" \
      --non-interactive \
      --quiet
  ok "SSL certificate issued for $DOMAIN"
else
  ok "SSL certificate already exists for $DOMAIN"
fi

# ── Update nginx cert paths ───────────────────────────────────────────────────
log "Patching nginx.conf SSL domain..."
if [[ -f "$APP_DIR/nginx/nginx.conf" ]]; then
  sed -i "s|/etc/letsencrypt/live/[^/]*/fullchain.pem|/etc/letsencrypt/live/$DOMAIN/fullchain.pem|g" \
    "$APP_DIR/nginx/nginx.conf"
  sed -i "s|/etc/letsencrypt/live/[^/]*/privkey.pem|/etc/letsencrypt/live/$DOMAIN/privkey.pem|g" \
    "$APP_DIR/nginx/nginx.conf"
  ok "nginx.conf SSL paths updated"
else
  warn "nginx.conf not yet at $APP_DIR/nginx/ — SSL paths will be patched after first deploy"
fi

# ── Auto-renew SSL via cron ───────────────────────────────────────────────────
CRON_RENEW="0 3 * * * docker run --rm \
  -v /opt/promptgenie/certbot/conf:/etc/letsencrypt \
  -v /opt/promptgenie/certbot/www:/var/www/certbot \
  certbot/certbot renew --quiet && \
  docker exec promptgenie-nginx nginx -s reload 2>/dev/null || true"

(crontab -l 2>/dev/null | grep -v certbot; echo "$CRON_RENEW") | crontab -
ok "SSL auto-renewal cron registered"

# ── Logrotate ────────────────────────────────────────────────────────────────
cat > /etc/logrotate.d/promptgenie <<EOF
$APP_DIR/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
EOF
ok "Log rotation configured"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           VPS initialisation complete!                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Domain  : https://$DOMAIN"
echo "  App dir : $APP_DIR"
echo "  User    : $DEPLOY_USER"
echo ""
echo "  Next steps:"
echo "  1.  Add GitHub Actions SSH public key to:"
echo "      $SSH_DIR/authorized_keys"
echo "  2.  Copy .env.production → $APP_DIR/.env  (never commit this!)"
echo "  3.  Set GitHub secrets (name them EXACTLY as shown — the CI workflows expect these names):"
echo "      DEPLOY_HOST=$(hostname -I | awk '{print $1}')"
echo "      DEPLOY_USER=$DEPLOY_USER"
echo "      DEPLOY_SSH_KEY=<contents of ~/.ssh/promptgenie_deploy private key>"
echo "      DEPLOY_PORT=22"
echo "  4.  Push to main — GitHub Actions will deploy automatically."
echo ""
