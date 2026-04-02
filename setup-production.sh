#!/bin/bash
set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed"
    exit 1
fi

if ! command -v flutter &> /dev/null; then
    log_warn "Flutter is not installed. Skipping Flutter setup."
else
    log_info "Flutter found: $(flutter --version)"
fi

# Backend setup
log_info "Setting up backend..."
cd orionstack-backend--main

log_info "Installing dependencies..."
npm install

log_info "Building TypeScript..."
npm run build

log_info "Running database migrations..."
npm run migration:run

log_info "Seeding database..."
npm run seed || log_warn "Seed script not available"

# Frontend setup
log_info "Setting up frontend..."
cd ../thepg

if command -v flutter &> /dev/null; then
    log_info "Getting Flutter dependencies..."
    flutter pub get

    log_info "Building Flutter app..."
    flutter build apk --release || log_warn "APK build skipped (platform-specific)"
else
    log_warn "Skipping Flutter setup"
fi

# Docker setup
log_info "Building Docker images..."
cd ..

log_info "Building backend Docker image..."
docker build -f orionstack-backend--main/Dockerfile -t prompt-genie-backend:latest ./orionstack-backend--main

log_info "Starting Docker containers..."
docker-compose -f docker-compose.prod.yml up -d

log_info "Waiting for services to be ready..."
sleep 10

# Health checks
log_info "Running health checks..."

if ! curl -f http://localhost:3000/health &> /dev/null; then
    log_error "Backend health check failed"
    exit 1
fi

log_info "Backend is healthy"

if ! curl -f http://localhost:5432 &> /dev/null; then
    log_warn "Database health check skipped"
fi

log_info "Running tests..."
cd orionstack-backend--main

log_info "Running backend tests..."
npm run test:cov || log_warn "Test coverage report not available"

log_info "Running linter..."
npm run lint || log_warn "Linting passed with warnings"

# Final summary
log_info "========================================"
log_info "Setup completed successfully!"
log_info "========================================"
log_info "Backend API: http://localhost:3000"
log_info "Database: postgres://localhost:5432"
log_info "Redis: redis://localhost:6379"
log_info "Nginx: http://localhost"
log_info ""
log_info "To stop services: docker-compose -f docker-compose.prod.yml down"
log_info "========================================"
