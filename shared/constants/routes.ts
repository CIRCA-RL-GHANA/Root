/**
 * Shared route constants.
 * These define the API route contract between frontend and backend.
 *
 * Backend: Routes are implemented in @Controller decorators
 * Frontend: Routes are used in lib/core/constants/api_routes.dart
 */
export const API_ROUTES = {
  AUTH: {
    LOGIN: '/auth/login',
    LOGOUT: '/auth/logout',
    REFRESH: '/auth/refresh',
    ME: '/auth/me',
  },
  USERS: {
    REGISTER: '/users/register',
    VERIFY_OTP: '/users/verify-otp',
    VERIFY_BIOMETRIC: '/users/verify-biometric',
    SET_PIN: '/users/set-pin',
    ASSIGN_STAFF: '/users/staff/assign',
    CHECK_USERNAME: '/users/check-username/:username',
    CHECK_PHONE: '/users/check-phone',
    RESEND_OTP: '/users/resend-otp',
    BY_ID: '/users/:id',
  },
  PROFILES: {
    BASE: '/profiles',
    BY_USER: '/profiles/user/:userId',
    BY_ENTITY: '/profiles/entity/:entityId',
  },
  ENTITIES: {
    INDIVIDUAL: '/entities/individual',
    OTHER: '/entities/other',
    BRANCHES: '/entities/branches',
    BY_OWNER: '/entities/owner/:ownerId',
  },
  QPOINTS: {
    DEPOSIT: '/qpoints/transactions/deposit',
    TRANSFER: '/qpoints/transactions/transfer',
    WITHDRAW: '/qpoints/transactions/withdraw',
    TRANSACTIONS: '/qpoints/transactions',
  },
  PRODUCTS: {
    BASE: '/products',
    SEARCH: '/products/search',
    DISCOUNTS: '/products/discounts',
    DELIVERY_ZONES: '/products/delivery-zones',
  },
  ORDERS: {
    BASE: '/orders',
    RETURNS: '/orders/returns',
    PACKAGES: '/orders/packages',
  },
  VEHICLES: {
    BASE: '/vehicles',
    BANDS: '/vehicles/bands',
    ASSIGNMENTS: '/vehicles/assignments',
    PRICING: '/vehicles/pricing',
  },
  RIDES: {
    BASE: '/rides',
    FEEDBACK: '/rides/feedback',
    SOS: '/rides/sos',
    REFERRALS: '/rides/referrals',
  },
  SOCIAL: {
    HEYYA: '/social/heyya',
    CHAT_SESSIONS: '/social/chat/sessions',
    CHAT_MESSAGES: '/social/chat/messages',
    UPDATES: '/social/updates',
    COMMENTS: '/social/comments',
    ENGAGEMENTS: '/social/engagements',
  },
  CALENDAR: { BASE: '/calendar' },
  PLANNER: { TRANSACTIONS: '/planner/transactions', SUMMARY: '/planner/summary' },
  STATEMENT: { BASE: '/statement' },
  WISHLIST: { BASE: '/wishlist' },
  INTERESTS: {
    FAVORITE_SHOPS: '/interests/favorite-shops',
    INTERESTS: '/interests/interests',
    CONNECTION_REQUESTS: '/interests/connection-requests',
    CONNECTIONS: '/interests/connections/:userId',
  },
  PLACES: { BASE: '/places' },
  SUBSCRIPTIONS: { PLANS: '/subscriptions/plans', ACTIVATE: '/subscriptions/activate' },
  AI: {
    // Core
    MODELS:      '/ai/models',
    INFERENCES:  '/ai/inferences',
    // NLP
    NLP_SENTIMENT:  '/ai/nlp/sentiment',
    NLP_INTENT:     '/ai/nlp/intent',
    NLP_KEYWORDS:   '/ai/nlp/keywords',
    NLP_SUMMARISE:  '/ai/nlp/summarise',
    NLP_SIMILARITY: '/ai/nlp/similarity',
    NLP_SEARCH:     '/ai/nlp/search',
    // Pricing
    PRICING_RIDE:       '/ai/pricing/ride',
    PRICING_DISCOUNT:   '/ai/pricing/discount',
    PRICING_RETENTION:  '/ai/pricing/retention',
    // Fraud
    FRAUD_SCORE:    '/ai/fraud/score',
    FRAUD_LOCATION: '/ai/fraud/location',
    // Insights
    INSIGHTS_FINANCIALS:   '/ai/insights/financials',
    INSIGHTS_SPENDING:     '/ai/insights/spending-pattern',
    INSIGHTS_FORECAST:     '/ai/insights/forecast',
    INSIGHTS_COLLAB:       '/ai/insights/collaborative-filter',
  },
  PLANNER: {
    TRANSACTIONS: '/planner/transactions',
    SUMMARY:      '/planner/summary',
    AI_INSIGHTS:  '/planner/ai/insights',
    AI_SPENDING:  '/planner/ai/spending-pattern',
    AI_FORECAST:  '/planner/ai/forecast',
  },
  HEALTH: { CHECK: '/health', READY: '/health/ready', LIVE: '/health/live' },
} as const;
