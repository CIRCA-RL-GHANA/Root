# Customer Journey Map — PROMPT Genie

Maps the end-to-end user experience for each primary persona across key touchpoints.

---

## Personas

| Persona | Description |
|---|---|
| **Individual User** | Urban professional using the app for payments, rides, and shopping |
| **Business Owner** | SME onboarding their shop/service onto the platform |
| **Driver** | Gig driver accepting ride requests |
| **Market Seller** | Seller listing products and managing orders |

---

## Journey 1: Individual User — First Use to First Transaction

| Stage | Touchpoint | User Action | System Action | Emotion |
|---|---|---|---|---|
| **Awareness** | App Store / Referral | Searches for or clicks referral link | — | Curious |
| **Download** | Play Store / App Store / PWA | Installs app | — | Hopeful |
| **Onboarding** | Splash screen | Opens app | Loads saved token → none found → routes to onboarding | Neutral |
| **Registration** | Phone entry screen | Enters phone number | Sends OTP via Twilio SMS | Expectant |
| **Verification** | OTP screen | Enters 6-digit code | Validates OTP, marks `otpVerified=true` | Relieved |
| **Setup** | Password, role, profile, biometrics, permissions | Completes 14-screen flow | Creates user, entity, profile in DB | Engaged |
| **Home** | PROMPT dashboard | Arrives at main hub | Loads AI insights, wallet, quick actions | Excited |
| **First top-up** | GO → Top Up | Tops up wallet | Processes via mobile money, credits wallet, awards QPoints | Satisfied |
| **First transfer** | GO → Transfer | Sends money to friend | Debits sender, credits receiver, notifications sent both ways | Delighted |
| **Retention** | Ongoing usage | Returns for rides, shopping, chat | Platform cross-sells between modules | Loyal |

---

## Journey 2: Business Owner — Onboarding to First Sale

| Stage | Touchpoint | User Action | System Action | Emotion |
|---|---|---|---|---|
| **Discovery** | Referral / social media | Hears about the platform | — | Curious |
| **Registration** | Same onboarding as individual | Creates account, selects "Business" role | Creates user + business entity | Hopeful |
| **Setup Dashboard** | 34-screen wizard | Completes business profile, adds branch, sets hours, uploads products, configures delivery zones | Saves entity, branch, products, zones to DB | Focused |
| **Subscription** | Setup → Plan selection | Selects subscription tier | Assigns subscription plan | Committed |
| **First listing** | Market → Products | Lists first product | Product saved as `draft`, activated when ready | Excited |
| **First order** | Market → Orders | Receives order notification | Order created in DB, fulfilment session starts | Thrilled |
| **Fulfilment** | Live → Active Orders | Processes and ships order | Delivery tracking activates, buyer notified | Busy |
| **Payment settled** | GO → Earnings | Views earnings dashboard | Platform fee deducted, remaining credited to wallet | Satisfied |
| **Repeat** | Ongoing | Manages catalogue, orders, staff | Platform analytics inform restocking decisions | Growing |

---

## Journey 3: Driver — Onboarding to First Completed Ride

| Stage | Touchpoint | User Action | System Action | Emotion |
|---|---|---|---|---|
| **Registration** | Same onboarding, selects "Driver" role | Creates account | Creates user, entity | Hopeful |
| **Vehicle setup** | Setup Dashboard → Vehicles | Adds vehicle (plate, make, model) | Creates vehicle record, uploads docs | Focused |
| **Assignment** | Setup → Vehicle Assignment | Active assignment created | VehicleAssignment record created | Ready |
| **Availability** | Live → Go Online | Sets status to available | Driver appears in matching pool | Expectant |
| **Ride request** | Live → Incoming request | Accepts request | Ride status → `accepted`; rider notified | Alert |
| **Pickup** | Live → Navigation | Drives to pickup | Tracking updates in real-time | Focused |
| **PIN verification** | Live → PIN prompt | Rider shares PIN | PIN verified; ride status → `in_progress` | Confirmed |
| **Dropoff** | Live → End ride | Completes ride | Fare calculated (AI dynamic pricing), deducted from rider, credited to driver minus platform fee | Satisfied |
| **Rating** | Live → Post-ride | Receives rating | Feedback stored, tags added to profile | Motivated |
| **Earnings** | GO Wallet | Views payout | QPoints awarded, earnings dashboard updated | Rewarded |

---

## Journey 4: Market Seller — Listing to Fulfilled Order

| Stage | Touchpoint | User Action | System Action | Emotion |
|---|---|---|---|---|
| **Listing** | Market → Products | Creates product listing with photos, price, stock | Product saved; AI-indexed for search | Productive |
| **Discoverability** | Buyer searches | — | AI semantic search matches product | — |
| **Order received** | Market → Notifications | Reviews new order | Order created in DB with `pending` status | Pleased |
| **Confirm order** | Market → Orders | Confirms order | Status → `confirmed`; buyer notified | Committed |
| **Fulfilment** | Live → Active Fulfilments | Packs and dispatches | Fulfilment session started, delivery tracking active | Busy |
| **Delivery** | Live → Delivery tracking | Driver picks up package | Status → `in_transit` | Trusting |
| **Completion** | Market → Completed | Buyer confirms receipt | Status → `delivered`; payment settled | Satisfied |
| **Returns** | Market → Returns | Handles return request if any | Return entity created; reviewed and approved/rejected | Professional |

---

## Pain Points & Mitigations

| Pain Point | Mitigation in Platform |
|---|---|
| Registration friction | OTP pre-fills, biometrics for return login |
| Trust for first payment | AI fraud scoring, secure PIN, transparent transaction history |
| Unreliable ride matching | Real-time driver location, driver rating system |
| Slow delivery updates | Live GPS tracking for every delivery |
| Product discoverability | AI semantic search + personalised recommendations |
| Surge pricing surprise | Fare estimate shown before ride confirmation |
| Forgetting to check app | Push notifications for all key events |
| Network outages | Hive local cache keeps core data available offline |

---

## Cross-Module User Flow

Users are encouraged to flow between modules through:

- **QPoints** — earned everywhere, redeemable everywhere
- **GO Wallet** — single payment method across rides, orders, transfers
- **Notifications** — surface opportunities in other modules ("Your GO wallet is low — top up before your next ride")
- **AI insights strip** — present on all 180 screens with contextual suggestions
