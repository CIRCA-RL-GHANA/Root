#!/bin/bash
# ============================================
# SSL Certificate Setup with Let's Encrypt
# Run once during initial server setup
# ============================================
set -euo pipefail

DOMAIN="${1:?Usage: $0 <domain> [email]}"
EMAIL="${2:-admin@$DOMAIN}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting up SSL for: $DOMAIN"
echo "Admin email: $EMAIL"

# Create directories
mkdir -p "$ROOT_DIR/certbot/conf"
mkdir -p "$ROOT_DIR/certbot/www"

# Update nginx.conf with actual domain
sed -i "s/yourdomain.com/$DOMAIN/g" "$ROOT_DIR/nginx/nginx.conf"

echo "Starting nginx for ACME challenge..."
docker compose -f "$ROOT_DIR/docker-compose.prod.yml" up -d nginx

echo "Requesting certificate..."
docker compose -f "$ROOT_DIR/docker-compose.prod.yml" run --rm certbot \
  certbot certonly --webroot \
  -w /var/www/certbot \
  -d "$DOMAIN" \
  -d "www.$DOMAIN" \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  --force-renewal

echo "Reloading nginx with SSL..."
docker compose -f "$ROOT_DIR/docker-compose.prod.yml" exec nginx nginx -s reload

echo ""
echo "✅ SSL certificate installed for $DOMAIN"
echo "Certificate will auto-renew via certbot container."
