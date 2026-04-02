#!/bin/bash
# ============================================
# OrionStack Production Deployment Script
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$ROOT_DIR/docker-compose.prod.yml"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ---- Pre-flight checks ----
preflight() {
  log_info "Running pre-flight checks..."

  # Check Docker
  if ! command -v docker &>/dev/null; then
    log_error "Docker is not installed"
    exit 1
  fi
  log_ok "Docker: $(docker --version)"

  # Check Docker Compose
  if ! docker compose version &>/dev/null; then
    log_error "Docker Compose V2 is not installed"
    exit 1
  fi
  log_ok "Docker Compose: $(docker compose version --short)"

  # Check .env file
  if [ ! -f "$ROOT_DIR/.env" ]; then
    log_error ".env file not found at $ROOT_DIR/.env"
    log_info "Copy .env.example to .env and fill in production values"
    exit 1
  fi
  log_ok ".env file exists"

  # Validate critical env vars
  source "$ROOT_DIR/.env"
  local missing=0
  for var in DB_PASSWORD JWT_SECRET JWT_REFRESH_SECRET PIN_ENCRYPTION_KEY; do
    val="${!var:-}"
    if [ -z "$val" ] || [[ "$val" == *"CHANGE_ME"* ]]; then
      log_error "Environment variable $var is not set or has default value"
      missing=1
    fi
  done
  if [ $missing -eq 1 ]; then
    exit 1
  fi
  log_ok "Critical environment variables are set"

  # Check Nginx config
  if [ ! -f "$ROOT_DIR/nginx/nginx.conf" ]; then
    log_error "Nginx configuration not found"
    exit 1
  fi
  log_ok "Nginx configuration exists"

  log_ok "All pre-flight checks passed!"
  echo ""
}

# ---- Deploy ----
deploy() {
  log_info "Starting deployment..."

  cd "$ROOT_DIR"

  # Pull latest images
  log_info "Pulling latest images..."
  docker compose -f "$COMPOSE_FILE" pull

  # Build application
  log_info "Building application..."
  docker compose -f "$COMPOSE_FILE" build --no-cache app

  # Stop old containers and start new ones
  log_info "Deploying services..."
  docker compose -f "$COMPOSE_FILE" up -d --remove-orphans

  # Wait for health checks
  log_info "Waiting for services to be healthy..."
  local retries=0
  local max_retries=30
  while [ $retries -lt $max_retries ]; do
    if docker compose -f "$COMPOSE_FILE" ps | grep -q "unhealthy"; then
      retries=$((retries + 1))
      sleep 2
    else
      break
    fi
  done

  if [ $retries -eq $max_retries ]; then
    log_error "Services did not become healthy within timeout"
    docker compose -f "$COMPOSE_FILE" logs --tail=50 app
    exit 1
  fi

  log_ok "All services are running and healthy!"
}

# ---- Health check ----
healthcheck() {
  log_info "Running health checks..."

  local app_health
  app_health=$(docker exec orionstack-app wget -qO- http://localhost:3000/api/v1/health 2>/dev/null || echo "FAIL")

  if echo "$app_health" | grep -q '"status":"ok"'; then
    log_ok "Backend health check: PASSED"
  else
    log_error "Backend health check: FAILED"
    echo "$app_health"
    return 1
  fi

  # Check database connectivity
  local db_check
  db_check=$(docker exec orionstack-postgres pg_isready -U postgres 2>/dev/null || echo "FAIL")
  if echo "$db_check" | grep -q "accepting connections"; then
    log_ok "Database health check: PASSED"
  else
    log_error "Database health check: FAILED"
    return 1
  fi

  # Check Redis
  local redis_check
  redis_check=$(docker exec orionstack-redis redis-cli ping 2>/dev/null || echo "FAIL")
  if [ "$redis_check" = "PONG" ]; then
    log_ok "Redis health check: PASSED"
  else
    log_error "Redis health check: FAILED"
    return 1
  fi

  log_ok "All health checks passed!"
}

# ---- Status ----
status() {
  log_info "Service status:"
  docker compose -f "$COMPOSE_FILE" ps
  echo ""
  log_info "Resource usage:"
  docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" \
    orionstack-app orionstack-postgres orionstack-redis orionstack-nginx 2>/dev/null || true
}

# ---- Rollback ----
rollback() {
  log_warn "Rolling back to previous version..."
  cd "$ROOT_DIR"
  docker compose -f "$COMPOSE_FILE" down app
  docker compose -f "$COMPOSE_FILE" up -d app
  log_info "Rollback complete. Running health check..."
  sleep 10
  healthcheck
}

# ---- Logs ----
logs() {
  local service="${1:-app}"
  docker compose -f "$COMPOSE_FILE" logs -f --tail=100 "$service"
}

# ---- Main ----
case "${1:-help}" in
  deploy)
    preflight
    deploy
    healthcheck
    ;;
  healthcheck)
    healthcheck
    ;;
  status)
    status
    ;;
  rollback)
    rollback
    ;;
  logs)
    logs "${2:-app}"
    ;;
  preflight)
    preflight
    ;;
  *)
    echo "Usage: $0 {deploy|healthcheck|status|rollback|logs [service]|preflight}"
    echo ""
    echo "Commands:"
    echo "  deploy      - Full deployment (preflight + build + deploy + healthcheck)"
    echo "  healthcheck - Run health checks on all services"
    echo "  status      - Show service status and resource usage"
    echo "  rollback    - Rollback to previous deployment"
    echo "  logs        - Tail logs (default: app)"
    echo "  preflight   - Run pre-flight checks only"
    ;;
esac
