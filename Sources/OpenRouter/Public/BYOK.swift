/// A nullable BYOK update: omit, assign, or explicitly clear a setting.
public enum BYOKField<Value> {
  case unchanged
  case value(Value)
  case null
}
extension BYOKField: Sendable where Value: Sendable {}
extension BYOKField: Equatable where Value: Equatable {}

public struct BYOKKey: Codable, Sendable, Equatable {
  public var allowedAPIKeyHashes: [String]?
  public var allowedModels: [String]?
  public var allowedUserIDs: [String]?
  public var createdAt: String
  public var declaredRegion: String?
  public var declaredZDR: Bool?
  public var disabled: Bool
  public var id: String
  public var isBYOKOnly: Bool
  public var isFallback: Bool
  public var isRequired: Bool
  public var label: String
  public var name: String?
  public var provider: String
  public var sortOrder: Int
  public var workspaceID: String?
  public init(
    allowedAPIKeyHashes: [String]? = nil, allowedModels: [String]? = nil,
    allowedUserIDs: [String]? = nil, createdAt: String, declaredRegion: String? = nil,
    declaredZDR: Bool? = nil, disabled: Bool, id: String, isBYOKOnly: Bool, isFallback: Bool,
    isRequired: Bool, label: String, name: String? = nil, provider: String, sortOrder: Int,
    workspaceID: String? = nil
  ) {
    self.allowedAPIKeyHashes = allowedAPIKeyHashes
    self.allowedModels = allowedModels
    self.allowedUserIDs = allowedUserIDs
    self.createdAt = createdAt
    self.declaredRegion = declaredRegion
    self.declaredZDR = declaredZDR
    self.disabled = disabled
    self.id = id
    self.isBYOKOnly = isBYOKOnly
    self.isFallback = isFallback
    self.isRequired = isRequired
    self.label = label
    self.name = name
    self.provider = provider
    self.sortOrder = sortOrder
    self.workspaceID = workspaceID
  }
  enum CodingKeys: String, CodingKey {
    case allowedAPIKeyHashes = "allowed_api_key_hashes"
    case allowedModels = "allowed_models"
    case allowedUserIDs = "allowed_user_ids"
    case createdAt = "created_at"
    case declaredRegion = "declared_region"
    case declaredZDR = "declared_zdr"
    case disabled
    case id
    case isBYOKOnly = "is_byok_only"
    case isFallback = "is_fallback"
    case isRequired = "is_required"
    case label
    case name
    case provider
    case sortOrder = "sort_order"
    case workspaceID = "workspace_id"
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(allowedAPIKeyHashes, forKey: .allowedAPIKeyHashes)
    try c.encode(allowedModels, forKey: .allowedModels)
    try c.encode(allowedUserIDs, forKey: .allowedUserIDs)
    try c.encode(createdAt, forKey: .createdAt)
    try c.encode(declaredRegion, forKey: .declaredRegion)
    try c.encode(declaredZDR, forKey: .declaredZDR)
    try c.encode(disabled, forKey: .disabled)
    try c.encode(id, forKey: .id)
    try c.encode(isBYOKOnly, forKey: .isBYOKOnly)
    try c.encode(isFallback, forKey: .isFallback)
    try c.encode(isRequired, forKey: .isRequired)
    try c.encode(label, forKey: .label)
    try c.encodeIfPresent(name, forKey: .name)
    try c.encode(provider, forKey: .provider)
    try c.encode(sortOrder, forKey: .sortOrder)
    try c.encode(workspaceID, forKey: .workspaceID)
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    guard c.contains(.allowedAPIKeyHashes) else {
      throw DecodingError.keyNotFound(
        CodingKeys.allowedAPIKeyHashes,
        .init(codingPath: c.codingPath, debugDescription: "Missing required BYOK field"))
    }
    allowedAPIKeyHashes = try c.decodeIfPresent([String].self, forKey: .allowedAPIKeyHashes)
    guard c.contains(.allowedModels) else {
      throw DecodingError.keyNotFound(
        CodingKeys.allowedModels,
        .init(codingPath: c.codingPath, debugDescription: "Missing required BYOK field"))
    }
    allowedModels = try c.decodeIfPresent([String].self, forKey: .allowedModels)
    guard c.contains(.allowedUserIDs) else {
      throw DecodingError.keyNotFound(
        CodingKeys.allowedUserIDs,
        .init(codingPath: c.codingPath, debugDescription: "Missing required BYOK field"))
    }
    allowedUserIDs = try c.decodeIfPresent([String].self, forKey: .allowedUserIDs)
    createdAt = try c.decode(String.self, forKey: .createdAt)
    guard c.contains(.declaredRegion) else {
      throw DecodingError.keyNotFound(
        CodingKeys.declaredRegion,
        .init(codingPath: c.codingPath, debugDescription: "Missing required BYOK field"))
    }
    declaredRegion = try c.decodeIfPresent(String.self, forKey: .declaredRegion)
    guard c.contains(.declaredZDR) else {
      throw DecodingError.keyNotFound(
        CodingKeys.declaredZDR,
        .init(codingPath: c.codingPath, debugDescription: "Missing required BYOK field"))
    }
    declaredZDR = try c.decodeIfPresent(Bool.self, forKey: .declaredZDR)
    disabled = try c.decode(Bool.self, forKey: .disabled)
    id = try c.decode(String.self, forKey: .id)
    isBYOKOnly = try c.decode(Bool.self, forKey: .isBYOKOnly)
    isFallback = try c.decode(Bool.self, forKey: .isFallback)
    isRequired = try c.decode(Bool.self, forKey: .isRequired)
    label = try c.decode(String.self, forKey: .label)
    name = try c.decodeIfPresent(String.self, forKey: .name)
    provider = try c.decode(String.self, forKey: .provider)
    sortOrder = try c.decode(Int.self, forKey: .sortOrder)
    guard c.contains(.workspaceID) else {
      throw DecodingError.keyNotFound(
        CodingKeys.workspaceID,
        .init(codingPath: c.codingPath, debugDescription: "Missing required BYOK field"))
    }
    workspaceID = try c.decodeIfPresent(String.self, forKey: .workspaceID)
  }
}

