import Foundation

/// Exchanges a single-use authorization code, optionally proving possession of a PKCE verifier.
public struct ExchangeAuthCodeForAPIKeyRequest: Codable, Sendable, Equatable,
  CustomStringConvertible
{
  public var code: String
  public var codeVerifier: String?
  public var codeChallengeMethod: String?

  enum CodingKeys: String, CodingKey {
    case code
    case codeVerifier = "code_verifier"
    case codeChallengeMethod = "code_challenge_method"
  }

  public init(code: String, codeVerifier: String? = nil, codeChallengeMethod: String? = nil) {
    self.code = code
    self.codeVerifier = codeVerifier
    self.codeChallengeMethod = codeChallengeMethod
  }

  public var description: String {
    "ExchangeAuthCodeForAPIKeyRequest(code: [REDACTED], codeVerifier: [REDACTED])"
  }
}

/// The exchanged plaintext API key. Store `key` securely; do not log it.
public struct ExchangeAuthCodeForAPIKeyResponse: Codable, Sendable, Equatable,
  CustomStringConvertible
{
  public var key: String
  public var userID: String?

  enum CodingKeys: String, CodingKey {
    case key
    case userID = "user_id"
  }

  public init(key: String, userID: String? = nil) {
    self.key = key
    self.userID = userID
  }

  public var description: String { "ExchangeAuthCodeForAPIKeyResponse(key: [REDACTED])" }
}

/// Parameters for creating a short-lived, single-use authorization code with a management key.
public struct CreateAuthKeysCodeRequest: Codable, Sendable, Equatable {
  public var callbackURL: String
  public var codeChallenge: String?
  public var codeChallengeMethod: String?
  public var expiresAt: String?
  public var keyLabel: String?
  public var limit: Double?
  public var usageLimitType: String?
  public var workspaceID: UUID?

  enum CodingKeys: String, CodingKey {
    case callbackURL = "callback_url"
    case codeChallenge = "code_challenge"
    case codeChallengeMethod = "code_challenge_method"
    case expiresAt = "expires_at"
    case keyLabel = "key_label"
    case limit
    case usageLimitType = "usage_limit_type"
    case workspaceID = "workspace_id"
  }

  public init(
    callbackURL: String,
    codeChallenge: String? = nil,
    codeChallengeMethod: String? = nil,
    expiresAt: String? = nil,
    keyLabel: String? = nil,
    limit: Double? = nil,
    usageLimitType: String? = nil,
    workspaceID: UUID? = nil
  ) {
    self.callbackURL = callbackURL
    self.codeChallenge = codeChallenge
    self.codeChallengeMethod = codeChallengeMethod
    self.expiresAt = expiresAt
    self.keyLabel = keyLabel
    self.limit = limit
    self.usageLimitType = usageLimitType
    self.workspaceID = workspaceID
  }
}

/// A single-use authorization code response. The code expires after approximately 10 minutes.
public struct CreateAuthKeysCodeResponse: Codable, Sendable, Equatable, CustomStringConvertible {
  public var data: AuthKeysCode

  public init(data: AuthKeysCode) {
    self.data = data
  }

  /// Redacts the short-lived authorization credential to prevent accidental logging.
  public var description: String { "CreateAuthKeysCodeResponse(id: [REDACTED])" }
}

/// A short-lived, sensitive authorization credential. Do not log or persist its `id`.
public struct AuthKeysCode: Codable, Sendable, Equatable, CustomStringConvertible {
  public var id: String
  public var appID: Int
  public var createdAt: String

  enum CodingKeys: String, CodingKey {
    case id
    case appID = "app_id"
    case createdAt = "created_at"
  }

  public init(id: String, appID: Int, createdAt: String) {
    self.id = id
    self.appID = appID
    self.createdAt = createdAt
  }

  /// Redacts the authorization code identifier to prevent accidental logging.
  public var description: String { "AuthKeysCode(id: [REDACTED])" }
}

/// Metadata for the API key used to make the current request. This response never exposes key material.
public struct CurrentKeyResponse: Codable, Sendable, Equatable {
  public var data: CurrentKey

  public init(data: CurrentKey) {
    self.data = data
  }
}

/// A management API key's metadata. This type never contains plaintext key material.
public struct APIKeysResponse: Codable, Sendable, Equatable {
  public var data: [ManagedAPIKey]

  public init(data: [ManagedAPIKey]) {
    self.data = data
  }
}

/// Metadata for one management API key. This response never exposes plaintext key material.
public struct APIKeyResponse: Codable, Sendable, Equatable {
  public var data: ManagedAPIKey

  public init(data: ManagedAPIKey) {
    self.data = data
  }
}

/// Confirmation returned after permanently deleting a management API key.
public struct DeleteAPIKeyResponse: Codable, Sendable, Equatable {
  public var deleted: Bool

