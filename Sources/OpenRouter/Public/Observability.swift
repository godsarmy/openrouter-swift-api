/// A nullable observability patch field. Unchanged fields are omitted from PATCH bodies.
public enum ObservabilityField<Value> {
  case unchanged, null
  case value(Value)
}
extension ObservabilityField: Sendable where Value: Sendable {}
extension ObservabilityField: Equatable where Value: Equatable {}

/// Sensitive observability objects deliberately hide their contents from diagnostics.
public protocol ObservabilityRedacted: CustomStringConvertible, CustomDebugStringConvertible,
  CustomReflectable
{}
extension ObservabilityRedacted {
  public var description: String { "\(Self.self)(redacted)" }
  public var debugDescription: String { description }
  public var customMirror: Mirror { Mirror(self, children: ["contents": "redacted"]) }
}

public enum ObservabilityFilterValue: Codable, Sendable, Equatable, ObservabilityRedacted {
  case string(String)
  case number(Double)
  public init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if let value = try? c.decode(String.self) {
      self = .string(value)
    } else {
      self = .number(try c.decode(Double.self))
    }
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .string(let value): try c.encode(value)
    case .number(let value): try c.encode(value)
    }
  }
}

public struct ObservabilityFilterRule: Codable, Sendable, Equatable, ObservabilityRedacted {
  public var field: String
  public var `operator`: String
  public var value: ObservabilityFilterValue?
  public init(field: String, operator: String, value: ObservabilityFilterValue? = nil) {
    self.field = field
    self.operator = `operator`
    self.value = value
  }
}
public struct ObservabilityFilterRuleGroup: Codable, Sendable, Equatable, ObservabilityRedacted {
  public var rules: [ObservabilityFilterRule]
  public var logic: String?
  public init(rules: [ObservabilityFilterRule], logic: String? = nil) {
    self.rules = rules
    self.logic = logic
  }
}
public struct ObservabilityFilterRulesConfig: Codable, Sendable, Equatable, ObservabilityRedacted {
  public var groups: [ObservabilityFilterRuleGroup]
  public var enabled: Bool?
  public init(groups: [ObservabilityFilterRuleGroup], enabled: Bool? = nil) {
    self.groups = groups
    self.enabled = enabled
  }
}

