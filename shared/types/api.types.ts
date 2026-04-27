/**
 * Shared TypeScript type definitions.
 * These define the API contract between the Flutter frontend and NestJS backend.
 *
 * The Flutter app uses Dart equivalents of these types (see lib/core/network/api_response.dart).
 * The NestJS backend implements these via DTOs and entity classes.
 */

// ─── Standard API Envelope ──────────────────────────

export interface ApiResponseEnvelope<T = any> {
  data: T;
  statusCode: number;
  timestamp: string;
  path: string;
}

export interface ApiErrorResponse {
  statusCode: number;
  timestamp: string;
  path: string;
  method: string;
  error: string;
  message: string | string[];
}

// ─── Pagination ─────────────────────────────────────

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

export interface PaginationQuery {
  page?: number;
  limit?: number;
}

// ─── Auth ───────────────────────────────────────────

export interface LoginRequest {
  identifier: string;
  password: string;
}

export interface LoginResponse {
  user: {
    id: string;
    phoneNumber: string;
    socialUsername: string;
    wireId: string;
    biometricVerified: boolean;
    otpVerified: boolean;
  };
  tokens: AuthTokens;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: string;
  tokenType: 'Bearer';
}

// ─── User ───────────────────────────────────────────

export interface User {
  id: string;
  phoneNumber: string;
  socialUsername: string;
  wireId: string;
  biometricVerified: boolean;
  otpVerified: boolean;
  deviceFingerprint?: string;
  ipAddress?: string;
  geolocation?: Record<string, any>;
  registrationTimestamp: string;
  createdAt: string;
  updatedAt: string;
}

export interface RegisterUserRequest {
  phoneNumber: string;
  socialUsername: string;
  wireId: string;
  password: string;
  firstName?: string;
  lastName?: string;
  email?: string;
  deviceFingerprint?: string;
}

export interface RegisterUserResponse {
  userId: string;
  message: string;
}

export interface VerifyOtpRequest {
  phoneNumber: string;
  code: string;
}

export interface CheckPhoneResponse {
  exists: boolean;
  phoneNumber: string;
}

export interface CheckUsernameResponse {
  available: boolean;
  username: string;
}

// ─── Staff ──────────────────────────────────────────

export type StaffRole =
  | 'owner'
  | 'administrator'
  | 'social_officer'
  | 'response_officer'
  | 'monitor'
  | 'branch_manager'
  | 'driver';

export interface AssignStaffRoleRequest {
  adminId: string;
  userId: string;
  entityId: string;
  role: StaffRole;
  pin: string;
  isBranch?: boolean;
  posId?: string;
  branchId?: string;
}

// ─── e-Play ─────────────────────────────────────────

export type DigitalAssetType = 'music' | 'movie' | 'podcast' | 'ebook' | 'show';
export type DigitalAssetStatus = 'draft' | 'published' | 'unlisted' | 'removed';
export type AccessModel = 'perpetual' | 'rental' | 'subscription';
export type LicenseStatus = 'active' | 'expired' | 'revoked';
export type CreatorTier = 'indie' | 'verified' | 'label';

export interface DigitalAsset {
  id: string;
  title: string;
  description: string | null;
  type: DigitalAssetType;
  status: DigitalAssetStatus;
  accessModel: AccessModel;
  creatorProfileId: string;
  priceQPoints: number;
  rentalDurationDays: number | null;
  coverUrl: string | null;
  encryptedStorageRef: string;
  durationSeconds: number | null;
  fileSizeBytes: number | null;
  tags: string | null;
  allowedRegions: string[] | null;
  platformRoyaltyPct: number;
  purchaseCount: number;
  playCount: number;
  createdAt: string;
}

export interface CreatorProfile {
  id: string;
  userId: string;
  displayName: string;
  bio: string | null;
  avatarUrl: string | null;
  bannerUrl: string | null;
  tier: CreatorTier;
  creatorRoyaltyPct: number;
  totalEarningsQPoints: number;
  assetCount: number;
  followerCount: number;
  isActive: boolean;
  createdAt: string;
}

export interface EplayLicense {
  id: string;
  userId: string;
  digitalAssetId: string;
  status: LicenseStatus;
  expiresAt: string | null;
  amountPaidQPoints: number;
  isPinned: boolean;
  lastAccessedAt: string | null;
  createdAt: string;
}

export interface StreamTokenResponse {
  streamToken: string;
  expiresAt: string;
}

// ─── Community ──────────────────────────────────────

export type CommunityType = 'library' | 'playlist' | 'theater' | 'fair' | 'hub' | 'hangout' | 'journal';
export type CommunityStatus = 'active' | 'archived' | 'suspended';
export type CommunityVisibility = 'public' | 'invite_only' | 'private';
export type MemberRole = 'owner' | 'admin' | 'moderator' | 'member';
export type MemberStatus = 'active' | 'banned' | 'pending';
export type PostType = 'text' | 'link' | 'poll' | 'event' | 'listing';

export interface Community {
  id: string;
  name: string;
  description: string | null;
  type: CommunityType;
  status: CommunityStatus;
  visibility: CommunityVisibility;
  ownerId: string;
  coverUrl: string | null;
  memberCount: number;
  postCount: number;
  metadata: Record<string, unknown> | null;
  tags: string | null;
  createdAt: string;
}

export interface CommunityMembership {
  id: string;
  communityId: string;
  userId: string;
  role: MemberRole;
  status: MemberStatus;
  banReason: string | null;
  inviteToken: string | null;
  createdAt: string;
}

export interface CommunityPost {
  id: string;
  communityId: string;
  authorId: string;
  type: PostType;
  title: string | null;
  body: string | null;
  linkedContentId: string | null;
  metadata: Record<string, unknown> | null;
  likeCount: number;
  commentCount: number;
  isPinned: boolean;
  isRemoved: boolean;
  createdAt: string;
}

// ─── Q Points Terms of Service ──────────────────────

/** GET /qpoints/tos — current ToS document */
export interface QPointsTosContent {
  version: string;
  effectiveDate: string;
  contentHash: string; // SHA-256 hex of the full text
  text: string;
}

/** GET /qpoints/tos/status */
export interface QPointsTosStatus {
  accepted: boolean;
  version: string;
  effectiveDate: string;
}

/** POST /qpoints/tos/accept — request body */
export interface AcceptQPointsTosRequest {
  tosVersion: string;
  readConfirmed: boolean;  // User read the full ToS
  riskConfirmed: boolean;  // User acknowledged Section 9 risk disclosures
  ageConfirmed: boolean;   // User confirmed 18+ years (Section 3.1)
  platform: 'web' | 'ios' | 'android';
}

/** POST /qpoints/tos/accept — response */
export interface AcceptQPointsTosResponse {
  success: boolean;
  tosVersion: string;
  acceptedAt: string;
  platform: string;
}

/** Audit record (admin view) */
export interface QPointsTosAcceptanceRecord {
  id: string;
  userId: string;
  tosVersion: string;
  ipAddress: string;
  userAgent: string;
  platform: string;
  readConfirmed: boolean;
  riskConfirmed: boolean;
  ageConfirmed: boolean;
  tosContentHash: string;
  acceptedAt: string;
}