  public init(deleted: Bool) {
    self.deleted = deleted
  }
}

public struct CreateAPIKeyRequest: Codable, Sendable, Equatable {
  public var name: String
  public var creatorUserID: String?
  public var expiresAt: String?
  public var includeBYOKInLimit: Bool?
  public var limit: Double?
  public var limitReset: String?
  public var workspaceID: UUID?

  enum CodingKeys: String, CodingKey {
    case name, limit
    case creatorUserID = "creator_user_id"
    case expiresAt = "expires_at"
    case includeBYOKInLimit = "include_byok_in_limit"
    case limitReset = "limit_reset"
    case workspaceID = "workspace_id"
  }

  public init(
    name: String,
    creatorUserID: String? = nil,
    expiresAt: String? = nil,
    includeBYOKInLimit: Bool? = nil,
    limit: Double? = nil,
    limitReset: String? = nil,
    workspaceID: UUID? = nil
  ) {
    self.name = name
    self.creatorUserID = creatorUserID
    self.expiresAt = expiresAt
    self.includeBYOKInLimit = includeBYOKInLimit
    self.limit = limit
    self.limitReset = limitReset
    self.workspaceID = workspaceID
  }
}

/// A field update that can be left unchanged, assigned a value, or explicitly cleared.
public enum APIKeyPatchField<Value> {
  case unchanged
  case value(Value)
  case null
}

extension APIKeyPatchField: Sendable where Value: Sendable {}
extension APIKeyPatchField: Equatable where Value: Equatable {}

/// Changes to management API key metadata. Use `.null` to clear nullable limit fields.
public struct UpdateAPIKeyRequest: Encodable, Sendable, Equatable {
  public var name: String?
  public var disabled: Bool?
  public var includeBYOKInLimit: Bool?
  public var limit: APIKeyPatchField<Double>
  public var limitReset: APIKeyPatchField<String>

  enum CodingKeys: String, CodingKey {
    case name, disabled, limit
    case includeBYOKInLimit = "include_byok_in_limit"
    case limitReset = "limit_reset"
  }

  public init(
    name: String? = nil,
    disabled: Bool? = nil,
    includeBYOKInLimit: Bool? = nil,
    limit: APIKeyPatchField<Double> = .unchanged,
    limitReset: APIKeyPatchField<String> = .unchanged
  ) {
    self.name = name
    self.disabled = disabled
    self.includeBYOKInLimit = includeBYOKInLimit
    self.limit = limit
    self.limitReset = limitReset
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(name, forKey: .name)
    try container.encodeIfPresent(disabled, forKey: .disabled)
    try container.encodeIfPresent(includeBYOKInLimit, forKey: .includeBYOKInLimit)
    try encode(limit, forKey: .limit, in: &container)
    try encode(limitReset, forKey: .limitReset, in: &container)
  }

  private func encode<Value: Encodable>(
    _ field: APIKeyPatchField<Value>,
    forKey key: CodingKeys,
    in container: inout KeyedEncodingContainer<CodingKeys>
  ) throws {
    switch field {
    case .unchanged: break
    case .value(let value): try container.encode(value, forKey: key)
    case .null: try container.encodeNil(forKey: key)
    }
  }
}

/// A newly created API key and its metadata. The plaintext `key` is returned only once; handle and store it securely.
public struct CreateAPIKeyResponse: Codable, Sendable, Equatable, CustomStringConvertible {
  public var data: ManagedAPIKey
  public var key: String

  public init(data: ManagedAPIKey, key: String) {
    self.data = data
    self.key = key
  }

  /// Redacts the one-time plaintext key to prevent accidental logging.
  public var description: String { "CreateAPIKeyResponse(key: [REDACTED])" }
}

/// Management metadata for an API key. This type never contains plaintext key material.
public struct ManagedAPIKey: Codable, Sendable, Equatable {
  public var hash: String
  public var name: String
  public var label: String
  public var disabled: Bool
  public var limit: Double?
  public var limitRemaining: Double?
  public var limitReset: String?
  public var includeBYOKInLimit: Bool
  public var usage: Double
  public var usageDaily: Double
  public var usageWeekly: Double
  public var usageMonthly: Double
  public var byokUsage: Double
  public var byokUsageDaily: Double
  public var byokUsageWeekly: Double
  public var byokUsageMonthly: Double
  public var createdAt: String
  public var updatedAt: String?
  public var creatorUserID: String?
  public var workspaceID: String
  public var expiresAt: String?

  enum CodingKeys: String, CodingKey {
    case hash, name, label, disabled, limit, usage
    case limitRemaining = "limit_remaining"
    case limitReset = "limit_reset"
    case includeBYOKInLimit = "include_byok_in_limit"
    case usageDaily = "usage_daily"
    case usageWeekly = "usage_weekly"
    case usageMonthly = "usage_monthly"
    case byokUsage = "byok_usage"
    case byokUsageDaily = "byok_usage_daily"
    case byokUsageWeekly = "byok_usage_weekly"
    case byokUsageMonthly = "byok_usage_monthly"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case creatorUserID = "creator_user_id"
    case workspaceID = "workspace_id"
    case expiresAt = "expires_at"
  }

