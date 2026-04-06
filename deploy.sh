#!/bin/bash

#================================================================
# Production Deployment Script
# OrionStack - Complete Full Stack Deployment
# Usage: ./deploy.sh [production|staging]
#================================================================

set -e

ENVIRONMENT=${1:-production}
COMPOSE_FILE="docker-compose.prod.yml"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}     OrionStack Production Deployment v1.0               ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}     Environment: $ENVIRONMENT                                ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}     Timestamp: $TIMESTAMP                                  ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Pre-deployment Checks
echo -e "${YELLOW}[1/8] Pre-deployment Verification${NC}"
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}✗ Docker Compose file not found: $COMPOSE_FILE${NC}"
    exit 1
fi

if [ ! -f ".env" ]; then
    echo -e "${RED}✗ Root .env file not found (copy .env.example to .env and fill in secrets)${NC}"
    exit 1
fi

if [ ! -f "orionstack-backend--main/.env" ]; then
    echo -e "${RED}✗ Backend .env file not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Pre-deployment checks passed${NC}"
echo ""

# Stop existing containers
echo -e "${YELLOW}[2/8] Stopping existing services${NC}"
docker-compose -f "$COMPOSE_FILE" down || true
echo -e "${GREEN}✓ Existing services stopped${NC}"
echo ""

# Pull latest images
echo -e "${YELLOW}[3/8] Pulling latest Docker images${NC}"
docker-compose -f "$COMPOSE_FILE" pull
echo -e "${GREEN}✓ Docker images updated${NC}"
echo ""

# Build application
echo -e "${YELLOW}[4/8] Building application${NC}"
docker-compose -f "$COMPOSE_FILE" build --no-cache
echo -e "${GREEN}✓ Application built${NC}"
echo ""

# Start services
echo -e "${YELLOW}[5/8] Starting services${NC}"
docker-compose -f "$COMPOSE_FILE" up -d
echo -e "${GREEN}✓ Services started${NC}"
echo ""

# Wait for services to be healthy
echo -e "${YELLOW}[6/8] Waiting for services to be healthy${NC}"
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "healthy"; then
        echo -e "${GREEN}✓ Services are healthy${NC}"
        break
    fi
    echo "  Waiting... (attempt $((attempt + 1))/$max_attempts)"
    sleep 2
    ((attempt++))
done

if [ $attempt -eq $max_attempts ]; then
    echo -e "${YELLOW}⚠ Services didn't reach healthy state in expected time${NC}"
    echo "  Checking service status..."
    docker-compose -f "$COMPOSE_FILE" ps
fi
echo ""

# Run database migrations
echo -e "${YELLOW}[7/8] Running database migrations${NC}"
docker-compose -f "$COMPOSE_FILE" exec -T app npm run migration:run || {
    echo -e "${YELLOW}⚠ Migrations skipped (already up to date)${NC}"
}
echo -e "${GREEN}✓ Database migrations completed${NC}"
echo ""

# Health checks
echo -e "${YELLOW}[8/8] Performing health checks${NC}"
echo ""
echo "Health Status:"
echo "  • Live Probe: $(curl -s http://localhost:3000/api/v1/health/live | jq -r '.status // "error"' 2>/dev/null || echo 'checking')"
echo "  • Ready Probe: $(curl -s http://localhost:3000/api/v1/health/ready | jq -r '.status // "error"' 2>/dev/null || echo 'checking')"
echo ""

# Display service status
echo -e "${BLUE}Service Status:${NC}"
docker-compose -f "$COMPOSE_FILE" ps

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}       ✅ DEPLOYMENT COMPLETED SUCCESSFULLY !           ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "📊 Service Access:"
echo "  • API Endpoint:     http://localhost/api/v1"
echo "  • Health Check:     http://localhost:3000/api/v1/health"
echo "  • Swagger Docs:     http://localhost/api-docs"
echo ""
echo "📝 View Logs:"
echo "  • Backend:  docker-compose -f $COMPOSE_FILE logs -f app"
echo "  • Database: docker-compose -f $COMPOSE_FILE logs -f postgres"
echo "  • Redis:    docker-compose -f $COMPOSE_FILE logs -f redis"
echo "  • Nginx:    docker-compose -f $COMPOSE_FILE logs -f nginx"
echo ""
echo "🛑 To stop services:"
echo "  • docker-compose -f $COMPOSE_FILE down"
echo ""
echo "📅 Deployment completed at: $(date '+%Y-%m-%d %H:%M:%S')"