/// Provider configuration is an object, preserved verbatim and validated by the server.
public struct ObservabilityDestination: Codable, Sendable, Equatable, ObservabilityRedacted {
  public var apiKeyHashes: [String]?
  public var broadcastGenerationCost: Bool
  public var broadcastGenerationCostAllocation: Bool
  public var broadcastGenerationIdentity: Bool
  public var broadcastGenerationRequestContext: Bool
  public var config: [String: JSONValue]
  public var createdAt: String
  public var enabled: Bool
  public var filterRules: ObservabilityFilterRulesConfig?
  public var id: String
  public var name: String?
  public var privacyMode: Bool
  public var regions: [String]
  public var samplingRate: Double
  public var type: String
  public var updatedAt: String
  public var workspaceID: String
  public init(
    apiKeyHashes: [String]? = nil, broadcastGenerationCost: Bool,
    broadcastGenerationCostAllocation: Bool, broadcastGenerationIdentity: Bool,
    broadcastGenerationRequestContext: Bool, config: [String: JSONValue], createdAt: String,
    enabled: Bool, filterRules: ObservabilityFilterRulesConfig? = nil, id: String,
    name: String? = nil, privacyMode: Bool, regions: [String], samplingRate: Double, type: String,
    updatedAt: String, workspaceID: String
  ) {
    self.apiKeyHashes = apiKeyHashes
    self.broadcastGenerationCost = broadcastGenerationCost
    self.broadcastGenerationCostAllocation = broadcastGenerationCostAllocation
    self.broadcastGenerationIdentity = broadcastGenerationIdentity
    self.broadcastGenerationRequestContext = broadcastGenerationRequestContext
    self.config = config
    self.createdAt = createdAt
    self.enabled = enabled
    self.filterRules = filterRules
    self.id = id
    self.name = name
    self.privacyMode = privacyMode
    self.regions = regions
    self.samplingRate = samplingRate
    self.type = type
    self.updatedAt = updatedAt
    self.workspaceID = workspaceID
  }
  enum CodingKeys: String, CodingKey {
    case apiKeyHashes = "api_key_hashes"
    case broadcastGenerationCost = "broadcast_generation_cost"
    case broadcastGenerationCostAllocation = "broadcast_generation_cost_allocation"
    case broadcastGenerationIdentity = "broadcast_generation_identity"
    case broadcastGenerationRequestContext = "broadcast_generation_request_context"
    case config = "config"
    case createdAt = "created_at"
    case enabled = "enabled"
    case filterRules = "filter_rules"
    case id = "id"
    case name = "name"
    case privacyMode = "privacy_mode"
    case regions = "regions"
    case samplingRate = "sampling_rate"
    case type = "type"
    case updatedAt = "updated_at"
    case workspaceID = "workspace_id"
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    guard c.contains(.apiKeyHashes) else {
      throw DecodingError.keyNotFound(
        CodingKeys.apiKeyHashes,
        .init(codingPath: decoder.codingPath, debugDescription: "Missing required field"))
    }
    apiKeyHashes = try c.decodeIfPresent([String].self, forKey: .apiKeyHashes)
    broadcastGenerationCost = try c.decode(Bool.self, forKey: .broadcastGenerationCost)
    broadcastGenerationCostAllocation = try c.decode(
      Bool.self, forKey: .broadcastGenerationCostAllocation)
    broadcastGenerationIdentity = try c.decode(Bool.self, forKey: .broadcastGenerationIdentity)
    broadcastGenerationRequestContext = try c.decode(
      Bool.self, forKey: .broadcastGenerationRequestContext)
    config = try c.decode([String: JSONValue].self, forKey: .config)
    createdAt = try c.decode(String.self, forKey: .createdAt)
    enabled = try c.decode(Bool.self, forKey: .enabled)
    guard c.contains(.filterRules) else {
      throw DecodingError.keyNotFound(
        CodingKeys.filterRules,
        .init(codingPath: decoder.codingPath, debugDescription: "Missing required field"))
    }
    filterRules = try c.decodeIfPresent(ObservabilityFilterRulesConfig.self, forKey: .filterRules)
    id = try c.decode(String.self, forKey: .id)
    guard c.contains(.name) else {
      throw DecodingError.keyNotFound(
        CodingKeys.name,
        .init(codingPath: decoder.codingPath, debugDescription: "Missing required field"))
    }
    name = try c.decodeIfPresent(String.self, forKey: .name)
    privacyMode = try c.decode(Bool.self, forKey: .privacyMode)
    regions = try c.decode([String].self, forKey: .regions)
    samplingRate = try c.decode(Double.self, forKey: .samplingRate)
    type = try c.decode(String.self, forKey: .type)
    updatedAt = try c.decode(String.self, forKey: .updatedAt)
    workspaceID = try c.decode(String.self, forKey: .workspaceID)
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(apiKeyHashes, forKey: .apiKeyHashes)
    try c.encode(broadcastGenerationCost, forKey: .broadcastGenerationCost)
    try c.encode(broadcastGenerationCostAllocation, forKey: .broadcastGenerationCostAllocation)
    try c.encode(broadcastGenerationIdentity, forKey: .broadcastGenerationIdentity)
    try c.encode(broadcastGenerationRequestContext, forKey: .broadcastGenerationRequestContext)
    try c.encode(config, forKey: .config)
    try c.encode(createdAt, forKey: .createdAt)
    try c.encode(enabled, forKey: .enabled)
    try c.encode(filterRules, forKey: .filterRules)
    try c.encode(id, forKey: .id)
    try c.encode(name, forKey: .name)
    try c.encode(privacyMode, forKey: .privacyMode)
    try c.encode(regions, forKey: .regions)
    try c.encode(samplingRate, forKey: .samplingRate)
    try c.encode(type, forKey: .type)
    try c.encode(updatedAt, forKey: .updatedAt)
    try c.encode(workspaceID, forKey: .workspaceID)
  }
}

