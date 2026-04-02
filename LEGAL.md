# Legal & Compliance — PROMPT Genie

**Version:** 1.0 · **Effective Date:** April 2026

---

## Disclaimer

This document provides a framework for PROMPT Genie's legal and compliance obligations. All sections marked **[TO BE COMPLETED BY LEGAL COUNSEL]** must be reviewed and finalised by a qualified legal professional before the platform launches in each jurisdiction.

**PROMPT Genie** refers to the platform operated under this codebase and its associated services.

---

## 1. Terms of Service

**[TO BE COMPLETED BY LEGAL COUNSEL]**

Key areas to address:
- User eligibility (minimum age, jurisdiction)
- Acceptable use policy
- Account termination conditions
- Disputes and liability limitations
- Changes to terms

**Technical notes for legal drafting:**
- Users are identified by phone number and a system-generated wireId
- The platform supports individual and business accounts
- Real-money transactions occur via GO Wallet (GHS/NGN/USD)
- Ride-hailing services involve third-party driver contractors

---

## 2. Privacy Policy

**[TO BE COMPLETED BY LEGAL COUNSEL]**

### Data Collected by the Platform

| Category | Data Points |
|---|---|
| Identity | Phone number, full name, social username, wireId |
| Device | Device fingerprint, IP address |
| Location | Registration geolocation, real-time GPS during rides |
| Financial | Wallet balance, transaction history, payment methods |
| Communications | Chat messages, post content |
| Behavioural | App usage, feature interactions |

### Data Storage

- Primary data: PostgreSQL database (server location configurable)
- Session data: Redis (in-memory, volatile)
- Uploaded files: Local filesystem (`./uploads`) — recommend S3-equivalent in production
- Device data: Hive local storage on device (tokens, preferences)

### Data Retention

**[TO BE DEFINED]** — recommended defaults:
- User account data: retained for duration of account + regulatory hold period
- Transaction records: minimum 7 years (financial regulation requirement)
- Chat messages: configurable; default retained until user deletes
- Audit logs: 90 days rolling

### User Rights

The platform technically supports:
- **Data export:** Account statement download (GO module)
- **Data deletion:** Account deletion request (User Details → Privacy)
- **Correction:** Profile and data update at any time

**GDPR / NDPR compliance provisions must be implemented per jurisdiction.**

---

## 3. Payment & Financial Compliance

### Electronic Money

**[TO BE REVIEWED BY FINANCIAL COMPLIANCE COUNSEL]**

The GO Wallet stores and transfers monetary value. Operating as an e-money issuer may require:
- Bank of Ghana (BOG) Payment Systems Licence
- Central Bank of Nigeria (CBN) Payment Service Bank (PSB) Licence
- Or partnership with a licensed PSB/e-money issuer

### Anti-Money Laundering (AML)

The platform includes technical controls:
- AI fraud scoring on all transactions (`AIFraudService`)
- Auto-block at risk score ≥ 0.85
- Manual review queue at risk score ≥ 0.55
- Velocity checks (transaction frequency)
- Geographic velocity detection

**[TO BE COMPLETED]:** Formal AML policy, SAR reporting procedures, and MLCO designation.

### Know Your Customer (KYC)

The platform supports KYC document collection (User Details → Verification) but a formal identity verification workflow must be integrated with an approved KYC provider.

**KYC tiers must be defined**, including:
- Tier 0 (unverified): Phone only — limited transaction amounts
- Tier 1 (basic): Phone + ID document — increased limits
- Tier 2 (full): Phone + ID + address proof — maximum limits

---

## 4. Ride-Hailing Compliance

**[TO BE REVIEWED BY TRANSPORT REGULATORY COUNSEL]**

Ride-hailing services may be subject to:
- Rideshare / TNC licensing (National Road Traffic Authority, Ghana / VIO, Nigeria)
- Driver background check requirements
- Vehicle roadworthiness requirements
- Insurance requirements (third-party liability)

**Technical controls in place:**
- Driver-vehicle assignment management
- Vehicle registration and inspection date tracking
- 4-digit PIN verification before ride start
- SOS emergency alert system with GPS coordinates
- Post-ride rating and behaviour tagging system

---

## 5. Data Hosting & Sovereignty

**[TO BE DETERMINED]** — Select data centre location considering:
- Ghana Data Protection Act, 2012 (Act 843) — data about Ghanaian citizens
- Nigeria Data Protection Regulation (NDPR) 2019 — data about Nigerian citizens
- Cross-border transfer restrictions

---

## 6. Security Compliance

The platform implements technical security controls aligned with OWASP Top 10:

| Control | Implementation |
|---|---|
| Broken Access Control | Global `JwtAuthGuard`; route-level `@Public()` opt-out only |
| Cryptographic Failures | HTTPS (TLS 1.2+); bcrypt 12 rounds; AES-256 PIN encryption; JWT with separate secrets |
| Injection | TypeORM parameterised queries; class-validator whitelist on all DTOs |
| Insecure Design | Joi env validation at startup; non-root Docker user |
| Security Misconfiguration | Helmet middleware; no Swagger in production; env vars not logged |
| Authentication Failures | Bcrypt; OTP 2FA; biometric option; JWT expiry; refresh token rotation |
| Data Integrity | DB migrations only (no `synchronize`); soft-deletes; audit logs |
| Security Logging | Winston structured logs; `LoggingInterceptor` on all requests |
| SSRF | No server-side URL fetching from user input |

---

## 7. Intellectual Property

**[TO BE REVIEWED BY IP COUNSEL]**

- Platform name "PROMPT Genie" — trademark registration status to be confirmed
- All source code — proprietary, all rights reserved
- Third-party open-source licences — see `package.json` and `pubspec.yaml` for full dependency list; review licences for commercial use compliance (MIT, Apache 2.0, BSD are generally safe)
- User-generated content — terms of service must define licence grant

---

## 8. Third-Party Services

| Service | Purpose | Privacy Policy |
|---|---|---|
| Twilio | SMS OTP delivery | https://www.twilio.com/legal/privacy |
| SendGrid | Transactional email | https://www.twilio.com/legal/privacy |
| OpenAI (optional) | AI completions | https://openai.com/policies/privacy-policy |
| Let's Encrypt | TLS certificates | https://letsencrypt.org/privacy/ |

Data shared with each provider is limited to the minimum required for the service function.

---

## 9. Contact

For legal and compliance inquiries:  
**[TO BE COMPLETED]:** Legal department contact, DPO contact, registered business address.
