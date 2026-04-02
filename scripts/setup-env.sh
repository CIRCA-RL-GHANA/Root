#!/bin/bash

# ════════════════════════════════════════════════════════════════════════════════
# PROMPT Genie Development Environment Setup Script
# ════════════════════════════════════════════════════════════════════════════════
# Purpose: Quickly initialize development environment with all required .env files
# Usage: ./scripts/setup-env.sh [--mode=development|staging|production]
# ════════════════════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="development"

# ────────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ────────────────────────────────────────────────────────────────────────────────

print_header() {
    echo ""
    echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Generate a random secret
generate_secret() {
    if command -v openssl &> /dev/null; then
        openssl rand -base64 $1 2>/dev/null | tr -d '\n'
    else
        print_warning "openssl not found, using weak random secret"
        head /dev/urandom | tr -dc A-Za-z0-9 | head -c $1
    fi
}

# Create .env file from template
setup_env_file() {
    local template_file="$1"
    local target_file="$2"
    local description="$3"
    
    print_info "Setting up $description"
    
    if [ -f "$target_file" ]; then
        print_warning "$description already exists, skipping"
        return 0
    fi
    
    if [ ! -f "$template_file" ]; then
        print_error "$template_file not found"
        return 1
    fi
    
    # Copy template
    cp "$template_file" "$target_file"
    print_success "Created $description from template"
    
    return 0
}

# ────────────────────────────────────────────────────────────────────────────────
# Root Environment Setup
# ────────────────────────────────────────────────────────────────────────────────

setup_root_env() {
    print_header "Setting up Root Environment"
    
    local env_file="$WORKSPACE_ROOT/.env"
    local env_template="$WORKSPACE_ROOT/.env.example"
    
    setup_env_file "$env_template" "$env_file" "Root .env"
    
    if [ ! -f "$env_file" ]; then
        return 1
    fi
    
    # Generate secrets
    print_info "Generating JWT secrets..."
    local jwt_secret=$(generate_secret 64)
    local jwt_refresh=$(generate_secret 64)
    
    # Update secrets in .env (platform-specific sed)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|^JWT_SECRET=.*|JWT_SECRET=$jwt_secret|" "$env_file"
        sed -i '' "s|^JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$jwt_refresh|" "$env_file"
    else
        # Linux
        sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$jwt_secret|" "$env_file"
        sed -i "s|^JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$jwt_refresh|" "$env_file"
    fi
    
    # Set mode
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^NODE_ENV=.*|NODE_ENV=$MODE|" "$env_file"
    else
        sed -i "s|^NODE_ENV=.*|NODE_ENV=$MODE|" "$env_file"
    fi
    
    print_success "Generated and configured secrets for root .env"
}

# ────────────────────────────────────────────────────────────────────────────────
# Backend Environment Setup
# ────────────────────────────────────────────────────────────────────────────────

setup_backend_env() {
    print_header "Setting up Backend Environment"
    
    local env_file="$WORKSPACE_ROOT/orionstack-backend--main/.env"
    local env_template="$WORKSPACE_ROOT/orionstack-backend--main/.env.example"
    
    setup_env_file "$env_template" "$env_file" "Backend .env"
    
    if [ ! -f "$env_file" ]; then
        return 1
    fi
    
    # Generate secrets
    print_info "Generating backend secrets..."
    local jwt_secret=$(generate_secret 64)
    local jwt_refresh=$(generate_secret 64)
    local bcrypt_rounds=12
    local otp_length=6
    local pin_key=$(generate_secret 32)
    
    # Update .env with generated secrets
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^NODE_ENV=.*|NODE_ENV=$MODE|" "$env_file"
        sed -i '' "s|^JWT_SECRET=.*|JWT_SECRET=$jwt_secret|" "$env_file"
        sed -i '' "s|^JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$jwt_refresh|" "$env_file"
        sed -i '' "s|^BCRYPT_ROUNDS=.*|BCRYPT_ROUNDS=$bcrypt_rounds|" "$env_file"
        sed -i '' "s|^OTP_LENGTH=.*|OTP_LENGTH=$otp_length|" "$env_file"
        sed -i '' "s|^PIN_ENCRYPTION_KEY=.*|PIN_ENCRYPTION_KEY=$pin_key|" "$env_file"
    else
        sed -i "s|^NODE_ENV=.*|NODE_ENV=$MODE|" "$env_file"
        sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$jwt_secret|" "$env_file"
        sed -i "s|^JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$jwt_refresh|" "$env_file"
        sed -i "s|^BCRYPT_ROUNDS=.*|BCRYPT_ROUNDS=$bcrypt_rounds|" "$env_file"
        sed -i "s|^OTP_LENGTH=.*|OTP_LENGTH=$otp_length|" "$env_file"
        sed -i "s|^PIN_ENCRYPTION_KEY=.*|PIN_ENCRYPTION_KEY=$pin_key|" "$env_file"
    fi
    
    print_success "Generated and configured secrets for backend .env"
}

# ────────────────────────────────────────────────────────────────────────────────
# Flutter Environment Setup
# ────────────────────────────────────────────────────────────────────────────────

setup_flutter_env() {
    print_header "Setting up Flutter Configuration"
    
    local env_file="$WORKSPACE_ROOT/thepg/.env"
    local env_template="$WORKSPACE_ROOT/thepg/.env.example"
    
    setup_env_file "$env_template" "$env_file" "Flutter .env"
    
    if [ ! -f "$env_file" ]; then
        return 1
    fi
    
    # Update environment mode
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^APP_ENV=.*|APP_ENV=$MODE|" "$env_file"
    else
        sed -i "s|^APP_ENV=.*|APP_ENV=$MODE|" "$env_file"
    fi
    
    print_success "Configured Flutter .env for $MODE mode"
}

# ────────────────────────────────────────────────────────────────────────────────
# Dependencies Check
# ────────────────────────────────────────────────────────────────────────────────

check_dependencies() {
    print_header "Checking Dependencies"
    
    local all_ok=true
    
    # Check Node.js
    if command -v node &> /dev/null; then
        local node_ver=$(node --version)
        print_success "Node.js installed: $node_ver"
    else
        print_error "Node.js not installed (required for backend)"
        all_ok=false
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        local npm_ver=$(npm --version)
        print_success "npm installed: $npm_ver"
    else
        print_error "npm not installed (required for backend)"
        all_ok=false
    fi
    
    # Check Flutter
    if command -v flutter &> /dev/null; then
        print_success "Flutter installed"
    else
        print_warning "Flutter not installed (required for mobile development)"
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_success "Docker installed"
    else
        print_warning "Docker not installed (recommended for database/Redis)"
    fi
    
    # Check PostgreSQL client
    if command -v psql &> /dev/null; then
        print_success "PostgreSQL client installed"
    else
        print_info "PostgreSQL client not installed (optional, use psql if needed)"
    fi
    
    if [ "$all_ok" = false ]; then
        print_error "Some required dependencies are missing"
        return 1
    fi
    
    return 0
}

# ────────────────────────────────────────────────────────────────────────────────
# Next Steps
# ────────────────────────────────────────────────────────────────────────────────

show_next_steps() {
    print_header "Next Steps"
    
    echo ""
    echo -e "${BLUE}1. Start Database (if not already running):${NC}"
    echo "   docker-compose up -d postgres redis"
    echo ""
    
    echo -e "${BLUE}2. Backend Setup:${NC}"
    echo "   cd orionstack-backend--main"
    echo "   npm install"
    echo "   npm run migration:run"
    echo "   npm run start:dev"
    echo ""
    
    echo -e "${BLUE}3. Frontend Setup (in another terminal):${NC}"
    echo "   cd thepg"
    echo "   flutter pub get"
    echo "   flutter run -d web    # or -d chrome, -d android, -d ios, etc."
    echo ""
    
    echo -e "${BLUE}4. Validate Configuration (optional):${NC}"
    echo "   ./scripts/validate-env.sh"
    echo ""
    
    echo -e "${BLUE}5. Build & Deploy:${NC}"
    echo "   See DEPLOYMENT.md for production deployment"
    echo ""
    
    echo -e "${GREEN}✓ Environment setup complete!${NC}"
}

# ────────────────────────────────────────────────────────────────────────────────
# Main
# ────────────────────────────────────────────────────────────────────────────────

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode=*)
                MODE="${1#--mode=}"
                shift
                ;;
            --help)
                echo "Usage: $0 [--mode=development|staging|production]"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Validate mode
    if [[ ! "$MODE" =~ ^(development|staging|production)$ ]]; then
        print_error "Invalid mode. Use: development, staging, or production"
        exit 1
    fi
    
    print_header "PROMPT Genie Environment Setup - $MODE Mode"
    
    # Check if already set up
    if [ -f "$WORKSPACE_ROOT/.env" ] && [ -f "$WORKSPACE_ROOT/orionstack-backend--main/.env" ]; then
        print_warning "Environment already initialized"
        read -p "Continue with setup? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Run setup steps
    check_dependencies || true
    
    setup_root_env
    setup_backend_env
    setup_flutter_env
    
    # Show next steps
    show_next_steps
}

# Run main
main "$@"