/// Provider configuration is an object, preserved verbatim and validated by the server.
public struct CreateObservabilityDestinationRequest: Codable, Sendable, Equatable,
  ObservabilityRedacted
{
  public var apiKeyHashes: [String]?
  public var broadcastGenerationCost: Bool?
  public var broadcastGenerationCostAllocation: Bool?
  public var broadcastGenerationIdentity: Bool?
  public var broadcastGenerationRequestContext: Bool?
  public var config: [String: JSONValue]
  public var enabled: Bool?
  public var filterRules: ObservabilityFilterRulesConfig?
  public var name: String
  public var privacyMode: Bool?
  public var regions: [String]?
  public var samplingRate: Double?
  public var type: String
  public var workspaceID: String?
  public init(
    type: String, name: String, config: [String: JSONValue],
    apiKeyHashes: [String]? = nil, broadcastGenerationCost: Bool? = nil,
    broadcastGenerationCostAllocation: Bool? = nil, broadcastGenerationIdentity: Bool? = nil,
    broadcastGenerationRequestContext: Bool? = nil,
    enabled: Bool? = nil, filterRules: ObservabilityFilterRulesConfig? = nil,
    privacyMode: Bool? = nil, regions: [String]? = nil, samplingRate: Double? = nil,
    workspaceID: String? = nil
  ) {
    self.apiKeyHashes = apiKeyHashes
    self.broadcastGenerationCost = broadcastGenerationCost
    self.broadcastGenerationCostAllocation = broadcastGenerationCostAllocation
    self.broadcastGenerationIdentity = broadcastGenerationIdentity
    self.broadcastGenerationRequestContext = broadcastGenerationRequestContext
    self.config = config
    self.enabled = enabled
    self.filterRules = filterRules
    self.name = name
    self.privacyMode = privacyMode
    self.regions = regions
    self.samplingRate = samplingRate
    self.type = type
    self.workspaceID = workspaceID
  }
  enum CodingKeys: String, CodingKey {
    case apiKeyHashes = "api_key_hashes"
    case broadcastGenerationCost = "broadcast_generation_cost"
    case broadcastGenerationCostAllocation = "broadcast_generation_cost_allocation"
    case broadcastGenerationIdentity = "broadcast_generation_identity"
    case broadcastGenerationRequestContext = "broadcast_generation_request_context"
    case config = "config"
    case enabled = "enabled"
    case filterRules = "filter_rules"
    case name = "name"
    case privacyMode = "privacy_mode"
    case regions = "regions"
    case samplingRate = "sampling_rate"
    case type = "type"
    case workspaceID = "workspace_id"
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    apiKeyHashes = try c.decodeIfPresent([String].self, forKey: .apiKeyHashes)
    broadcastGenerationCost = try c.decodeIfPresent(Bool.self, forKey: .broadcastGenerationCost)
    broadcastGenerationCostAllocation = try c.decodeIfPresent(
      Bool.self, forKey: .broadcastGenerationCostAllocation)
    broadcastGenerationIdentity = try c.decodeIfPresent(
      Bool.self, forKey: .broadcastGenerationIdentity)
    broadcastGenerationRequestContext = try c.decodeIfPresent(
      Bool.self, forKey: .broadcastGenerationRequestContext)
    config = try c.decode([String: JSONValue].self, forKey: .config)
    enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled)
    filterRules = try c.decodeIfPresent(ObservabilityFilterRulesConfig.self, forKey: .filterRules)
    name = try c.decode(String.self, forKey: .name)
    privacyMode = try c.decodeIfPresent(Bool.self, forKey: .privacyMode)
    regions = try c.decodeIfPresent([String].self, forKey: .regions)
    samplingRate = try c.decodeIfPresent(Double.self, forKey: .samplingRate)
    type = try c.decode(String.self, forKey: .type)
    workspaceID = try c.decodeIfPresent(String.self, forKey: .workspaceID)
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encodeIfPresent(apiKeyHashes, forKey: .apiKeyHashes)
    try c.encodeIfPresent(broadcastGenerationCost, forKey: .broadcastGenerationCost)
    try c.encodeIfPresent(
      broadcastGenerationCostAllocation, forKey: .broadcastGenerationCostAllocation)
    try c.encodeIfPresent(broadcastGenerationIdentity, forKey: .broadcastGenerationIdentity)
    try c.encodeIfPresent(
      broadcastGenerationRequestContext, forKey: .broadcastGenerationRequestContext)
    try c.encode(config, forKey: .config)
    try c.encodeIfPresent(enabled, forKey: .enabled)
    try c.encodeIfPresent(filterRules, forKey: .filterRules)
    try c.encode(name, forKey: .name)
    try c.encodeIfPresent(privacyMode, forKey: .privacyMode)
    try c.encodeIfPresent(regions, forKey: .regions)
    try c.encodeIfPresent(samplingRate, forKey: .samplingRate)
    try c.encode(type, forKey: .type)
    try c.encodeIfPresent(workspaceID, forKey: .workspaceID)
  }
}

