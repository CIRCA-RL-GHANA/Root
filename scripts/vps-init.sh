#!/bin/bash
# ============================================================
# VPS Initial Setup — Hostinger Ubuntu 22.04
# Run once as root immediately after provisioning.
# Usage: bash scripts/vps-init.sh [--domain api.promptgenie.app] [--email admin@promptgenie.app]
# ============================================================
set -euo pipefail

# ── Parse args ──────────────────────────────────────────────────────────────
DOMAIN=""
EMAIL=""
APP_DIR="/opt/orionstack"
DEPLOY_USER="orionstack"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2 ;;
    --email)  EMAIL="$2";  shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$DOMAIN" || -z "$EMAIL" ]]; then
  read -rp "API domain (e.g. api.promptgenie.app): " DOMAIN
  read -rp "SSL/Let's Encrypt contact email:        " EMAIL
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()   { echo -e "${BLUE}[›]${NC} $*"; }
ok()    { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
die()   { echo -e "${RED}[✗]${NC} $*"; exit 1; }

[[ $EUID -eq 0 ]] || die "Run this script as root (sudo bash vps-init.sh)"

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
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/'          /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/'   /etc/ssh/sshd_config
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/'                  /etc/ssh/sshd_config
systemctl reload sshd
ok "SSH hardened (key-only, no root login)"

# ── Kernel network tuning ────────────────────────────────────────────────────
log "Tuning kernel network params..."
cat > /etc/sysctl.d/99-orionstack.conf <<'EOF'
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
vm.overcommit_memory = 1
EOF
sysctl -p /etc/sysctl.d/99-orionstack.conf >/dev/null
ok "Kernel tuning applied"

# ── SSL via Let's Encrypt (Certbot standalone) ────────────────────────────────
log "Issuing SSL certificate for $DOMAIN..."
if [[ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
  docker run --rm -p 80:80 \
    -v /opt/orionstack/certbot/conf:/etc/letsencrypt \
    -v /opt/orionstack/certbot/www:/var/www/certbot \
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
fi

# ── Auto-renew SSL via cron ───────────────────────────────────────────────────
CRON_RENEW="0 3 * * * docker run --rm \
  -v /opt/orionstack/certbot/conf:/etc/letsencrypt \
  -v /opt/orionstack/certbot/www:/var/www/certbot \
  certbot/certbot renew --quiet && \
  docker exec orionstack-nginx nginx -s reload 2>/dev/null || true"

(crontab -l 2>/dev/null | grep -v certbot; echo "$CRON_RENEW") | crontab -
ok "SSL auto-renewal cron registered"

# ── Logrotate ────────────────────────────────────────────────────────────────
cat > /etc/logrotate.d/orionstack <<EOF
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
echo "  3.  Set GitHub secrets:"
echo "      VPS_HOST=$0 $(hostname -I | awk '{print $1}')"
echo "      VPS_USER=$DEPLOY_USER"
echo "      VPS_SSH_KEY=<private key content>"
echo "      VPS_PORT=22"
echo "  4.  Push to main — GitHub Actions will deploy automatically."
echo ""