  public init(
    hash: String,
    name: String,
    label: String,
    disabled: Bool,
    limit: Double?,
    limitRemaining: Double?,
    limitReset: String?,
    includeBYOKInLimit: Bool,
    usage: Double,
    usageDaily: Double,
    usageWeekly: Double,
    usageMonthly: Double,
    byokUsage: Double,
    byokUsageDaily: Double,
    byokUsageWeekly: Double,
    byokUsageMonthly: Double,
    createdAt: String,
    updatedAt: String?,
    creatorUserID: String?,
    workspaceID: String,
    expiresAt: String?
  ) {
    self.hash = hash
    self.name = name
    self.label = label
    self.disabled = disabled
    self.limit = limit
    self.limitRemaining = limitRemaining
    self.limitReset = limitReset
    self.includeBYOKInLimit = includeBYOKInLimit
    self.usage = usage
    self.usageDaily = usageDaily
    self.usageWeekly = usageWeekly
    self.usageMonthly = usageMonthly
    self.byokUsage = byokUsage
    self.byokUsageDaily = byokUsageDaily
    self.byokUsageWeekly = byokUsageWeekly
    self.byokUsageMonthly = byokUsageMonthly
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.creatorUserID = creatorUserID
    self.workspaceID = workspaceID
    self.expiresAt = expiresAt
  }
}

/// Usage, limits, and lifecycle metadata for the current API key. This type never contains key material.
public struct CurrentKey: Codable, Sendable, Equatable {
  public var label: String
  public var limit: Double?
  public var limitRemaining: Double?
  public var limitReset: String?
  public var includeBYOKInLimit: Bool
  public var usage: Double
  public var usageDaily: Double
  public var usageWeekly: Double
  public var usageMonthly: Double
  public var byokUsage: Double
  public var byokUsageDaily: Double
  public var byokUsageWeekly: Double
  public var byokUsageMonthly: Double
  public var isFreeTier: Bool
  public var isManagementKey: Bool
  /// Deprecated provisioning indicator retained for wire compatibility; OpenRouter may remove it.
  public var isProvisioningKey: Bool?
  public var creatorUserID: String?
  public var expiresAt: String?
  /// Raw, tolerant `rate_limit` metadata. It can be the documented object or a legacy numeric value.
  public var rateLimit: JSONValue?

  enum CodingKeys: String, CodingKey {
    case label, limit, usage
    case limitRemaining = "limit_remaining"
    case limitReset = "limit_reset"
    case includeBYOKInLimit = "include_byok_in_limit"
    case usageDaily = "usage_daily"
    case usageWeekly = "usage_weekly"
    case usageMonthly = "usage_monthly"
    case byokUsage = "byok_usage"
    case byokUsageDaily = "byok_usage_daily"
    case byokUsageWeekly = "byok_usage_weekly"
    case byokUsageMonthly = "byok_usage_monthly"
    case isFreeTier = "is_free_tier"
    case isManagementKey = "is_management_key"
    case isProvisioningKey = "is_provisioning_key"
    case creatorUserID = "creator_user_id"
    case expiresAt = "expires_at"
    case rateLimit = "rate_limit"
  }

  public init(
    label: String,
    limit: Double?,
    limitRemaining: Double?,
    limitReset: String?,
    includeBYOKInLimit: Bool,
    usage: Double,
    usageDaily: Double,
    usageWeekly: Double,
    usageMonthly: Double,
    byokUsage: Double,
    byokUsageDaily: Double,
    byokUsageWeekly: Double,
    byokUsageMonthly: Double,
    isFreeTier: Bool,
    isManagementKey: Bool,
    creatorUserID: String?,
    expiresAt: String?,
    isProvisioningKey: Bool? = nil,
    rateLimit: JSONValue? = nil
  ) {
    self.label = label
    self.limit = limit
    self.limitRemaining = limitRemaining
    self.limitReset = limitReset
    self.includeBYOKInLimit = includeBYOKInLimit
    self.usage = usage
    self.usageDaily = usageDaily
    self.usageWeekly = usageWeekly
    self.usageMonthly = usageMonthly
    self.byokUsage = byokUsage
    self.byokUsageDaily = byokUsageDaily
    self.byokUsageWeekly = byokUsageWeekly
    self.byokUsageMonthly = byokUsageMonthly
    self.isFreeTier = isFreeTier
    self.isManagementKey = isManagementKey
    self.creatorUserID = creatorUserID
    self.expiresAt = expiresAt
    self.isProvisioningKey = isProvisioningKey
    self.rateLimit = rateLimit
  }
}