public struct CreateBYOKKeyRequest: Encodable, Sendable, Equatable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  public var allowedAPIKeyHashes: [String]?
  public var allowedModels: [String]?
  public var allowedUserIDs: [String]?
  public var declaredRegion: String?
  public var declaredZDR: Bool?
  public var disabled: Bool?
  public var isBYOKOnly: Bool?
  public var isFallback: Bool?
  public var isRequired: Bool?
  public var key: String
  public var name: String?
  public var provider: String
  public var workspaceID: String?
  public init(
    provider: String, key: String,
    allowedAPIKeyHashes: [String]? = nil, allowedModels: [String]? = nil,
    allowedUserIDs: [String]? = nil, declaredRegion: String? = nil, declaredZDR: Bool? = nil,
    disabled: Bool? = nil, isBYOKOnly: Bool? = nil, isFallback: Bool? = nil,
    isRequired: Bool? = nil, name: String? = nil,
    workspaceID: String? = nil
  ) {
    self.allowedAPIKeyHashes = allowedAPIKeyHashes
    self.allowedModels = allowedModels
    self.allowedUserIDs = allowedUserIDs
    self.declaredRegion = declaredRegion
    self.declaredZDR = declaredZDR
    self.disabled = disabled
    self.isBYOKOnly = isBYOKOnly
    self.isFallback = isFallback
    self.isRequired = isRequired
    self.key = key
    self.name = name
    self.provider = provider
    self.workspaceID = workspaceID
  }
  enum CodingKeys: String, CodingKey {
    case allowedAPIKeyHashes = "allowed_api_key_hashes"
    case allowedModels = "allowed_models"
    case allowedUserIDs = "allowed_user_ids"
    case declaredRegion = "declared_region"
    case declaredZDR = "declared_zdr"
    case disabled
    case isBYOKOnly = "is_byok_only"
    case isFallback = "is_fallback"
    case isRequired = "is_required"
    case key
    case name
    case provider
    case workspaceID = "workspace_id"
  }
  public var description: String { "CreateBYOKKeyRequest(key: [REDACTED])" }
  public var debugDescription: String { description }
  public var customMirror: Mirror { Mirror(self, children: ["key": "[REDACTED]"]) }
}

