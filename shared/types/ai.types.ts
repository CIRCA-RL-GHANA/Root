/**
 * Shared AI TypeScript type definitions.
 * These define the AI sub-system API contract between the Flutter frontend
 * and NestJS backend AI services.
 *
 * Backend implementation : src/modules/ai/services/
 * Flutter equivalents    : lib/core/services/ai_service.dart
 */

// ─── NLP ─────────────────────────────────────────────────────────────────────

export interface SentimentResult {
  /** Raw AFINN score accumulated over all tokens. */
  score: number;
  /** Normalised score in the range [-1, 1]. */
  normalised: number;
  /** Human-readable label: 'positive' | 'neutral' | 'negative' */
  label: 'positive' | 'neutral' | 'negative';
  /** Number of tokens that contributed to the score. */
  tokens: number;
}

export interface IntentResult {
  /** Top-matched intent category, or 'unknown'. */
  intent: string;
  /**
   * Confidence in the range [0, 1].
   * Derived from token-overlap ratio with the intent keyword set.
   */
  confidence: number;
  /** Named entities extracted by compromise.js. */
  entities: {
    people:        string[];
    places:        string[];
    organisations: string[];
    topics:        string[];
    dates:         string[];
    values:        string[];
  };
}

export interface KeywordsResult {
  /** Stemmed + de-stopped keywords ordered by relevance. */
  keywords: string[];
}

export interface SummaryResult {
  summary: string;
}

export interface SimilarityResult {
  /** Cosine similarity in [0, 1] between the two input texts. */
  similarity: number;
}

export interface SearchResult {
  id:    string;
  score: number;
}

// ─── NLP request bodies ──────────────────────────────────────────────────────

export interface SentimentRequest    { text: string }
export interface IntentRequest       { text: string }
export interface KeywordsRequest     { text: string }
export interface SummariseRequest    { text: string }
export interface SimilarityRequest   { text1: string; text2: string }
export interface SearchRequest       { query: string; documents?: Array<{ id: string; text: string }> }

// ─── Dynamic Pricing ─────────────────────────────────────────────────────────

export interface RidePriceContext {
  baseFareNaira:   number;
  distanceKm:      number;
  perKmRate:        number;
  durationMinutes:  number;
  perMinuteRate:    number;
  /** Active ride requests in the zone. */
  demand:           number;
  /** Available drivers right now. */
  supply:           number;
  /** ISO 8601 timestamp used to apply peak-hour rules. */
  timestamp:        string;
}

export interface RidePriceBreakdown {
  baseFare:     number;
  distanceFare: number;
  timeFare:     number;
  surgeFee:     number;
  platformFee:  number;
}

export interface DynamicRidePrice {
  basePrice:         number;
  surgeMultiplier:   number;
  finalPrice:        number;
  breakdown:         RidePriceBreakdown;
  estimatedMinutes:  number;
  reason:            string;
}

export interface DiscountRecommendation {
  originalPrice:   number;
  discountPct:     number;
  discountedPrice: number;
  reason:          string;
}

export interface RetentionOffer {
  originalPrice:   number;
  discountPct:     number;
  offeredPrice:    number;
  offer:           string;
}

// ─── Pricing request bodies ───────────────────────────────────────────────────

export interface RidePriceRequest       extends RidePriceContext {}
export interface DiscountRequest        { price: number; daysSinceSale: number; views: number; conversionRate: number; stock: number }
export interface RetentionRequest       { months: number; loginDaysAgo: number; usageScore: number; price: number }

// ─── Fraud Detection ─────────────────────────────────────────────────────────

export type RiskLevel = 'low' | 'medium' | 'high' | 'critical';

export interface FraudSignal {
  signal:      string;
  weight:      number;
  triggered:   boolean;
  description: string;
}

export interface FraudCheckResult {
  riskScore:   number;
  riskLevel:   RiskLevel;
  signals:     FraudSignal[];
  blocked:     boolean;
  reviewFlag:  boolean;
}

export interface LocationAnomalyResult {
  distanceKm:  number;
  isAnomaly:   boolean;
  threshold:   number;
}

// ─── Fraud request bodies ─────────────────────────────────────────────────────

export interface FraudRequest {
  userId:              string;
  amount:              number;
  paymentMethod:       string;
  transactionsLastHour?: number;
  previousAmounts?:    number[];
  timestamp?:          string;
}

export interface LocationAnomalyRequest {
  knownLat:  number;
  knownLng:  number;
  txnLat:    number;
  txnLng:    number;
}

// ─── Financial Insights ───────────────────────────────────────────────────────

export type InsightType =
  | 'anomaly'
  | 'recommendation'
  | 'trend'
  | 'alert'
  | 'forecast';

export type InsightImpact = 'positive' | 'negative' | 'neutral';

export interface FinancialInsight {
  type:        InsightType;
  title:       string;
  description: string;
  impact:      InsightImpact;
  confidence:  number;
  data?:       Record<string, unknown>;
}

export interface CategorySpend {
  category:   string;
  total:      number;
  percentage: number;
}

export interface SpendingPattern {
  topCategories:    CategorySpend[];
  avgDailySpend:    number;
  avgWeeklySpend:   number;
  largestCategory:  string;
}

export interface RevenueForecaste {
  next7Days:    number;
  next30Days:   number;
  trend:        'up' | 'down' | 'stable';
  seasonality:  string;
}

