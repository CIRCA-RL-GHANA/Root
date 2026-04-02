#!/bin/bash

# ════════════════════════════════════════════════════════════════════════════════
# Environment Configuration Validation Script
# ════════════════════════════════════════════════════════════════════════════════
# Purpose: Validate that all required .env variables are set and properly configured
# Usage: ./scripts/validate-env.sh [--strict] [--help]
# ════════════════════════════════════════════════════════════════════════════════

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
SUCCESS=0

# Configuration
STRICT_MODE=false
WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ────────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ────────────────────────────────────────────────────────────────────────────────

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((SUCCESS++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

# Check if a variable is set in .env file
check_env_var() {
    local env_file=$1
    local var_name=$2
    local required=${3:-true}
    
    if grep -q "^${var_name}=" "$env_file" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Get value of env variable
get_env_value() {
    local env_file=$1
    local var_name=$2
    
    grep "^${var_name}=" "$env_file" 2>/dev/null | cut -d'=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Validate env file exists
validate_file_exists() {
    local env_file=$1
    local name=$2
    
    if [ ! -f "$env_file" ]; then
        print_error "$name not found: $env_file"
        return 1
    else
        print_success "$name exists: $env_file"
        return 0
    fi
}

# ────────────────────────────────────────────────────────────────────────────────
# Root .env Validation
# ────────────────────────────────────────────────────────────────────────────────

validate_root_env() {
    print_header "Validating Root Environment (.env)"
    
    local env_file="$WORKSPACE_ROOT/.env"
    
    if ! validate_file_exists "$env_file" "Root .env"; then
        print_error "Copy .env.example to .env: cp $WORKSPACE_ROOT/.env.example $WORKSPACE_ROOT/.env"
        return 1
    fi
    
    # Required variables
    local required_vars=(
        "NODE_ENV"
        "APP_VERSION"
        "BACKEND_PORT"
        "FRONTEND_PORT"
        "DB_HOST"
        "DB_PORT"
        "DB_USERNAME"
        "DB_PASSWORD"
        "DB_NAME"
        "REDIS_HOST"
        "REDIS_PORT"
        "JWT_SECRET"
        "JWT_REFRESH_SECRET"
    )
    
    # Check required variables
    for var in "${required_vars[@]}"; do
        if check_env_var "$env_file" "$var"; then
            local value=$(get_env_value "$env_file" "$var")
            
            # Check for placeholder values
            if [[ "$value" == "your-"* ]] || [[ "$value" == *"-here"* ]]; then
                print_warning "$var is set but appears to be a placeholder"
            else
                print_success "$var is configured"
            fi
        else
            print_error "$var is missing from .env"
        fi
    done
    
    # Optional but recommended variables
    local optional_vars=(
        "CORS_ORIGIN"
        "SENDGRID_API_KEY"
        "TWILIO_ACCOUNT_SID"
        "AWS_ACCESS_KEY_ID"
        "SENTRY_DSN"
    )
    
    for var in "${optional_vars[@]}"; do
        if check_env_var "$env_file" "$var"; then
            local value=$(get_env_value "$env_file" "$var")
            if [[ "$value" != "your-"* ]] && [[ "$value" != *"-here"* ]]; then
                print_success "$var is configured (optional)"
            fi
        fi
    done
}

# ────────────────────────────────────────────────────────────────────────────────
# Backend .env Validation
# ────────────────────────────────────────────────────────────────────────────────

validate_backend_env() {
    print_header "Validating Backend Environment"
    
    local env_file="$WORKSPACE_ROOT/orionstack-backend--main/.env"
    
    if [ ! -f "$env_file" ]; then
        print_warning "Backend .env not found, copying from .env.example"
        cp "$WORKSPACE_ROOT/orionstack-backend--main/.env.example" "$env_file"
    fi
    
    if ! validate_file_exists "$env_file" "Backend .env"; then
        return 1
    fi
    
    # Required variables
    local required_vars=(
        "NODE_ENV"
        "PORT"
        "DB_HOST"
        "DB_PORT"
        "DB_USERNAME"
        "DB_PASSWORD"
        "DB_NAME"
        "REDIS_HOST"
        "REDIS_PORT"
        "JWT_SECRET"
        "JWT_REFRESH_SECRET"
        "BCRYPT_ROUNDS"
        "OTP_LENGTH"
    )
    
    for var in "${required_vars[@]}"; do
        if check_env_var "$env_file" "$var"; then
            local value=$(get_env_value "$env_file" "$var")
            
            if [[ "$value" == "your-"* ]]; then
                print_warning "$var is set but appears to be a placeholder"
            else
                print_success "$var is configured"
            fi
        else
            print_error "$var is missing from backend .env"
        fi
    done
}

# ────────────────────────────────────────────────────────────────────────────────
# Flutter .env Validation
# ────────────────────────────────────────────────────────────────────────────────

validate_flutter_env() {
    print_header "Validating Flutter Configuration"
    
    local env_file="$WORKSPACE_ROOT/thepg/.env"
    local env_example="$WORKSPACE_ROOT/thepg/.env.example"
    
    if [ ! -f "$env_file" ]; then
        if [ -f "$env_example" ]; then
            print_warning "Flutter .env not found, creating from .env.example"
            cp "$env_example" "$env_file"
        else
            print_warning "Flutter .env.example not found"
            return 0
        fi
    fi
    
    if ! validate_file_exists "$env_file" "Flutter .env"; then
        return 1
    fi
    
    # Check for key Flutter configuration
    local flutter_vars=(
        "APP_ENV"
        "API_BASE_URL"
        "API_TIMEOUT"
        "FEATURE_BIOMETRIC_AUTH"
        "THEME_MODE"
    )
    
    for var in "${flutter_vars[@]}"; do
        if check_env_var "$env_file" "$var"; then
            print_success "Flutter $var is configured"
        else
            print_warning "Flutter $var is not set (optional)"
        fi
    done
}

# ────────────────────────────────────────────────────────────────────────────────
# Service Connectivity Checks
# ────────────────────────────────────────────────────────────────────────────────

validate_services() {
    print_header "Validating Service Connectivity"
    
    # Only perform connectivity checks if .env exists
    if [ ! -f "$WORKSPACE_ROOT/.env" ]; then
        print_warning "Skipping connectivity checks (no .env file)"
        return 0
    fi
    
    # Load .env variables
    set -a
    source "$WORKSPACE_ROOT/.env" 2>/dev/null || true
    set +a
    
    # Check Docker
    if command -v docker &> /dev/null; then
        if docker ps &>/dev/null; then
            print_success "Docker is running"
        else
            print_error "Docker daemon is not running"
        fi
    else
        print_warning "Docker is not installed"
    fi
    
    # Check Node.js
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        print_success "Node.js is installed: $node_version"
    else
        print_error "Node.js is not installed"
    fi
    
    # Check Flutter
    if command -v flutter &> /dev/null; then
        local flutter_version=$(flutter --version | head -n1)
        print_success "Flutter is installed: $flutter_version"
    else
        print_warning "Flutter is not installed (required for mobile development)"
    fi
    
    # Check PostgreSQL connectivity (if running)
    if [ ! -z "$DB_HOST" ] && [ ! -z "$DB_PORT" ]; then
        print_warning "Database connectivity check requires psql, skipping"
    fi
}

# ────────────────────────────────────────────────────────────────────────────────
# Generate Secrets Section
# ────────────────────────────────────────────────────────────────────────────────

generate_secrets() {
    print_header "Generating Required Secrets"
    
    echo -e "${YELLOW}Run these commands to generate secure values:${NC}\n"
    
    echo "JWT_SECRET:"
    echo "  openssl rand -base64 64"
    echo ""
    
    echo "JWT_REFRESH_SECRET:"
    echo "  openssl rand -base64 64"
    echo ""
    
    echo "PIN_ENCRYPTION_KEY:"
    echo "  openssl rand -base64 32"
    echo ""
    
    echo "HIVE_ENCRYPTION_KEY (Flutter):"
    echo "  openssl rand -base64 32"
}

# ────────────────────────────────────────────────────────────────────────────────
# Help Text
# ────────────────────────────────────────────────────────────────────────────────

show_help() {
    cat << EOF
${BLUE}Environment Configuration Validation Script${NC}

${YELLOW}Usage:${NC}
  ./scripts/validate-env.sh [OPTIONS]

${YELLOW}Options:${NC}
  --strict        Exit with error if any issues found
  --generate      Show secret generation commands
  --help          Show this help message

${YELLOW}Description:${NC}
  This script validates that all required environment variables are:
  1. Present in .env files
  2. Not set to placeholder values
  3. Properly configured for your environment

${YELLOW}Files Checked:${NC}
  - .env (root workspace)
  - orionstack-backend--main/.env (NestJS backend)
  - thepg/.env (Flutter app)

${YELLOW}Examples:${NC}
  ./scripts/validate-env.sh              # Standard validation
  ./scripts/validate-env.sh --strict     # Fail on warnings
  ./scripts/validate-env.sh --generate   # Show secret generation

${YELLOW}For more information:${NC}
  - See ENVIRONMENT_CONFIGURATION_GUIDE.md
  - See thepg/CONFIGURATION_GUIDE.md
  - See README.md
EOF
}

# ────────────────────────────────────────────────────────────────────────────────
# Main Execution
# ────────────────────────────────────────────────────────────────────────────────

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            --strict)
                STRICT_MODE=true
                shift
                ;;
            --generate)
                generate_secrets
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Run validations
    validate_root_env
    validate_backend_env
    validate_flutter_env
    validate_services
    
    # Summary
    print_header "Validation Summary"
    
    echo ""
    echo -e "${GREEN}Success:${NC} $SUCCESS"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo -e "${RED}Errors:${NC} $ERRORS"
    echo ""
    
    if [ $ERRORS -eq 0 ]; then
        echo -e "${GREEN}✓ Environment validation passed!${NC}"
        
        if [ $WARNINGS -gt 0 ]; then
            echo -e "${YELLOW}⚠ There are $WARNINGS warnings to review${NC}"
            
            if [ "$STRICT_MODE" = true ]; then
                exit 1
            fi
        fi
        
        exit 0
    else
        echo -e "${RED}✗ Environment validation failed!${NC}"
        echo -e "${RED}Please fix the errors above and try again.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