public struct UpdateBYOKKeyRequest: Encodable, Sendable, Equatable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  public var allowedAPIKeyHashes: BYOKField<[String]>
  public var allowedModels: BYOKField<[String]>
  public var allowedUserIDs: BYOKField<[String]>
  public var declaredRegion: BYOKField<String>
  public var declaredZDR: BYOKField<Bool>
  public var disabled: Bool?
  public var isBYOKOnly: Bool?
  public var isFallback: Bool?
  public var isRequired: Bool?
  public var key: String?
  public var name: BYOKField<String>
  public init(
    allowedAPIKeyHashes: BYOKField<[String]> = .unchanged,
    allowedModels: BYOKField<[String]> = .unchanged,
    allowedUserIDs: BYOKField<[String]> = .unchanged,
    declaredRegion: BYOKField<String> = .unchanged, declaredZDR: BYOKField<Bool> = .unchanged,
    disabled: Bool? = nil, isBYOKOnly: Bool? = nil, isFallback: Bool? = nil,
    isRequired: Bool? = nil, key: String? = nil, name: BYOKField<String> = .unchanged
  ) {
    self.allowedAPIKeyHashes = allowedAPIKeyHashes
    self.allowedModels = allowedModels
    self.allowedUserIDs = allowedUserIDs
    self.declaredRegion = declaredRegion
    self.declaredZDR = declaredZDR
    self.disabled = disabled
    self.isBYOKOnly = isBYOKOnly
    self.isFallback = isFallback
    self.isRequired = isRequired
    self.key = key
    self.name = name
  }
  enum CodingKeys: String, CodingKey {
    case allowedAPIKeyHashes = "allowed_api_key_hashes"
    case allowedModels = "allowed_models"
    case allowedUserIDs = "allowed_user_ids"
    case declaredRegion = "declared_region"
    case declaredZDR = "declared_zdr"
    case disabled
    case isBYOKOnly = "is_byok_only"
    case isFallback = "is_fallback"
    case isRequired = "is_required"
    case key
    case name
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    switch allowedAPIKeyHashes {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .allowedAPIKeyHashes)
    case .value(let value): try c.encode(value, forKey: .allowedAPIKeyHashes)
    }
    switch allowedModels {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .allowedModels)
    case .value(let value): try c.encode(value, forKey: .allowedModels)
    }
    switch allowedUserIDs {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .allowedUserIDs)
    case .value(let value): try c.encode(value, forKey: .allowedUserIDs)
    }
    switch declaredRegion {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .declaredRegion)
    case .value(let value): try c.encode(value, forKey: .declaredRegion)
    }
    switch declaredZDR {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .declaredZDR)
    case .value(let value): try c.encode(value, forKey: .declaredZDR)
    }
    try c.encodeIfPresent(disabled, forKey: .disabled)
    try c.encodeIfPresent(isBYOKOnly, forKey: .isBYOKOnly)
    try c.encodeIfPresent(isFallback, forKey: .isFallback)
    try c.encodeIfPresent(isRequired, forKey: .isRequired)
    try c.encodeIfPresent(key, forKey: .key)
    switch name {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .name)
    case .value(let value): try c.encode(value, forKey: .name)
    }
  }
  public var description: String { "UpdateBYOKKeyRequest(key: [REDACTED])" }
  public var debugDescription: String { description }
  public var customMirror: Mirror { Mirror(self, children: ["key": "[REDACTED]"]) }
}

public struct CreateBYOKKeyResponse: Codable, Sendable, Equatable {
  public var data: BYOKKey
  public init(data: BYOKKey) { self.data = data }
}
public struct GetBYOKKeyResponse: Codable, Sendable, Equatable {
  public var data: BYOKKey
  public init(data: BYOKKey) { self.data = data }
}
public struct UpdateBYOKKeyResponse: Codable, Sendable, Equatable {
  public var data: BYOKKey
  public init(data: BYOKKey) { self.data = data }
}
public struct ListBYOKKeysResponse: Codable, Sendable, Equatable {
  public var data: [BYOKKey]
  public var totalCount: Int
  public init(data: [BYOKKey], totalCount: Int) {
    self.data = data
    self.totalCount = totalCount
  }
  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
}
/// Successful deletion is always confirmed with `deleted: true`.
public struct DeleteBYOKKeyResponse: Codable, Sendable, Equatable {
  public let deleted: Bool
  public init() { deleted = true }
  enum CodingKeys: String, CodingKey { case deleted }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    guard try c.decode(Bool.self, forKey: .deleted) else {
      throw DecodingError.dataCorruptedError(
        forKey: .deleted, in: c, debugDescription: "Expected deletion confirmation")
    }
    deleted = true
  }
}