export interface CollaborativeFilterResult {
  recommendations: Array<{ id: string; score: number }>;
}

// ─── Insights request bodies ──────────────────────────────────────────────────

export interface FinancialsRequest {
  income:   Array<{ amount: number; category?: string; date?: string }>;
  expenses: Array<{ amount: number; category?: string; date?: string }>;
}

export interface SpendingPatternRequest {
  transactions: Array<{
    amount:    number;
    category:  string;
    date:      string;
    type:      'credit' | 'debit';
  }>;
}

export interface ForecastRequest {
  dailySales: number[];
}

export interface CollaborativeFilterRequest {
  targetVector: number[];
  allVectors:   Array<{ id: string; vector: number[] }>;
  topN?:        number;
}

// ─── Unified AI module namespace (convenience re-export) ─────────────────────

export namespace AI {
  export type Sentiment          = SentimentResult;
  export type Intent             = IntentResult;
  export type DynamicPrice       = DynamicRidePrice;
  export type FraudCheck         = FraudCheckResult;
  export type Insight            = FinancialInsight;
  export type Spending           = SpendingPattern;
  export type Forecast           = RevenueForecaste;
  export type CollabFilter       = CollaborativeFilterResult;
  export type Discount           = DiscountRecommendation;
  export type Retention          = RetentionOffer;
  export type LocationAnomaly    = LocationAnomalyResult;
  export type SearchHit          = SearchHitResult;
  export type RankedCandidate    = RankedCandidateResult;
  export type SearchSuggestion   = SearchSuggestResult;
  export type Recommendation     = RecommendedItem;
  export type FeedItem           = PersonalizedFeedItem;
  export type WishlistScore      = WishlistConversionScore;
  export type PlanRecommendation = SubscriptionPlanRecommendation;
}

// ─── Search ───────────────────────────────────────────────────────────────────

/** A single ranked hit returned by AISearchService.search() / searchDocuments() */
export interface SearchHitResult {
  /** The document / entity id that was indexed. */
  id:    string;
  /** TF-IDF cosine similarity score in [0, 1]. */
  score: number;
}

/** A pre-fetched candidate re-ranked by cosine similarity. */
export interface RankedCandidateResult {
  id:         string;
  score:      number;
  /** Rank position (1-based) in the final ordered list. */
  rank:       number;
}

/** Autocomplete suggestion from AISearchService.suggestKeywords(). */
export interface SearchSuggestResult {
  keywords:  string[];
  entities:  IntentResult['entities'];
}

// ─── Search request bodies ────────────────────────────────────────────────────

export interface SearchDocumentsRequest {
  query:      string;
  documents:  Array<{ id: string; text: string }>;
  topN?:      number;
}

export interface RankCandidatesRequest {
  query:      string;
  /** Each candidate must have at minimum an `id` and a `text` field. */
  candidates: Array<{ id: string; text: string; [key: string]: unknown }>;
  topN?:      number;
}

export interface SearchSuggestRequest {
  query: string;
  topN?: number;
}

// ─── Recommendations ─────────────────────────────────────────────────────────

/** A single recommended item produced by AIRecommendationsService. */
export interface RecommendedItem {
  id:       string;
  /** Blended relevance score in [0, 1]. */
  score:    number;
  source:   'content-based' | 'collaborative' | 'blended' | 'cold-start';
}

/** A ranked item in a personalised feed. */
export interface PersonalizedFeedItem {
  id:       string;
  score:    number;
  /** Original content-item metadata passed in (echoed back). */
  metadata: Record<string, unknown>;
}

/** Wishlist conversion likelihood scored by AIRecommendationsService. */
export interface WishlistConversionScore {
  id:                string;
  conversionScore:   number;
  /** 0–1: ratio of budget already saved toward the item. */
  affordabilityRatio: number;
  /** Urgency derived from priority and item age. */
  urgency:           'low' | 'medium' | 'high';
}

/** Subscription plan recommendation from AIRecommendationsService. */
export interface SubscriptionPlanRecommendation {
  recommendedPlanId:   string;
  recommendedPlanName: string;
  action:              'upgrade' | 'downgrade' | 'keep';
  reason:              string;
  currentTier:         string;
  usageScore:          number;
}

// ─── Recommendations request bodies ──────────────────────────────────────────

export interface SimilarItemsRequest {
  /** Tags / description text of the reference item. */
  targetTags:     string;
  catalogueItems: Array<{ id: string; text: string }>;
  topN?:          number;
}

export interface ProductRecommendationsRequest {
  purchasedTexts:  string[];
  catalogueItems:  Array<{ id: string; text: string }>;
  topN?:           number;
}

export interface PersonalizedFeedRequest {
  /** Free-text user interest summary. */
  interestText:  string;
  contentItems:  Array<{ id: string; text: string; [key: string]: unknown }>;
  topN?:         number;
}

export interface BlendRecommendationsRequest {
  collaborative: Array<{ id: string; score: number }>;
  contentBased:  Array<{ id: string; score: number }>;
  topN?:         number;
}

export interface SubscriptionPlanRequest {
  usageScore:   number;
  currentTier:  string;
  plans:        Array<{ id: string; name: string; tier: number; price: number }>;
}

export interface WishlistScoreRequest {
  items: Array<{
    id:        string;
    priority:  number;
    addedAt:   string;
    price:     number;
    savedAmount: number;
  }>;
}
