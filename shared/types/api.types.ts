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