/// Only explicit fields are patched. Masked config values are preserved; the server ignores them.
public struct UpdateObservabilityDestinationRequest: Codable, Sendable, Equatable,
  ObservabilityRedacted
{
  public var apiKeyHashes: ObservabilityField<[String]>
  public var broadcastGenerationCost: Bool?
  public var broadcastGenerationCostAllocation: Bool?
  public var broadcastGenerationIdentity: Bool?
  public var broadcastGenerationRequestContext: Bool?
  public var config: [String: JSONValue]?
  public var enabled: Bool?
  public var filterRules: ObservabilityField<ObservabilityFilterRulesConfig>
  public var name: String?
  public var privacyMode: Bool?
  public var regions: [String]?
  public var samplingRate: Double?
  public init(
    apiKeyHashes: ObservabilityField<[String]> = .unchanged, broadcastGenerationCost: Bool? = nil,
    broadcastGenerationCostAllocation: Bool? = nil, broadcastGenerationIdentity: Bool? = nil,
    broadcastGenerationRequestContext: Bool? = nil, config: [String: JSONValue]? = nil,
    enabled: Bool? = nil,
    filterRules: ObservabilityField<ObservabilityFilterRulesConfig> = .unchanged,
    name: String? = nil, privacyMode: Bool? = nil, regions: [String]? = nil,
    samplingRate: Double? = nil
  ) {
    self.apiKeyHashes = apiKeyHashes
    self.broadcastGenerationCost = broadcastGenerationCost
    self.broadcastGenerationCostAllocation = broadcastGenerationCostAllocation
    self.broadcastGenerationIdentity = broadcastGenerationIdentity
    self.broadcastGenerationRequestContext = broadcastGenerationRequestContext
    self.config = config
    self.enabled = enabled
    self.filterRules = filterRules
    self.name = name
    self.privacyMode = privacyMode
    self.regions = regions
    self.samplingRate = samplingRate
  }
  enum CodingKeys: String, CodingKey {
    case apiKeyHashes = "api_key_hashes"
    case broadcastGenerationCost = "broadcast_generation_cost"
    case broadcastGenerationCostAllocation = "broadcast_generation_cost_allocation"
    case broadcastGenerationIdentity = "broadcast_generation_identity"
    case broadcastGenerationRequestContext = "broadcast_generation_request_context"
    case config = "config"
    case enabled = "enabled"
    case filterRules = "filter_rules"
    case name = "name"
    case privacyMode = "privacy_mode"
    case regions = "regions"
    case samplingRate = "sampling_rate"
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    apiKeyHashes =
      !c.contains(.apiKeyHashes)
      ? .unchanged
      : try c.decodeNil(forKey: .apiKeyHashes)
        ? .null : .value(c.decode([String].self, forKey: .apiKeyHashes))
    broadcastGenerationCost = try c.decodeIfPresent(Bool.self, forKey: .broadcastGenerationCost)
    broadcastGenerationCostAllocation = try c.decodeIfPresent(
      Bool.self, forKey: .broadcastGenerationCostAllocation)
    broadcastGenerationIdentity = try c.decodeIfPresent(
      Bool.self, forKey: .broadcastGenerationIdentity)
    broadcastGenerationRequestContext = try c.decodeIfPresent(
      Bool.self, forKey: .broadcastGenerationRequestContext)
    config = c.contains(.config) ? try c.decode([String: JSONValue].self, forKey: .config) : nil
    enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled)
    filterRules =
      !c.contains(.filterRules)
      ? .unchanged
      : try c.decodeNil(forKey: .filterRules)
        ? .null : .value(c.decode(ObservabilityFilterRulesConfig.self, forKey: .filterRules))
    name = try c.decodeIfPresent(String.self, forKey: .name)
    privacyMode = try c.decodeIfPresent(Bool.self, forKey: .privacyMode)
    regions = try c.decodeIfPresent([String].self, forKey: .regions)
    samplingRate = try c.decodeIfPresent(Double.self, forKey: .samplingRate)
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    switch apiKeyHashes {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .apiKeyHashes)
    case .value(let v): try c.encode(v, forKey: .apiKeyHashes)
    }
    try c.encodeIfPresent(broadcastGenerationCost, forKey: .broadcastGenerationCost)
    try c.encodeIfPresent(
      broadcastGenerationCostAllocation, forKey: .broadcastGenerationCostAllocation)
    try c.encodeIfPresent(broadcastGenerationIdentity, forKey: .broadcastGenerationIdentity)
    try c.encodeIfPresent(
      broadcastGenerationRequestContext, forKey: .broadcastGenerationRequestContext)
    try c.encodeIfPresent(config, forKey: .config)
    try c.encodeIfPresent(enabled, forKey: .enabled)
    switch filterRules {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .filterRules)
    case .value(let v): try c.encode(v, forKey: .filterRules)
    }
    try c.encodeIfPresent(name, forKey: .name)
    try c.encodeIfPresent(privacyMode, forKey: .privacyMode)
    try c.encodeIfPresent(regions, forKey: .regions)
    try c.encodeIfPresent(samplingRate, forKey: .samplingRate)
  }
}

public struct GetObservabilityDestinationResponse: Codable, Sendable, Equatable,
  ObservabilityRedacted
{
  public var data: ObservabilityDestination
  public init(data: ObservabilityDestination) { self.data = data }
}
public typealias CreateObservabilityDestinationResponse = GetObservabilityDestinationResponse
public typealias UpdateObservabilityDestinationResponse = GetObservabilityDestinationResponse
public struct ListObservabilityDestinationsResponse: Codable, Sendable, Equatable,
  ObservabilityRedacted
{
  public var data: [ObservabilityDestination]
  public var totalCount: Int
  public init(data: [ObservabilityDestination], totalCount: Int) {
    self.data = data
    self.totalCount = totalCount
  }
  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
}
public struct DeleteObservabilityDestinationResponse: Codable, Sendable, Equatable {
  public let deleted: Bool
  public init() { deleted = true }
  enum CodingKeys: String, CodingKey { case deleted }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    guard try c.decode(Bool.self, forKey: .deleted) else {
      throw DecodingError.dataCorruptedError(
        forKey: .deleted, in: c, debugDescription: "Expected deleted: true")
    }
    deleted = true
  }
}
