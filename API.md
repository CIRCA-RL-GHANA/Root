# API Reference

**Base URL:** `https://api.genieinprompt.app/api/v1`  
**Authentication:** Bearer JWT — `Authorization: Bearer <access_token>`  
**Content-Type:** `application/json`  
**Interactive docs (dev only):** `http://localhost:3000/api/docs`

---

## Table of Contents

1. [Authentication](#authentication)
2. [Response Format](#response-format)
3. [Error Codes](#error-codes)
4. [Pagination](#pagination)
5. [Auth Module](#auth-module)
6. [Users Module](#users-module)
7. [Entities Module](#entities-module)
8. [Profiles Module](#profiles-module)
9. [QPoints Module](#qpoints-module)
10. [Wallets Module](#wallets-module)
11. [Payments Module](#payments-module)
12. [Products Module](#products-module)
13. [Orders Module](#orders-module)
14. [Rides Module](#rides-module)
15. [Vehicles Module](#vehicles-module)
16. [AI Module](#ai-module)
17. [Social Module](#social-module)
18. [GO Module](#go-module)
19. [Health Module](#health-module)
20. [WebSocket Gateway](#websocket-gateway)

---

## Authentication

All endpoints require a valid JWT access token unless marked `[PUBLIC]`.

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Token Lifecycle

| Token | Expiry | Purpose |
|---|---|---|
| Access Token | 7 days | Sent in `Authorization` header on every request |
| Refresh Token | 30 days | Used to obtain a new access token without re-login |

The API client auto-retries requests with a refreshed token when it receives `401 Unauthorized`.

---

## Response Format

### Success

```json
{
  "data": { ... },
  "statusCode": 200,
  "timestamp": "2024-01-15T09:30:00.000Z"
}
```

### List / Paginated

```json
{
  "data": [ ... ],
  "total": 150,
  "limit": 20,
  "offset": 0
}
```

### Error

```json
{
  "statusCode": 400,
  "timestamp": "2024-01-15T09:30:00.000Z",
  "path": "/api/v1/orders",
  "method": "POST",
  "error": "Bad Request",
  "message": ["amount must be a positive number"]
}
```

---

## Error Codes

| HTTP Status | Meaning |
|---|---|
| `200 OK` | Success |
| `201 Created` | Resource created |
| `204 No Content` | Success, no body (delete operations) |
| `400 Bad Request` | Validation failed — see `message` array |
| `401 Unauthorized` | Missing or invalid / expired token |
| `403 Forbidden` | Authenticated but insufficient permissions |
| `404 Not Found` | Resource does not exist |
| `409 Conflict` | Duplicate resource (e.g. phone already registered) |
| `429 Too Many Requests` | Rate limit exceeded |
| `500 Internal Server Error` | Server-side error |
| `503 Service Unavailable` | Service degraded or in maintenance |

---

## Pagination

Endpoints that return lists accept `limit` and `offset` query parameters.

```
GET /api/v1/orders/user/:userId?limit=20&offset=0
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `limit` | integer | 20 | Results per page (max 100) |
| `offset` | integer | 0 | Number of records to skip |
| `sort` | string | `-createdAt` | Field to sort by. Prefix with `-` for descending |

---

## Auth Module

### `POST /auth/login` [PUBLIC]

Authenticate with phone number and password.

**Request:**
```json
{
  "identifier": "+233241234567",
  "password": "MySecurePassword123!"
}
```

`identifier` may be a phone number or social username.

**Response `200`:**
```json
{
  "user": {
    "id": "uuid",
    "phoneNumber": "+233241234567",
    "socialUsername": "user123",
    "wireId": "WR-XXXXXX"
  },
  "tokens": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

---

### `POST /auth/refresh` [PUBLIC]

Exchange a refresh token for a new access token.

**Request:**
```json
{
  "refreshToken": "eyJ..."
}
```

**Response `200`:**
```json
{
  "tokens": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

---

### `GET /auth/me`

Returns the currently authenticated user.

**Response `200`:**
```json
{
  "id": "uuid",
  "phoneNumber": "+233241234567",
  "socialUsername": "user123",
  "wireId": "WR-XXXXXX",
  "otpVerified": true,
  "biometricVerified": false,
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

---

### `POST /auth/logout`

Invalidates the current session.

**Response `204` No Content**

---

## Users Module

### `GET /users/:id`

Fetch a user by ID.

**Response `200`:** User object.

---

### `PATCH /users/:id`

Partially update a user's profile data.

**Request:**
```json
{
  "socialUsername": "newusername"
}
```

---

## Entities Module

### `POST /entities/individual`

Create an individual entity for the authenticated user.

**Request:**
```json
{
  "name": "John Doe",
  "phone": "+233241234567",
  "email": "john@example.com"
}
```

---

### `POST /entities/other`

Create a business or organisation entity.

**Request:**
```json
{
  "type": "business",
  "name": "Acme Ltd",
  "phone": "+233241234567",
  "email": "info@acme.com"
}
```

---

### `POST /entities/branches`

Create a branch under a business entity.

**Request:**
```json
{
  "entityId": "uuid",
  "name": "Accra Main Branch",
  "location": "123 High Street, Accra",
  "operatingHours": "08:00-18:00"
}
```

---

### `GET /entities/:id`

Get entity details.

---

## Profiles Module

### `POST /profiles`

Create a profile for an entity.

**Request:**
```json
{
  "entityId": "uuid",
  "bio": "Short bio text",
  "avatarUrl": "https://..."
}
```

---

### `GET /profiles/:id`

Get profile by profile ID.

### `GET /profiles/user/:userId`

Get profile by user ID.

### `GET /profiles/entity/:entityId`

Get profile by entity ID.

### `PUT /profiles/:id`

Update profile metadata.

### `PUT /profiles/:id/visibility`

Update visibility settings.

**Request:**
```json
{
  "showOnlineStatus": true,
  "showActivity": false,
  "profileVisibility": "public"
}
```

### `PUT /profiles/:id/preferences`

Update interaction preferences.

**Request:**
```json
{
  "allowChatFrom": "followers",
  "notificationsEnabled": true
}
```

---

## QPoints Module

QPoints are the platform's loyalty currency.

### `POST /qpoints/transactions`

Record a QPoints transaction.

**Request:**
```json
{
  "userId": "uuid",
  "type": "earn",
  "amount": 500,
  "metadata": {
    "reason": "order_completed",
    "orderId": "uuid"
  }
}
```

`type`: `earn` | `spend` | `transfer` | `burn`

---

### `GET /qpoints/balance/:userId`

Get the current QPoints balance.

**Response `200`:**
```json
{
  "balance": 2500,
  "totalEarned": 5000,
  "totalSpent": 2500,
  "status": "active"
}
```

---

### `GET /qpoints/history/:userId`

Get transaction history (paginated).

**Query params:** `limit`, `offset`

---

### `POST /qpoints/transfer`

Transfer QPoints to another user.

**Request:**
```json
{
  "fromUserId": "uuid",
  "toWireId": "WR-XXXXXX",
  "amount": 100
}
```

**Fraud check:** Transfers are automatically scored by the AI fraud service. Transfers with a risk score ≥ 0.85 are auto-blocked.

---

## Wallets Module

### `GET /wallets/me`

Get the authenticated user's full wallet details.

**Response `200`:**
```json
{
  "id": "uuid",
  "currency": "GHS",
  "balance": 1500.00,
  "frozenBalance": 0.00,
  "type": "personal"
}
```

---

### `GET /wallets/balance`

Get current wallet balance only.

**Response `200`:**
```json
{
  "balance": 1500.00,
  "currency": "GHS"
}
```

---

## Payments Module

### `POST /payments`

Process a payment.

**Request:**
```json
{
  "amount": 250.00,
  "currency": "GHS",
  "method": "wallet",
  "recipientId": "uuid",
  "description": "Order payment"
}
```

`method`: `wallet` | `card` | `mobile_money`

**Response `201`:**
```json
{
  "id": "uuid",
  "status": "completed",
  "amount": 250.00,
  "currency": "GHS",
  "fraudStatus": "clean",
  "createdAt": "2024-01-15T09:30:00.000Z"
}
```

---

### `POST /payments/:id/refund`

Refund a completed payment.

**Request:**
```json
{
  "reason": "Customer requested refund"
}
```

---

### `GET /payments/history`

Get paginated payment history.

**Query params:** `limit`, `offset`

---

### `GET /payments/:id`

Get a specific payment by ID.

---

## Products Module

### `POST /products`

Create a product listing.

**Request:**
```json
{
  "sku": "PROD-001",
  "name": "Widget Pro",
  "description": "A great widget",
  "category": "electronics",
  "basePrice": 49.99,
  "cost": 20.00,
  "stock": 100,
  "branchId": "uuid"
}
```

---

### `GET /products`

List products with filtering.

**Query params:**

| Param | Type | Description |
|---|---|---|
| `branchId` | string | Filter by branch |
| `category` | string | Filter by category |
| `status` | string | `draft` \| `active` \| `discontinued` |
| `isFeatured` | boolean | Featured products only |
| `limit` | integer | Page size |
| `offset` | integer | Page offset |

---

### `GET /products/search`

Full-text product search (AI-enhanced).

**Query params:** `q` (search term), `limit`, `offset`

---

### `GET /products/:id`

Get product details.

### `PUT /products/:id`

Replace full product record.

### `PATCH /products/:id`

Partial product update.

### `DELETE /products/:id`

Delete a product.

---

### `POST /products/:id/media`

Upload product images or videos.

**Content-Type:** `multipart/form-data`  
**Max size:** 10 MB per file

### `GET /products/:id/media`

List all media for a product.

### `DELETE /products/media/:id`

Remove a media item.

---

### `POST /products/discount-tiers`

Create a volume discount tier.

**Request:**
```json
{
  "productId": "uuid",
  "minQuantity": 10,
  "discountPercent": 15
}
```

---

## Orders Module

### `POST /orders`

Create an order.

**Request:**
```json
{
  "sellerId": "uuid",
  "shippingAddress": "123 Main St, Accra",
  "items": [
    { "productId": "uuid", "quantity": 2 }
  ]
}
```

---

### `GET /orders/:id`

Get order details including items and status history.

### `GET /orders/user/:userId`

Get paginated order history for a user.

### `GET /orders/:id/items`

Get line items for an order.

---

### `PATCH /orders/:id/status`

Update order status.

**Request:**
```json
{
  "status": "confirmed"
}
```

`status`: `pending` | `confirmed` | `fulfilling` | `delivered` | `canceled` | `returned`

---

### `POST /orders/:id/fulfillment/start`

Start fulfilment session for an order.

### `POST /orders/fulfillment/:sessionId/complete`

Mark fulfilment session as complete.

---

### `POST /orders/:id/returns`

Create a return request.

**Request:**
```json
{
  "reason": "Damaged item received",
  "items": ["order-item-uuid"]
}
```

### `GET /orders/returns/:id`

Get return request status.

### `PUT /orders/returns/:id/status`

Update return request status (admin/seller action).

**Request:**
```json
{ "status": "approved" }
```

`status`: `pending` | `approved` | `rejected`

---

## Rides Module

### `POST /rides`

Request a new ride.

**Request:**
```json
{
  "riderId": "uuid",
  "pickupLocation": {
    "latitude": 5.6037,
    "longitude": -0.1870,
    "address": "Accra Mall, Accra"
  },
  "dropoffLocation": {
    "latitude": 5.5500,
    "longitude": -0.2167,
    "address": "University of Ghana, Legon"
  },
  "vehicleBandId": "uuid",
  "paymentMethod": "wallet"
}
```

**Response `201`:** Includes `estimatedFare`, `riderPin`, and assigned `driverPin` (once a driver accepts).

---

### `GET /rides/:id`

Get full ride details.

### `GET /rides/user/:userId`

Get ride history for a user (paginated).

---

### `PATCH /rides/:id/assign-driver`

Assign a driver to a requested ride.

**Request:**
```json
{
  "driverId": "uuid",
  "vehicleId": "uuid"
}
```

---

### `PATCH /rides/:id/status`

Update ride status.

**Request:**
```json
{ "status": "in_progress" }
```

`status`: `requested` | `accepted` | `driver_arrived` | `in_progress` | `completed` | `canceled`

---

### `POST /rides/:id/verify-rider-pin`

Verify the 4-digit rider PIN before starting a ride.

**Request:**
```json
{ "pin": "1234" }
```

### `POST /rides/:id/verify-driver-pin`

Verify the 4-digit driver PIN.

---

### `POST /rides/:id/feedback`

Submit post-ride rating and review.

**Request:**
```json
{
  "rating": 5,
  "comment": "Great driver, very smooth ride.",
  "behaviorTags": ["polite", "safe_driving", "clean"]
}
```

`behaviorTags`: `clean` | `polite` | `safe_driving` | `on_time` | `great_conversation`

---

### `POST /rides/:id/sos`

Trigger an SOS emergency alert.

**Request:**
```json
{
  "coordinates": {
    "latitude": 5.6037,
    "longitude": -0.1870
  },
  "message": "Driver is behaving erratically"
}
```

### `GET /rides/:id/sos`

Get SOS alerts for a ride.

---

## Vehicles Module

### `POST /vehicles`

Register a vehicle.

**Request:**
```json
{
  "plateNumber": "GR-1234-22",
  "make": "Toyota",
  "model": "Corolla",
  "year": 2020,
  "color": "White",
  "type": "sedan",
  "capacity": 4
}
```

### `GET /vehicles`

List vehicles (paginated). Query: `limit`, `offset`, `status`, `type`.

### `GET /vehicles/:id`

Get vehicle details.

### `GET /vehicles/plate/:plateNumber`

Look up a vehicle by plate number.

### `PUT /vehicles/:id`

Update vehicle information.

### `PATCH /vehicles/:id`

Partial vehicle update.

### `DELETE /vehicles/:id`

Remove a vehicle.

### `PATCH /vehicles/:id/status`

**Request:**
```json
{ "status": "maintenance" }
```

`status`: `active` | `maintenance` | `inactive`

---

### `POST /vehicles/bands`

Create a vehicle service band.

**Request:**
```json
{
  "name": "Premium",
  "description": "Luxury vehicles",
  "basePricePerKm": 5.00
}
```

### `GET /vehicles/bands`

List all vehicle bands.

### `PUT /vehicles/bands/:id`

Update a band.

### `DELETE /vehicles/bands/:id`

Delete a band.

---

### `POST /vehicles/assignments`

Assign a driver to a vehicle.

**Request:**
```json
{
  "driverId": "uuid",
  "vehicleId": "uuid",
  "startDate": "2024-01-15"
}
```

### `GET /vehicles/assignments`

List all assignments.

### `PUT /vehicles/assignments/:id`

Update an assignment.

### `PUT /vehicles/assignments/:id/end`

End an active assignment.

### `GET /vehicles/drivers/:driverId/active-assignment`

Get the current active vehicle assignment for a driver.

---

### `POST /vehicles/pricing`

Set pricing for a vehicle band.

**Request:**
```json
{
  "bandId": "uuid",
  "basePrice": 5.00,
  "pricePerKm": 2.50,
  "pricePerMinute": 0.35
}
```

### `GET /vehicles/pricing`

Get all pricing configurations.

### `PUT /vehicles/pricing/:id`

Update pricing.

### `POST /vehicles/pricing/calculate-wait-charge`

Calculate estimated wait charge.

**Request:**
```json
{
  "bandId": "uuid",
  "waitMinutes": 10
}
```

---

## AI Module

### `POST /ai/models`

Register a new AI model.

**Request:**
```json
{
  "name": "Fraud Detector v2",
  "modelType": "fraud",
  "version": "2.0.0",
  "config": { "threshold": 0.85 }
}
```

`modelType`: `nlp` | `pricing` | `fraud` | `recommendation`

### `GET /ai/models`

List active models. Query: `type` (modelType filter).

### `GET /ai/models/:id`

Get model details.

### `PUT /ai/models/:id/status`

**Request:**
```json
{ "status": "active" }
```

`status`: `training` | `active` | `deprecated`

### `PUT /ai/models/:id/metrics`

**Request:**
```json
{
  "accuracy": 0.94,
  "precision": 0.91,
  "recall": 0.88,
  "f1Score": 0.895
}
```

### `GET /ai/models/:id/stats`

Get model performance statistics.

---

### `POST /ai/inferences`

Run inference against an active model.

**Request:**
```json
{
  "modelId": "uuid",
  "inputData": {
    "userId": "uuid",
    "amount": 500,
    "method": "mobile_money"
  }
}
```

**Response `201`:**
```json
{
  "id": "uuid",
  "prediction": { "riskScore": 0.12, "riskLevel": "low" },
  "confidence": 0.94,
  "status": "completed",
  "latencyMs": 45
}
```

### `GET /ai/inferences/:id`

Get inference result.

### `GET /ai/inferences`

List inference history (paginated).

---

### `POST /ai/recommendations`

Get personalised recommendations.

**Request:**
```json
{
  "userId": "uuid",
  "type": "product",
  "context": { "category": "electronics" }
}
```

`type`: `product` | `ride` | `ride_type`

---

### `GET /ai/workflows/:id/status`

Check the status of an asynchronous AI workflow.

**Response `200`:**
```json
{
  "id": "uuid",
  "status": "completed",
  "result": { ... },
  "startedAt": "2024-01-15T09:30:00.000Z",
  "completedAt": "2024-01-15T09:30:05.000Z"
}
```

---

## Social Module

### Chat

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/social/chat/sessions` | Start a chat session |
| `GET` | `/social/chat/sessions/:id` | Get session details |
| `POST` | `/social/chat/sessions/:id/messages` | Send a message |
| `GET` | `/social/chat/sessions/:id/messages` | Get messages (paginated) |

### Posts & Feed

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/social/posts` | Create a post |
| `GET` | `/social/posts` | Get social feed (paginated) |
| `GET` | `/social/posts/:id` | Get post details |
| `POST` | `/social/posts/:id/reactions` | React to a post |
| `DELETE` | `/social/posts/:id` | Delete a post |

---

## GO Module

The GO module orchestrates wallets, payments, and QPoints.

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/go/dashboard` | GO wallet dashboard summary |
| `POST` | `/go/transfer` | P2P money transfer via wireId |
| `POST` | `/go/batch-payments` | Bulk transfers to multiple recipients |
| `POST` | `/go/top-up` | Add funds to GO wallet |
| `GET` | `/go/transactions` | Full transaction history (paginated) |
| `GET` | `/go/statement` | Downloadable account statement |

### Batch Payment

```json
{
  "recipients": [
    { "wireId": "WR-AAAAAA", "amount": 100.00 },
    { "wireId": "WR-BBBBBB", "amount": 250.00 }
  ],
  "description": "Monthly salary disbursement"
}
```

---

## Health Module

### `GET /health` [PUBLIC]

Full health check (database, memory, disk).

**Response `200`:**
```json
{
  "status": "ok",
  "info": {
    "database": { "status": "up" },
    "memory_heap": { "status": "up" },
    "storage": { "status": "up" }
  }
}
```

### `GET /health/live` [PUBLIC]

Liveness probe — is the process alive?

**Response `200`:** `{ "status": "ok" }`

### `GET /health/ready` [PUBLIC]

Readiness probe — is the app ready to serve traffic?

**Response `200`:** `{ "status": "ok" }`

---

## WebSocket Gateway

### Connection

**URL:** `wss://api.genieinprompt.app/socket.io/chat`  
**Namespace:** `/chat`  
**Transport:** WebSocket (with polling fallback)

**Authentication:** Pass JWT in the connection handshake:

```javascript
const socket = io('wss://api.genieinprompt.app/chat', {
  auth: { token: 'Bearer eyJ...' }
});
```

### Events

#### Client → Server

| Event | Payload | Description |
|---|---|---|
| `chat:message` | `{ recipientId, content, attachments? }` | Send a message |
| `chat:typing` | `{ recipientId, isTyping }` | Typing indicator |
| `chat:read` | `{ messageId }` | Mark message as read |

#### Server → Client

| Event | Payload | Description |
|---|---|---|
| `connection:confirmed` | `{ userId, socketId }` | Handshake confirmed |
| `chat:message` | Message object | Incoming message |
| `chat:typing` | `{ senderId, isTyping }` | Recipient is typing |
| `chat:read` | `{ messageId, readAt }` | Message read receipt |
| `presence:online` | `{ userId }` | User came online |
| `presence:offline` | `{ userId }` | User went offline |

### Message Object

```json
{
  "id": "uuid",
  "senderId": "uuid",
  "recipientId": "uuid",
  "content": "Hello!",
  "status": "delivered",
  "timestamp": "2024-01-15T09:30:00.000Z",
  "attachments": []
}
```

---

## Rate Limits

| Scope | Limit |
|---|---|
| All API routes | 30 requests/second per IP |
| Auth routes (`/auth/*`) | 5 requests/second per IP |
| Static assets | 100 requests/second per IP |
| Per-account throttle | 100 requests/60s (configurable) |

When exceeded, the API returns `HTTP 429 Too Many Requests`.
