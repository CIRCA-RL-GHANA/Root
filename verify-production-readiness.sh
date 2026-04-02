#!/bin/bash

###############################################################################
# PROMPT Genie Platform - Production Readiness Verification Script
# 
# This script verifies that all critical components are production-ready
# and provides a detailed report on the current state of the platform.
#
# Usage: bash verify-production-readiness.sh
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Functions
log_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    ((CHECKS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((CHECKS_WARNING++))
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

separator() {
    echo ""
    echo "=====================================================  "
    echo "$1"
    echo "====================================================="
    echo ""
}

# Start verification
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC} PROMPT Genie Platform - Production Readiness Verification ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
separator "1. PREREQUISITES"

if command -v node &> /dev/null; then
    node_version=$(node -v)
    log_success "Node.js installed: $node_version"
else
    log_error "Node.js is not installed"
fi

if command -v npm &> /dev/null; then
    npm_version=$(npm -v)
    log_success "npm installed: $npm_version"
else
    log_error "npm is not installed"
fi

if command -v docker &> /dev/null; then
    docker_version=$(docker -v)
    log_success "Docker installed"
else
    log_error "Docker is not installed"
fi

if command -v git &> /dev/null; then
    log_success "Git installed"
else
    log_error "Git is not installed"
fi

# Check backend structure
separator "2. BACKEND STRUCTURE"

BACKEND_DIR="orionstack-backend--main"

if [ -d "$BACKEND_DIR" ]; then
    log_success "Backend directory exists"
    
    # Check key files
    [ -f "$BACKEND_DIR/package.json" ] && log_success "package.json exists" || log_error "package.json missing"
    [ -f "$BACKEND_DIR/tsconfig.json" ] && log_success "tsconfig.json exists" || log_error "tsconfig.json missing"
    [ -f "$BACKEND_DIR/Dockerfile" ] && log_success "Dockerfile exists" || log_error "Dockerfile missing"
    [ -f "$BACKEND_DIR/docker-compose.yml" ] && log_success "docker-compose.yml exists" || log_error "docker-compose.yml missing"
    [ -d "$BACKEND_DIR/src" ] && log_success "src directory exists" || log_error "src directory missing"
    
    # Check key source files
    [ -f "$BACKEND_DIR/src/app.module.ts" ] && log_success "app.module.ts exists" || log_error "app.module.ts missing"
    [ -f "$BACKEND_DIR/src/main.ts" ] && log_success "main.ts exists" || log_error "main.ts missing"
    [ -d "$BACKEND_DIR/src/modules" ] && {
        module_count=$(ls -d "$BACKEND_DIR/src/modules"/* 2>/dev/null | wc -l)
        if [ "$module_count" -ge 20 ]; then
            log_success "Backend modules present ($module_count modules)"
        else
            log_warning "Only $module_count modules found (expected 22)"
        fi
    } || log_error "modules directory missing"
    
    # Check critical modules
    [ -d "$BACKEND_DIR/src/gateway" ] && log_success "WebSocket gateway exists" || log_error "WebSocket gateway missing"
    [ -d "$BACKEND_DIR/src/modules/files" ] && log_success "File upload module exists" || log_error "File upload module missing"
    [ -d "$BACKEND_DIR/src/modules/social" ] && log_success "Social module (chat) exists" || log_error "Social module missing"
    [ -d "$BACKEND_DIR/src/modules/orders" ] && log_success "Orders module exists" || log_error "Orders module missing"
    [ -d "$BACKEND_DIR/src/modules/rides" ] && log_success "Rides module exists" || log_error "Rides module missing"
    
else
    log_error "Backend directory not found"
fi

# Check frontend structure
separator "3. FRONTEND STRUCTURE"

FRONTEND_DIR="thepg"

if [ -d "$FRONTEND_DIR" ]; then
    log_success "Frontend directory exists"
    
    # Check key files
    [ -f "$FRONTEND_DIR/pubspec.yaml" ] && log_success "pubspec.yaml exists" || log_error "pubspec.yaml missing"
    [ -f "$FRONTEND_DIR/android/build.gradle" ] && log_success "Android build.gradle exists" || log_error "Android build.gradle missing"
    [ -f "$FRONTEND_DIR/ios/Podfile" ] && log_success "iOS Podfile exists" || log_error "iOS Podfile missing"
    [ -d "$FRONTEND_DIR/lib" ] && log_success "lib directory exists" || log_error "lib directory missing"
    
    # Check lib structure
    [ -d "$FRONTEND_DIR/lib/core" ] && log_success "core directory exists" || log_warning "core directory missing"
    [ -d "$FRONTEND_DIR/lib/features" ] && {
        feature_count=$(ls -d "$FRONTEND_DIR/lib/features"/* 2>/dev/null | wc -l)
        if [ "$feature_count" -ge 10 ]; then
            log_success "Frontend features present ($feature_count features)"
        else
            log_warning "Only $feature_count features found (expected 12)"
        fi
    } || log_error "features directory missing"
    
    # Check critical services
    [ -f "$FRONTEND_DIR/lib/core/services/websocket_service.dart" ] && log_success "WebSocket service exists" || log_warning "WebSocket service missing"
    [ -f "$FRONTEND_DIR/lib/core/services/chat_service.dart" ] && log_success "Chat service exists" || log_warning "Chat service missing"
    
else
    log_error "Frontend directory not found"
fi

# Check configuration
separator "4. CONFIGURATION FILES"

[ -f "docker-compose.prod.yml" ] && log_success "production docker-compose exists" || log_error "production docker-compose missing"
[ -f "Makefile" ] && log_success "Makefile exists" || log_warning "Makefile missing"
[ -f ".env.example" ] && log_success ".env.example exists" || log_warning ".env.example missing"

# Check documentation
separator "5. DOCUMENTATION"

[ -f "README.md" ] && log_success "README.md exists" || log_warning "README.md missing"
[ -f "BACKEND_API_DOCUMENTATION.md" ] && log_success "API documentation exists" || log_warning "API documentation missing"
[ -f "PRODUCTION_IMPLEMENTATION_GUIDE.md" ] && log_success "Implementation guide exists" || log_warning "Implementation guide missing"
[ -f "PRODUCTION_COMPLETION_STATUS.md" ] && log_success "Completion status document exists" || log_warning "Completion status document missing"
[ -f "FINAL_COMPLETION_CHECKLIST.md" ] && log_success "Final checklist exists" || log_warning "Final checklist missing"

# Check backend dependencies
separator "6. BACKEND DEPENDENCIES (npm)"

if [ -f "$BACKEND_DIR/package.json" ]; then
    cd "$BACKEND_DIR"
    
    # Check for required packages
    if grep -q '"@nestjs/common"' package.json; then
        log_success "@nestjs/common is installed"
    else
        log_warning "@nestjs/common not found in package.json"
    fi
    
    if grep -q '"typeorm"' package.json; then
        log_success "typeorm is installed"
    else
        log_warning "typeorm not found in package.json"
    fi
    
    if grep -q '"pg"' package.json; then
        log_success "PostgreSQL driver is installed"
    else
        log_warning "PostgreSQL driver not found"
    fi
    
    if grep -q '"redis"' package.json; then
        log_success "Redis client is installed"
    else
        log_warning "Redis client not found"
    fi
    
    if grep -q '"socket.io"' package.json; then
        log_success "Socket.IO is installed"
    else
        log_warning "Socket.IO not found"
    fi
    
    if [ -d "node_modules" ]; then
        package_count=$(ls -d node_modules/* 2>/dev/null | wc -l)
        log_success "Dependencies installed ($package_count packages)"
    else
        log_warning "node_modules directory not found - run 'npm install'"
    fi
    
    cd - > /dev/null
else
    log_warning "package.json not found"
fi

# Check error handling
separator "7. ERROR HANDLING & SECURITY"

if [ -f "$BACKEND_DIR/src/common/filters/http-exception.filter.ts" ]; then
    log_success "HTTP exception filter configured"
else
    log_warning "HTTP exception filter not found"
fi

if grep -r "JwtAuthGuard" "$BACKEND_DIR/src/modules" &> /dev/null; then
    log_success "JWT authentication guards in use"
else
    log_warning "JWT guards not found in modules"
fi

if grep -r "@IsNotEmpty\|@IsEmail\|@IsString" "$BACKEND_DIR/src/modules" &> /dev/null; then
    log_success "DTO validation decorators in use"
else
    log_warning "Validation decorators not found"
fi

# Check database configuration
separator "8. DATABASE CONFIGURATION"

if [ -f "$BACKEND_DIR/src/config/typeorm.config.ts" ]; then
    log_success "TypeORM configuration exists"
else
    log_warning "TypeORM configuration not found"
fi

if [ -f "$BACKEND_DIR/src/database/data-source.ts" ]; then
    log_success "Data source configuration exists"
else
    log_warning "Data source configuration not found"
fi

if [ -d "$BACKEND_DIR/src/database/migrations" ]; then
    migration_count=$(ls "$BACKEND_DIR/src/database/migrations"/*.ts 2>/dev/null | wc -l)
    if [ "$migration_count" -gt 0 ]; then
        log_success "Database migrations present ($migration_count migrations)"
    else
        log_warning "No migrations found - run migrations before deployment"
    fi
else
    log_warning "Migrations directory not found"
fi

# Check Docker configuration
separator "9. DOCKER CONFIGURATION"

if [ -f "docker-compose.prod.yml" ]; then
    if grep -q "postgres" docker-compose.prod.yml; then
        log_success "PostgreSQL service configured"
    else
        log_warning "PostgreSQL service not found in docker-compose"
    fi
    
    if grep -q "redis" docker-compose.prod.yml; then
        log_success "Redis service configured"
    else
        log_warning "Redis service not found in docker-compose"
    fi
    
    if grep -q "nginx" docker-compose.prod.yml; then
        log_success "Nginx reverse proxy configured"
    else
        log_warning "Nginx not found in docker-compose"
    fi
fi

# Check scripts
separator "10. DEPLOYMENT SCRIPTS"

[ -f "scripts/deploy.sh" ] && log_success "Deployment script exists" || log_warning "Deployment script missing"
[ -f "scripts/setup-ssl.sh" ] && log_success "SSL setup script exists" || log_warning "SSL setup script missing"
[ -f "setup-production.sh" ] && log_success "Production setup script exists" || log_warning "Production setup script missing"

# Final summary
separator "VERIFICATION SUMMARY"

total_checks=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNING))

echo -e "${GREEN}Passed:${NC}   $CHECKS_PASSED"
echo -e "${RED}Failed:${NC}   $CHECKS_FAILED"
echo -e "${YELLOW}Warnings:${NC} $CHECKS_WARNING"
echo ""

pass_percentage=$((CHECKS_PASSED * 100 / total_checks))
echo "Overall Pass Rate: ${pass_percentage}%"

echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical components verified!${NC}"
    echo -e "${GREEN}✓ Platform is ready for further development.${NC}"
else
    echo -e "${RED}✗ Some critical components are missing or not configured properly.${NC}"
    echo -e "${RED}✗ Please review the errors above and address them before deployment.${NC}"
fi

if [ $CHECKS_WARNING -gt 0 ]; then
    echo -e "${YELLOW}⚠ There are ${CHECKS_WARNING} warnings that should be reviewed.${NC}"
fi

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Review any errors or warnings above"
echo "2. Run database migrations: cd orionstack-backend--main && npm run migration:run"
echo "3. Seed initial data: npm run seed"
echo "4. Run tests: npm run test"
echo "5. Start development: npm run start:dev"
echo ""
