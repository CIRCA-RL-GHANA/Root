# ============================================
# Makefile — PROMPT Genie Production Commands
# ============================================
.PHONY: help setup dev build deploy logs status healthcheck rollback clean ssl migrate

COMPOSE_PROD = docker compose -f docker-compose.prod.yml
COMPOSE_DEV  = cd orionstack-backend--main && docker compose

# ---- Help ----
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ---- Setup ----
setup: ## Install all dependencies (backend + frontend)
	cd orionstack-backend--main && npm install
	cd thepg && flutter pub get

setup-backend: ## Install backend dependencies only
	cd orionstack-backend--main && npm install

setup-frontend: ## Install frontend dependencies only
	cd thepg && flutter pub get

# ---- Development ----
dev-backend: ## Start backend in dev mode
	cd orionstack-backend--main && npm run start:dev

dev-db: ## Start dev database + Redis
	$(COMPOSE_DEV) up -d postgres redis

dev-db-down: ## Stop dev database + Redis
	$(COMPOSE_DEV) down

# ---- Build ----
build-backend: ## Build NestJS backend
	cd orionstack-backend--main && npm run build

build-apk: ## Build Android APK (release)
	cd thepg && flutter build apk --release --obfuscate --split-debug-info=build/debug-info

build-aab: ## Build Android App Bundle (release)
	cd thepg && flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

build-ios: ## Build iOS IPA (release)
	cd thepg && cd ios && pod install --repo-update && cd .. && flutter build ipa --release --obfuscate --split-debug-info=build/debug-info --export-options-plist=ios/ExportOptions.plist

build-web: ## Build Flutter Web / PWA
	cd thepg && flutter build web --release --web-renderer canvaskit --pwa-strategy offline-first

build-docker: ## Build production Docker image
	$(COMPOSE_PROD) build --no-cache app

# ---- Production Deployment ----
deploy: ## Full production deployment (preflight + build + deploy + healthcheck)
	chmod +x scripts/*.sh
	./scripts/deploy.sh deploy

preflight: ## Run pre-deployment checks
	chmod +x scripts/*.sh
	./scripts/deploy.sh preflight

ssl: ## Setup SSL certificate (usage: make ssl DOMAIN=api.genieinprompt.app EMAIL=admin@genieinprompt.app)
	chmod +x scripts/*.sh
	./scripts/setup-ssl.sh $(DOMAIN) $(EMAIL)

# ---- Operations ----
status: ## Show service status
	$(COMPOSE_PROD) ps
	@echo ""
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" promptgenie-app promptgenie-postgres promptgenie-redis promptgenie-nginx 2>/dev/null || true

healthcheck: ## Run health checks on all services
	chmod +x scripts/*.sh
	./scripts/deploy.sh healthcheck

logs: ## Show app logs (usage: make logs or make logs SERVICE=postgres)
	$(COMPOSE_PROD) logs -f --tail=100 $(or $(SERVICE),app)

rollback: ## Rollback to previous deployment
	chmod +x scripts/*.sh
	./scripts/deploy.sh rollback

restart: ## Restart all services
	$(COMPOSE_PROD) restart

restart-app: ## Restart app only (zero-downtime)
	$(COMPOSE_PROD) up -d --no-deps --build app

down: ## Stop all production services
	$(COMPOSE_PROD) down

# ---- Database ----
migrate: ## Run database migrations
	cd orionstack-backend--main && npm run migration:run

migrate-revert: ## Revert last database migration
	cd orionstack-backend--main && npm run migration:revert

migrate-prod: ## Run migrations inside production container
	docker exec promptgenie-app node -e "require('./dist/database/data-source').AppDataSource.runMigrations()"

# ---- Testing ----
test-backend: ## Run backend tests
	cd orionstack-backend--main && npm run test

test-frontend: ## Run Flutter tests
	cd thepg && flutter test

test: test-backend test-frontend ## Run all tests

# ---- Linting ----
lint-backend: ## Lint backend code
	cd orionstack-backend--main && npm run lint

lint-frontend: ## Analyze Flutter code
	cd thepg && flutter analyze

lint: lint-backend lint-frontend ## Lint everything

# ---- Clean ----
clean-backend: ## Clean backend build artifacts
	cd orionstack-backend--main && rm -rf dist node_modules coverage

clean-frontend: ## Clean Flutter build artifacts
	cd thepg && flutter clean

clean: clean-backend clean-frontend ## Clean everything

clean-docker: ## Remove all Docker containers, volumes, images
	$(COMPOSE_PROD) down -v --rmi local
