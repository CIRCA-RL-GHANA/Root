# Product Requirements Document — PROMPT Genie

**Version:** 1.0.0  
**Status:** Released  
**Platform:** Android · iOS · PWA  
**Target Markets:** Ghana, Nigeria

---

## Overview

PROMPT Genie is a multi-role super-app for West Africa. It provides individuals, businesses, and service providers with a unified platform for payments, ride-hailing, e-commerce, and social commerce under a single identity and loyalty system.

---

## Product Modules

### 1. GO — Digital Wallet

**Purpose:** P2P money transfers, bill payments, batch disbursements, and financial statements.

**Core Features:**
- Multi-currency wallet (GHS / NGN / USD)
- Instant P2P transfer via wireId (`WR-XXXXXX`)
- Batch payments (bulk disbursements to multiple recipients)
- Top-up via mobile money / card
- Transaction history with filtering and export
- Account statement (PDF / CSV)
- QPoints earnings on transactions
- AI financial insights (spending patterns, forecasts)
- Tax summary

**User Roles:** Individual user, Business admin, Staff member

---

### 2. Live — Ride-Hailing & Fulfilment

**Purpose:** On-demand ride booking and last-mile delivery coordination.

**Core Features:**

**Rider / Customer:**
- Request a ride (pickup + dropoff via map)
- Real-time driver tracking (GPS)
- 4-digit PIN verification before ride starts
- Multiple vehicle bands (Economy, Standard, Premium)
- Dynamic fare estimation (AI surge pricing 1× – 3.5×)
- Post-ride rating and behaviour tags
- Emergency SOS alert with location broadcast
- Ride history and receipts

**Driver:**
- Accept / decline ride requests
- Navigation to pickup / dropoff
- QPoints earnings per completed ride
- Earnings dashboard
- Vehicle assignment management
- SOS escalation

**Fulfilment / Delivery:**
- Accept delivery orders
- Order scanning and package tracking
- Live location sharing
- Delivery confirmation

---

### 3. Market — E-Commerce

**Purpose:** Social commerce marketplace for individual sellers and businesses.

**Core Features:**

**Buyer:**
- Browse products by category
- AI-powered semantic search
- Product detail with media gallery
- Cart and checkout (wallet, card, mobile money)
- Order tracking (confirmed → fulfilling → delivered)
- Return requests
- Product wishlisting
- AI product recommendations

**Seller / Business:**
- Product catalogue management (create, update, deactivate)
- Inventory and stock management
- Discount tier configuration
- Delivery zone setup
- Order management dashboard
- Fulfilment tracking
- Revenue and sales analytics
- AI-suggested discounts and pricing

---

### 4. QualChat — Messaging

**Purpose:** Secure real-time messaging between users, businesses, and support.

**Core Features:**
- 1-to-1 conversations
- Group chats
- Media sharing (images, documents)
- Message read receipts and typing indicators
- AI sentiment analysis of conversations
- AI intent detection
- Conversation summaries
- Push notifications (offline messages)

---

### 5. APRIL — Finance Calendar

**Purpose:** Personal and business financial planning and tracking.

**Core Features:**
- Expense and income calendar view
- Financial goals and savings targets
- Spending categories and budgets
- AI spending pattern analysis
- AI financial forecasts
- Account statement download
- Wishlist with AI scoring

---

### 6. Updates — Social Feed

**Purpose:** Social discovery and engagement between users, businesses, and creators.

**Core Features:**
- Scrollable social feed (posts, media)
- Follow / unfollow
- Reactions (Hey-Ya system)
- Comments and shares
- Business posts and promotions
- Trending content
- AI personalised feed ranking

---

### 7. Setup Dashboard — Business Onboarding

**Purpose:** Self-service wizard for businesses to onboard onto the platform.

**Core Features:**
- Business entity creation (34-screen guided flow)
- Branch management
- Staff invitation and role assignment
- Product catalogue import
- Delivery zone configuration
- Subscription plan selection
- KYC document upload
- Business profile customisation
- Banking / payout setup

---

### 8. User Details — Profile & Security

**Purpose:** User identity, security settings, and KYC verification.

**Core Features:**
- Profile photo and bio
- Privacy and visibility settings
- Interaction preferences (who can message you)
- Password change
- Biometric authentication toggle
- Active sessions management
- KYC verification (identity document upload)
- Privacy data export / deletion request
- Device and login history

---

## Identity & Loyalty

### User Identity
Every user has:
- **Phone number** (primary identifier)
- **Social username** (optional, human-readable handle)
- **wireId** (`WR-XXXXXX`) — unique transfer identifier for payments

### QPoints Loyalty Currency
- Earned on every completed transaction (rides, orders, payments)
- Transferable to other users
- Redeemable for discounts on platform services
- Leaderboard and tier system

---

## Subscription Tiers

| Tier | Features |
|---|---|
| Free | Basic wallet, limited marketplace, standard ride access |
| Premium | Reduced fees, priority matching, advanced analytics |
| VIP | Custom fees, dedicated support, all AI features unlocked |

---

## AI Features in Product

| Feature | Powered By | Where Used |
|---|---|---|
| Dynamic ride pricing | AIPricingService | Live module |
| Transaction fraud detection | AIFraudService | All payment flows |
| Product recommendations | AIRecommendationsService | Market module |
| Semantic product search | AISearchService | Market module |
| Financial insights | AIInsightsService | APRIL, GO modules |
| Spending pattern analysis | AIInsightsService | APRIL module |
| Message sentiment analysis | AINlpService | QualChat |
| Intent detection | AINlpService | QualChat, PROMPT |
| Conversation summaries | AINlpService | QualChat |
| Personalised feed | AIRecommendationsService | Updates module |
| AI insights strip | AIInsightsNotifier | All 180 screens |

---

## Platform Constraints

| Constraint | Value |
|---|---|
| File upload max size | 10 MB |
| OTP expiry | 5 minutes |
| Access token lifetime | 7 days |
| Refresh token lifetime | 30 days |
| Max surge multiplier | 3.5× base fare |
| Platform fee | 8% of ride fare (configurable) |
| API rate limit | 30 req/s (API), 5 req/s (auth) |

---

## Non-Functional Requirements

| Category | Requirement |
|---|---|
| Availability | 99.5% monthly uptime target |
| Response time | p95 API latency < 500ms |
| Security | OWASP Top 10 mitigations applied |
| Data residency | Data stored in chosen server region |
| Accessibility | Flutter `textScaleFactor` clamped 0.8–1.2 |
| Platform | Android 6.0+ (API 23), iOS 13+, Chrome/Firefox/Safari (PWA) |
| Offline | Core screens display cached data when offline (Hive) |
