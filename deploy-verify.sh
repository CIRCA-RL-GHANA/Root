#!/bin/bash

#================================================================
# Production Deployment Verification Script
# OrionStack - Full Stack Deployment Readiness Check
#================================================================

set -e

echo "🚀 OrionStack Production Deployment Verification"
echo "=================================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Functions
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $2"
        return 0
    else
        echo -e "${RED}✗${NC} $2 (not found)"
        ((ERRORS++))
        return 1
    fi
}

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        return 0
    else
        echo -e "${RED}✗${NC} $2 (missing)"
        ((ERRORS++))
        return 1
    fi
}

check_directory() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        return 0
    else
        echo -e "${RED}✗${NC} $2 (missing)"
        ((ERRORS++))
        return 1
    fi
}

# System Requirements
echo "1️⃣  System Requirements"
echo "----------------------"
check_command "docker" "Docker installed"
check_command "docker-compose" "Docker Compose installed"
check_command "node" "Node.js installed"
check_command "npm" "npm installed"
echo ""

# File Structure
echo "2️⃣  Project Structure"
echo "--------------------"
check_directory "orionstack-backend--main" "Backend directory exists"
check_directory "thepg" "Frontend directory exists"
check_directory "nginx" "Nginx config directory exists"
check_file "docker-compose.prod.yml" "Production compose file exists"
check_file "Makefile" "Makefile exists"
echo ""

# Environment Configuration
echo "3️⃣  Environment Configuration"
echo "-----------------------------"
check_file "orionstack-backend--main/.env" "Backend .env file exists"
check_file "orionstack-backend--main/.env.example" "Backend .env.example exists"

# Verify critical env vars
if [ -f "orionstack-backend--main/.env" ]; then
    required_vars=("DB_HOST" "DB_PASSWORD" "JWT_SECRET" "REDIS_PASSWORD")
    for var in "${required_vars[@]}"; do
        if grep -q "^${var}=" "orionstack-backend--main/.env"; then
            echo -e "${GREEN}✓${NC} ${var} configured"
        else
            echo -e "${YELLOW}⚠${NC} ${var} not configured"
            ((WARNINGS++))
        fi
    done
fi
echo ""

# Backend Code Quality
echo "4️⃣  Backend Code Quality"
echo "------------------------"
cd orionstack-backend--main

# Check for TODOs in production code
if grep -r "// TODO" src/ 2>/dev/null | wc -l | grep -q "^0$"; then
    echo -e "${GREEN}✓${NC} No TODOs in backend source"
else
    TODOS=$(grep -r "// TODO" src/ 2>/dev/null | wc -l)
    echo -e "${RED}✗${NC} Found $TODOS TODO markers in backend"
    grep -r "// TODO" src/ | head -3
    ((ERRORS++))
fi

# Check if package.json has test script
if grep -q '"test":' package.json; then
    echo -e "${GREEN}✓${NC} Test script configured"
else
    echo -e "${YELLOW}⚠${NC} No test script in package.json"
    ((WARNINGS++))
fi

# Check if package.json has build script
if grep -q '"build":' package.json; then
    echo -e "${GREEN}✓${NC} Build script configured"
else
    echo -e "${RED}✗${NC} No build script in package.json"
    ((ERRORS++))
fi

# Check TypeScript config
check_file "tsconfig.json" "TypeScript configuration exists"
check_file "tsconfig.build.json" "TypeScript build config exists"

# Check key dependencies
echo ""
echo "Backend Dependencies:"
for dep in "@nestjs/core" "typeorm" "pg" "redis" "socket.io"; do
    if grep -q "\"$dep\"" package.json; then
        echo -e "${GREEN}✓${NC} $dep"
    else
        echo -e "${RED}✗${NC} $dep missing"
        ((ERRORS++))
    fi
done

cd ..
echo ""

# Frontend Code Quality
echo "5️⃣  Frontend Code Quality"
echo "-------------------------"

# Check Flutter pubspec.yaml
check_file "thepg/pubspec.yaml" "Flutter pubspec.yaml exists"

# Check for TODOs in Flutter code
if grep -r "// TODO\|// FIXME" thepg/lib 2>/dev/null | grep -v "toDouble" | wc -l | grep -q "^0$"; then
    echo -e "${GREEN}✓${NC} No TODOs in Flutter source"
else
    FLUTTER_TODOS=$(grep -r "// TODO\|// FIXME" thepg/lib 2>/dev/null | grep -v "toDouble" | wc -l)
    if [ "$FLUTTER_TODOS" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} No TODOs in Flutter source"
    else
        echo -e "${RED}✗${NC} Found $FLUTTER_TODOS TODO markers in Flutter"
        ((ERRORS++))
    fi
fi

# Docker Configuration
echo ""
echo "6️⃣  Docker Configuration"
echo "------------------------"
check_file "orionstack-backend--main/Dockerfile" "Backend Dockerfile exists"
check_file "nginx/nginx.conf" "Nginx configuration exists"

# Verify Dockerfile multi-stage
if grep -q "FROM.*AS production" orionstack-backend--main/Dockerfile; then
    echo -e "${GREEN}✓${NC} Dockerfile uses multi-stage build"
else
    echo -e "${YELLOW}⚠${NC} Dockerfile might not be optimized"
    ((WARNINGS++))
fi

echo ""

# Production Readiness
echo "7️⃣  Production Readiness"
echo "------------------------"

# Check for health endpoints
if grep -r "health" orionstack-backend--main/src/modules/health --include="*.ts" | grep -q "check"; then
    echo -e "${GREEN}✓${NC} Health check endpoints configured"
else
    echo -e "${YELLOW}⚠${NC} Health check endpoints might be missing"
    ((WARNINGS++))
fi

# Check for logging
if grep -r "Logger\|this.logger" orionstack-backend--main/src 2>/dev/null | wc -l | grep -qv "^0$"; then
    echo -e "${GREEN}✓${NC} Logging configured"
else
    echo -e "${YELLOW}⚠${NC} Limited logging detected"
    ((WARNINGS++))
fi

# Check for error handling
if grep -r "catch\|throw" orionstack-backend--main/src 2>/dev/null | wc -l | grep -qv "^0$"; then
    echo -e "${GREEN}✓${NC} Error handling implemented"
else
    echo -e "${RED}✗${NC} Insufficient error handling"
    ((ERRORS++))
fi

echo ""

# Deployment Files
echo "8️⃣  Deployment Files"
echo "--------------------"
check_file "scripts/deploy.sh" "Deploy script exists"
check_file "scripts/setup-ssl.sh" "SSL setup script exists"
check_file "DEPLOYMENT.md" "Deployment documentation exists"
check_file "docker-compose.yml" "Development compose file exists"

echo ""

# Final Summary
echo "📊 Verification Summary"
echo "======================"
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Ready for deployment.${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS errors found. Please fix before deployment.${NC}"
    exit 1
fi
