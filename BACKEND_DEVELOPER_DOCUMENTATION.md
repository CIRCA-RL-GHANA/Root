# Backend Developer Documentation

NestJS 10 API for the PROMPT Genie platform.  
Stack: TypeScript · PostgreSQL 15 · Redis 7 · TypeORM 0.3 · Socket.io 4 · Bull queues · Winston

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Setup (Local Development)](#setup-local-development)
3. [Architecture Overview](#architecture-overview)
4. [Module Structure Pattern](#module-structure-pattern)
5. [Configuration Layer](#configuration-layer)
6. [Authentication & Guards](#authentication--guards)
7. [Database & Migrations](#database--migrations)
8. [AI Services](#ai-services)
9. [WebSocket Gateway](#websocket-gateway)
10. [Error Handling](#error-handling)
11. [Request Lifecycle](#request-lifecycle)
12. [Testing](#testing)
13. [Scripts Reference](#scripts-reference)
14. [Adding a New Module](#adding-a-new-module)

---

## Project Structure

```
orionstack-backend--main/
├── src/
│   ├── app.module.ts          # Root module — imports all 27 feature modules
│   ├── app.service.ts         # Root service (health metadata)
│   ├── main.ts                # Bootstrap: Helmet, CORS, Swagger, global pipes
│   │
│   ├── config/
│   │   ├── configuration.ts   # Env factory (maps process.env to typed config)
│   │   ├── typeorm.config.ts  # TypeORM async config factory
│   │   └── validation.schema.ts  # Joi schema — validates env vars at startup
│   │
│   ├── database/
│   │   ├── data-source.ts     # TypeORM DataSource (used by CLI migration commands)
│   │   ├── migrations/        # 25 ordered TypeORM migrations
│   │   └── seeds/             # Optional seed data
│   │
│   ├── gateway/
│   │   ├── chat.gateway.ts    # Socket.io WebSocket gateway
│   │   └── gateway.module.ts
│   │
│   ├── common/
│   │   ├── constants/         # App-wide constants
│   │   ├── dto/               # Shared DTOs
│   │   ├── entities/          # Shared base entities
│   │   ├── exceptions/        # Custom exceptions
│   │   ├── filters/
│   │   │   └── http-exception.filter.ts   # Global error handler
│   │   ├── interceptors/
│   │   │   ├── logging.interceptor.ts     # Request/response logging
│   │   │   └── transform.interceptor.ts   # Response envelope
│   │   └── services/
│   │
│   └── modules/
│       ├── ai/
│       ├── auth/
│       ├── calendar/
│       ├── entities/
│       ├── entity-profiles/
│       ├── favorite-drivers/
│       ├── files/
│       ├── go/
│       ├── health/
│       ├── interests/
│       ├── market-profiles/
│       ├── orders/
│       ├── payments/
│       ├── places/
│       ├── planner/
│       ├── products/
│       ├── profiles/
│       ├── qpoints/
│       ├── rides/
│       ├── social/
│       ├── statement/
│       ├── subscriptions/
│       ├── users/
│       ├── vehicles/
│       ├── wallets/
│       └── wishlist/
│
├── Dockerfile                 # Multi-stage production image
├── docker-compose.yml         # Dev stack (postgres, redis, app)
├── nest-cli.json
├── package.json
├── tsconfig.json
└── tsconfig.build.json
```

---

## Setup (Local Development)

### Prerequisites

- Node.js 18+ and npm 9+
- Docker and Docker Compose V2

### Steps

```bash
cd orionstack-backend--main

# 1. Install dependencies
npm install

# 2. Configure environment
cp .env.example .env
# Edit .env — fill in DB, Redis, JWT, Twilio, SendGrid values

# 3. Start Docker services (postgres + redis)
docker compose up -d

# 4. Run database migrations
npm run migration:run

# 5. Start development server (hot reload)
npm run start:dev
```

**API available at:** `http://localhost:3000`  
**Swagger UI:** `http://localhost:3000/api/docs`

### Available npm Scripts

| Script | Description |
|---|---|
| `npm run start:dev` | Development server with file-watching (ts-node) |
| `npm run start:debug` | Debug mode (attach debugger on port 9229) |
| `npm run build` | Compile TypeScript to `dist/` |
| `npm run start:prod` | Run compiled `dist/main.js` |
| `npm run migration:run` | Apply all pending migrations |
| `npm run migration:revert` | Revert the last applied migration |
| `npm run migration:generate` | Generate migration from entity changes |
| `npm run migration:status` | Show pending / applied migrations |
| `npm run lint` | ESLint with auto-fix |
| `npm run test` | Unit tests (Jest) |
| `npm run test:e2e` | End-to-end tests |
| `npm run test:cov` | Test coverage report |

---

## Architecture Overview

```
HTTP Request
     │
     ▼
Nginx (reverse proxy, TLS, rate limiting)
     │
     ▼
NestJS main.ts (port 3000)
  ├── Helmet middleware (security headers)
  ├── CORS middleware
  ├── Compression middleware
  ├── Global ValidationPipe (class-validator, whitelist=true)
  ├── Global JwtAuthGuard (honours @Public() decorator)
  ├── Global LoggingInterceptor (request/response timing)
  ├── Global TransformInterceptor (response envelope)
  └── Global HttpExceptionFilter (error normalisation)
     │
     ▼
Feature Module Controller
     │
     ▼
Feature Module Service (business logic)
  ├── TypeORM Repository (PostgreSQL)
  ├── Redis (Bull queues, caching)
  └── External services (Twilio, SendGrid, OpenAI)
```

### Key Patterns

- **Dependency Injection** — all services injected via NestJS IoC container
- **DTOs** — class-validator decorators on all incoming payloads; `whitelist: true` strips unknown fields
- **Entities** — TypeORM `@Entity()` classes define DB schema
- **Guards** — `JwtAuthGuard` is applied globally; use `@Public()` to opt out
- **Decorators** — `@CurrentUser()` injects the authenticated user into controllers
- **Bull Queues** — async / background jobs use Redis-backed Bull queues
- **Scheduled Tasks** — `@nestjs/schedule` cron decorators for periodic jobs

---

## Module Structure Pattern

Every feature module follows this structure:

```
modules/example/
├── example.module.ts          # NestJS module — imports, providers, exports
├── example.controller.ts      # Route handlers — thin, delegate to service
├── example.service.ts         # Business logic
├── entities/
│   └── example.entity.ts      # TypeORM entity
├── dto/
│   ├── create-example.dto.ts  # Validated input shape for POST
│   └── update-example.dto.ts  # Partial<CreateExampleDto>
└── interfaces/
    └── example.interface.ts   # TypeScript interfaces / types
```

### Example Controller

```typescript
@Controller('examples')
export class ExampleController {
  constructor(private readonly exampleService: ExampleService) {}

  @Post()
  create(@Body() dto: CreateExampleDto, @CurrentUser() user: JwtUser) {
    return this.exampleService.create(dto, user.sub);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.exampleService.findOne(id);
  }

  @Public()                   // opt out of JwtAuthGuard
  @Get('public-info')
  publicInfo() {
    return this.exampleService.getPublicInfo();
  }
}
```

### Example Service

```typescript
@Injectable()
export class ExampleService {
  constructor(
    @InjectRepository(Example)
    private readonly exampleRepo: Repository<Example>,
  ) {}

  async create(dto: CreateExampleDto, userId: string): Promise<Example> {
    const entity = this.exampleRepo.create({ ...dto, userId });
    return this.exampleRepo.save(entity);
  }

  async findOne(id: string): Promise<Example> {
    const entity = await this.exampleRepo.findOne({ where: { id } });
    if (!entity) throw new NotFoundException(`Example ${id} not found`);
    return entity;
  }
}
```

---

## Configuration Layer

### `src/config/configuration.ts`

Returns a typed config object from environment variables. Access anywhere via:

```typescript
constructor(private readonly config: ConfigService) {}

const jwtSecret = this.config.get<string>('jwt.secret');
const dbHost = this.config.get<string>('database.host');
const aiEnabled = this.config.get<boolean>('AI_ENABLED');
```

### `src/config/validation.schema.ts`

Joi schema validates all env vars at startup. The process exits immediately if required variables are missing or invalid. Add new variables here when extending the platform.

```typescript
export const validationSchema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'production', 'test').required(),
  PORT: Joi.number().default(3000),
  DB_HOST: Joi.string().required(),
  // ...
});
```

---

## Authentication & Guards

### JWT Flow

1. Client calls `POST /auth/login` with `identifier` + `password`
2. `AuthService.login()` validates user, verifies `otpVerified === true`
3. Generates access token (7d) and refresh token (30d) using `@nestjs/jwt`
4. Client stores tokens; attaches access token as `Authorization: Bearer <token>` on all requests
5. `JwtAuthGuard` (global) validates token signature via `JwtStrategy`
6. `JwtStrategy` extracts payload and injects into `@CurrentUser()`
7. On 401, client calls `POST /auth/refresh` → new access token

### JWT Payload

```typescript
interface JwtPayload {
  sub: string;           // User ID (UUID)
  phoneNumber: string;
  socialUsername: string;
  wireId: string;
  iat: number;
  exp: number;
}
```

### Decorators

```typescript
// Require auth (default — applied by global guard)
@Get('protected')
protectedRoute(@CurrentUser() user: JwtPayload) { ... }

// Opt out of auth guard for a specific route
@Public()
@Get('public')
publicRoute() { ... }
```

### Password & PIN Security

- **Passwords:** bcrypt with 12 rounds (`BCRYPT_ROUNDS` env var)
- **PINs:** AES-256 encrypted at rest using `PIN_ENCRYPTION_KEY`; decrypted server-side only for comparison
- **OTP:** 6-digit code, 5-minute expiry, sent via Twilio SMS

---

## Database & Migrations

### TypeORM Data Source

`src/database/data-source.ts` is used by the TypeORM CLI for migration commands.

```typescript
export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT ?? '5432'),
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: ['src/**/*.entity.ts'],
  migrations: ['src/database/migrations/*'],
  synchronize: false,  // Always false
});
```

### Migration Workflow

```bash
# Check pending migrations
npm run migration:status

# Apply all pending
npm run migration:run

# Generate new migration from entity changes
npm run migration:generate -- src/database/migrations/AddExampleColumn

# Revert last applied migration
npm run migration:revert
```

### Migration Order (25 total)

| Order | Name |
|---|---|
| 1 | InitialSchema |
| 2 | CreateUsersTable |
| 3 | CreateVehiclesTable |
| 4 | CreateOrdersTable |
| 5 | CreatePaymentsTable |
| 6 | CreateWalletsTable |
| 7 | CreateQPointsTable |
| 8 | CreateProductsTable |
| 9 | CreateSubscriptionsTable |
| 10 | CreateRidesTable |
| 11 | CreateSocialInteractionsTable |
| 12 | CreateIndexesAndConstraints |
| 13 | CreateQPointsMarketTables |
| 14 | CreateFacilitatorAccountsTable |
| 15 | AddUpdatedAtTriggers |
| 16 | CreateSubscriptionEntityTables |
| 17 | CreateProfileStaffAuthTables |
| 18 | CreateAITables |
| 19 | CreateSocialTables |
| 20 | CreateOrderDetailTables |
| 21 | CreateQPointsDetailTables |
| 22 | CreateVehicleDetailTables |
| 23 | CreateRideDetailTables |
| 24 | CreateProductDetailTables |
| 25 | CreateMiscTables |

### Database Conventions

- All primary keys are UUIDs generated by `uuid_generate_v4()`
- All tables use `createdAt`, `updatedAt`, `deletedAt` (soft-delete)
- Foreign keys use cascade delete where appropriate
- Composite indexes on `(userId, createdAt)`, `(status, createdAt)`, and `(entityId, branchId)`

---

## AI Services

The AI module (`src/modules/ai/`) provides six services, backed by local npm packages (`natural`, `compromise`, `@tensorflow/tfjs-node`) — no external API required for core functionality:

### AINlpService

Natural language processing using `natural` and `compromise` npm packages (no external API required).

```typescript
// Intent recognition
const result = await nlpService.analyzeIntentFromText('I want to book a ride');
// { intent: 'book_ride', confidence: 0.92 }

// Sentiment analysis
const sentiment = await nlpService.analyzeSentiment('The service was great!');
// { score: 0.85, label: 'positive' }

// Entity extraction
const entities = await nlpService.extractEntities('Send 100 GHS to John');
// [{ type: 'amount', value: '100 GHS' }, { type: 'person', value: 'John' }]
```

### AIPricingService

Dynamic ride fare calculation.

```typescript
// Surge multiplier (1.0 – 3.5×)
const surge = pricingService.computeSurgeMultiplier(demandFactor, supplyFactor);

// Full price breakdown
const price = await pricingService.computeDynamicPrice({
  distanceKm: 8.5,
  bandId: 'uuid',
  rideRequestedAt: new Date(),
});
// { baseFare: 26.25, platformFee: 2.10, surgeMultiplier: 1.2, totalFare: 33.42 }
```

**Pricing formula:**

```
baseFare = 5.00 + (distanceKm × 2.50) + (estimatedMinutes × 0.35)
platformFee = baseFare × 0.08
totalFare = (baseFare + platformFee) × surgeMultiplier
```

Peak hours (UTC): 7–9am, 5–8pm. Late night (11pm–4am): +20% surge floor. Weekends: higher base demand factor.

### AIFraudService

Transaction risk scoring.

```typescript
const result = await fraudService.checkTransaction({
  userId: 'uuid',
  amount: 5000,
  method: 'mobile_money',
  timestamp: new Date(),
});
// {
//   riskScore: 0.23,
//   riskLevel: 'low',
//   blocked: false,
//   reviewFlag: false,
//   signals: [],
//   reason: 'Transaction appears normal'
// }
```

**Thresholds:**
- `riskScore ≥ 0.85` → `blocked: true` (auto-decline)
- `0.55 ≤ riskScore < 0.85` → `reviewFlag: true` (manual review queue)
- High-risk methods: `virtual_card`, `prepaid`, `gift_card`

### AIRecommendationsService

Collaborative filtering for products and ride types.

```typescript
const recs = await recommendationsService.getProductRecommendations(userId);
// [{ productId, score, reason }]
```

### AISearchService

Hybrid product search (vector + keyword).

```typescript
const results = await searchService.searchProducts('wireless headphones', { limit: 10 });
```

### AIInsightsService

Financial and behavioural analytics.

```typescript
const insights = await insightsService.getSpendingInsights(userId);
// [{ label, value, trend, period }]
```

---

## WebSocket Gateway

### `src/gateway/chat.gateway.ts`

```typescript
@WebSocketGateway({ namespace: '/chat', cors: { origin: '*' } })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {

  @WebSocketServer()
  server: Server;

  private connectedUsers = new Map<string, Set<string>>(); // userId → Set<socketId>

  async handleConnection(client: Socket) {
    // Validate JWT from client.handshake.auth.token
    // Add socket to user's room: `user:${userId}`
    // Emit connection:confirmed
  }

  handleDisconnect(client: Socket) {
    // Remove from connectedUsers map
    // Broadcast presence:offline if no remaining sockets
  }

  @SubscribeMessage('chat:message')
  async handleMessage(client: Socket, payload: ChatMessagePayload) {
    // Persist message to DB
    // Emit to recipient's room: `user:${recipientId}`
    // Emit delivery confirmation to sender
  }

  @SubscribeMessage('chat:typing')
  handleTyping(client: Socket, payload: TypingPayload) {
    client.to(`user:${payload.recipientId}`).emit('chat:typing', {
      senderId: client.data.userId,
      isTyping: payload.isTyping,
    });
  }
}
```

### Client Connection (Flutter / JavaScript)

```dart
// Flutter (socket_io_client)
final socket = io('wss://api.promptgenie.app/chat', OptionBuilder()
  .setTransports(['websocket'])
  .setAuth({'token': 'Bearer $accessToken'})
  .build());

socket.on('connection:confirmed', (data) => print('Connected: $data'));
socket.on('chat:message', (msg) => handleIncoming(msg));
socket.emit('chat:message', { 'recipientId': id, 'content': 'Hello' });
```

---

## Error Handling

### `HttpExceptionFilter` (global)

All unhandled exceptions are caught and formatted:

```json
{
  "statusCode": 404,
  "timestamp": "2024-01-15T09:30:00.000Z",
  "path": "/api/v1/rides/invalid-id",
  "method": "GET",
  "error": "Not Found",
  "message": "Ride invalid-id not found"
}
```

### Custom Exceptions

```typescript
// In services — use standard NestJS exceptions
throw new NotFoundException(`User ${id} not found`);
throw new BadRequestException('OTP has expired');
throw new UnauthorizedException('Invalid credentials');
throw new ConflictException('Phone number already registered');
throw new ForbiddenException('Insufficient permissions');
```

### Validation Errors (400)

`ValidationPipe` with `whitelist: true` and `forbidNonWhitelisted: true`:
- Strips unknown properties automatically
- Returns detailed field-level error messages
- Uses `transform: true` to coerce types (string → number, etc.)

---

## Request Lifecycle

```
1. Nginx (TLS, rate limit, gzip)
2. Express middleware (Helmet, CORS, compression, body-parser)
3. NestJS routing → Controller
4. Guards: JwtAuthGuard → validates Bearer token
5. Interceptors (before): LoggingInterceptor
6. Pipes: ValidationPipe → validates and transforms DTO
7. Controller method
8. Service method → Repository (TypeORM) → PostgreSQL
9. Interceptors (after): TransformInterceptor → wraps response
10. Response sent to client
```

---

## Testing

### Unit Tests

```bash
npm run test                    # Run all unit tests
npm run test -- --watch         # Watch mode
npm run test -- --testPathPattern=auth   # Run specific test file
npm run test:cov                # Coverage report
```

Tests live alongside source files: `*.spec.ts`

### E2E Tests

```bash
npm run test:e2e
```

E2E tests are in the `test/` directory and use a test database.

### Test Environment

Use `NODE_ENV=test`. The test configuration points to a separate test database and disables external service calls (Twilio, SendGrid).

---

## Scripts Reference

Located in `scripts/`:

| Script | Purpose |
|---|---|
| `generate-modules.sh` | Scaffolds a new NestJS module with standard file structure |
| `setup-ssl.sh` | Provisions Let's Encrypt SSL certificate |
| `setup-env.sh` | Interactive env file setup |
| `validate-env.sh` | Validates all required env vars are set |
| `deploy.sh` | Production deployment script |

---

## Adding a New Module

### 1. Scaffold

```bash
# Generate boilerplate
nest generate module modules/my-feature
nest generate controller modules/my-feature
nest generate service modules/my-feature
```

Or use the project script:

```bash
./scripts/generate-modules.sh my-feature
```

### 2. Create Entity

```typescript
// src/modules/my-feature/entities/my-feature.entity.ts
@Entity('my_features')
export class MyFeature extends BaseEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ name: 'user_id' })
  userId: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @DeleteDateColumn()
  deletedAt?: Date;
}
```

### 3. Generate Migration

```bash
npm run migration:generate -- src/database/migrations/CreateMyFeaturesTable
```

### 4. Register in App Module

```typescript
// src/app.module.ts
import { MyFeatureModule } from './modules/my-feature/my-feature.module';

@Module({
  imports: [
    // ...existing modules
    MyFeatureModule,
  ],
})
export class AppModule {}
```

### 5. Write Tests

Create `my-feature.service.spec.ts` with unit tests before implementing business logic.
