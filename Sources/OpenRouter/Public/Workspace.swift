/// A nullable workspace setting: omitted, assigned, or explicitly cleared.
public enum WorkspaceField<Value> {
  case unchanged
  case value(Value)
  case null
}
extension WorkspaceField: Sendable where Value: Sendable {}
extension WorkspaceField: Equatable where Value: Equatable {}

/// A workspace and its default model, logging, and budget settings.
public struct Workspace: Codable, Sendable, Equatable {
  public var id: String
  public var defaultGuardrailID: String
  public var name: String
  public var slug: String
  public var description: String?
  public var defaultTextModel: String?
  public var defaultImageModel: String?
  public var defaultProviderSort: String?
  public var isObservabilityIOLoggingEnabled: Bool
  public var isObservabilityBroadcastEnabled: Bool
  public var isDataDiscountLoggingEnabled: Bool
  public var ioLoggingSamplingRate: Double
  public var ioLoggingAPIKeyIDs: [Int]?
  public var createdAt: String
  public var updatedAt: String?
  public var createdBy: String?
  public var disabledServerTools: [String]?
  public var includeBYOKInBudgets: Bool?

  public init(
    id: String,
    defaultGuardrailID: String,
    name: String,
    slug: String,
    description: String? = nil,
    defaultTextModel: String? = nil,
    defaultImageModel: String? = nil,
    defaultProviderSort: String? = nil,
    isObservabilityIOLoggingEnabled: Bool,
    isObservabilityBroadcastEnabled: Bool,
    isDataDiscountLoggingEnabled: Bool,
    ioLoggingSamplingRate: Double,
    ioLoggingAPIKeyIDs: [Int]? = nil,
    createdAt: String,
    updatedAt: String? = nil,
    createdBy: String? = nil,
    disabledServerTools: [String]? = nil,
    includeBYOKInBudgets: Bool? = nil
  ) {
    self.id = id
    self.defaultGuardrailID = defaultGuardrailID
    self.name = name
    self.slug = slug
    self.description = description
    self.defaultTextModel = defaultTextModel
    self.defaultImageModel = defaultImageModel
    self.defaultProviderSort = defaultProviderSort
    self.isObservabilityIOLoggingEnabled = isObservabilityIOLoggingEnabled
    self.isObservabilityBroadcastEnabled = isObservabilityBroadcastEnabled
    self.isDataDiscountLoggingEnabled = isDataDiscountLoggingEnabled
    self.ioLoggingSamplingRate = ioLoggingSamplingRate
    self.ioLoggingAPIKeyIDs = ioLoggingAPIKeyIDs
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.createdBy = createdBy
    self.disabledServerTools = disabledServerTools
    self.includeBYOKInBudgets = includeBYOKInBudgets
  }

  enum CodingKeys: String, CodingKey {
    case id, name, slug, description
    case defaultGuardrailID = "default_guardrail_id"
    case defaultTextModel = "default_text_model"
    case defaultImageModel = "default_image_model"
    case defaultProviderSort = "default_provider_sort"
    case isObservabilityIOLoggingEnabled = "is_observability_io_logging_enabled"
    case isObservabilityBroadcastEnabled = "is_observability_broadcast_enabled"
    case isDataDiscountLoggingEnabled = "is_data_discount_logging_enabled"
    case ioLoggingSamplingRate = "io_logging_sampling_rate"
    case ioLoggingAPIKeyIDs = "io_logging_api_key_ids"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case createdBy = "created_by"
    case disabledServerTools = "disabled_server_tools"
    case includeBYOKInBudgets = "include_byok_in_budgets"
  }
}

/// A page of workspaces and the total number available.
public struct WorkspacesResponse: Codable, Sendable, Equatable {
  public var data: [Workspace]
  public var totalCount: Int

  public init(data: [Workspace], totalCount: Int) {
    self.data = data
    self.totalCount = totalCount
  }

  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
}

/// A single workspace response.
public struct WorkspaceResponse: Codable, Sendable, Equatable {
  public var data: Workspace

  public init(data: Workspace) {
    self.data = data
  }
}

/// Partial workspace settings. `.unchanged` omits a nullable field; `.null` clears it.
/// Constraints (including slug syntax and sampling rate) are validated by the server.
public struct UpdateWorkspaceRequest: Encodable, Sendable, Equatable {
  public var name: String?
  public var slug: String?
  public var description: WorkspaceField<String> = .unchanged
  public var defaultTextModel: WorkspaceField<String> = .unchanged
  public var defaultImageModel: WorkspaceField<String> = .unchanged
  public var defaultProviderSort: WorkspaceField<String> = .unchanged
  public var disabledServerTools: WorkspaceField<[String]> = .unchanged
  public var ioLoggingAPIKeyIDs: WorkspaceField<[Int]> = .unchanged
  public var ioLoggingSamplingRate: Double?
  public var isDataDiscountLoggingEnabled: Bool?
  public var isObservabilityBroadcastEnabled: Bool?
  public var isObservabilityIOLoggingEnabled: Bool?

  public init(name: String? = nil, slug: String? = nil) {
    self.name = name
    self.slug = slug
  }

  enum CodingKeys: String, CodingKey {
    case name, slug, description
    case defaultTextModel = "default_text_model"
    case defaultImageModel = "default_image_model"
    case defaultProviderSort = "default_provider_sort"
    case disabledServerTools = "disabled_server_tools"
    case ioLoggingAPIKeyIDs = "io_logging_api_key_ids"
    case ioLoggingSamplingRate = "io_logging_sampling_rate"
    case isDataDiscountLoggingEnabled = "is_data_discount_logging_enabled"
    case isObservabilityBroadcastEnabled = "is_observability_broadcast_enabled"
    case isObservabilityIOLoggingEnabled = "is_observability_io_logging_enabled"
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(name, forKey: .name)
    try container.encodeIfPresent(slug, forKey: .slug)
    try container.encodeIfPresent(ioLoggingSamplingRate, forKey: .ioLoggingSamplingRate)
    try container.encodeIfPresent(
      isDataDiscountLoggingEnabled, forKey: .isDataDiscountLoggingEnabled)
    try container.encodeIfPresent(
      isObservabilityBroadcastEnabled, forKey: .isObservabilityBroadcastEnabled)
    try container.encodeIfPresent(
      isObservabilityIOLoggingEnabled, forKey: .isObservabilityIOLoggingEnabled)
    try encode(description, forKey: .description, in: &container)
    try encode(defaultTextModel, forKey: .defaultTextModel, in: &container)
    try encode(defaultImageModel, forKey: .defaultImageModel, in: &container)
    try encode(defaultProviderSort, forKey: .defaultProviderSort, in: &container)
    try encode(disabledServerTools, forKey: .disabledServerTools, in: &container)
    try encode(ioLoggingAPIKeyIDs, forKey: .ioLoggingAPIKeyIDs, in: &container)
  }

  private func encode<Value: Encodable>(
    _ field: WorkspaceField<Value>, forKey key: CodingKeys,
    in container: inout KeyedEncodingContainer<CodingKeys>
  ) throws {
    switch field {
    case .unchanged: break
    case .value(let value): try container.encode(value, forKey: key)
    case .null: try container.encodeNil(forKey: key)
    }
  }
}

/// Creates a workspace with required name and slug and optional settings.
/// Settings are encoded in the same JSON object, not under a `settings` key.
public struct CreateWorkspaceRequest: Encodable, Sendable, Equatable {
  public var name: String
  public var slug: String
  public var settings: UpdateWorkspaceRequest

  public init(name: String, slug: String, settings: UpdateWorkspaceRequest = .init()) {
    self.name = name
    self.slug = slug
    self.settings = settings
  }

  public func encode(to encoder: Encoder) throws {
    var request = settings
    request.name = name
    request.slug = slug
    try request.encode(to: encoder)
  }
}

public struct DeleteWorkspaceResponse: Codable, Sendable, Equatable {
  public var deleted: Bool
  public init(deleted: Bool) { self.deleted = deleted }
}

/// The server requires 1...100 user IDs per operation.
public struct WorkspaceMembersRequest: Codable, Sendable, Equatable {
  public var userIDs: [String]
  public init(userIDs: [String]) { self.userIDs = userIDs }
  enum CodingKeys: String, CodingKey { case userIDs = "user_ids" }
}

public struct WorkspaceMembership: Codable, Sendable, Equatable {
  public var id: String
  public var workspaceID: String
  public var userID: String
  public var role: String
  public var createdAt: String

  public init(id: String, workspaceID: String, userID: String, role: String, createdAt: String) {
    self.id = id
    self.workspaceID = workspaceID
    self.userID = userID
    self.role = role
    self.createdAt = createdAt
  }
  enum CodingKeys: String, CodingKey {
    case id, role
    case workspaceID = "workspace_id"
    case userID = "user_id"
    case createdAt = "created_at"
  }
}

public struct AddWorkspaceMembersResponse: Codable, Sendable, Equatable {
  public var addedCount: Int
  public var data: [WorkspaceMembership]
  public init(addedCount: Int, data: [WorkspaceMembership]) {
    self.addedCount = addedCount
    self.data = data
  }
  enum CodingKeys: String, CodingKey {
    case data
    case addedCount = "added_count"
  }
}

public struct RemoveWorkspaceMembersResponse: Codable, Sendable, Equatable {
  public var removedCount: Int
  public init(removedCount: Int) { self.removedCount = removedCount }
  enum CodingKeys: String, CodingKey { case removedCount = "removed_count" }
}

/// A page of workspace memberships and the total number available.
public struct WorkspaceMembersResponse: Codable, Sendable, Equatable {
  public var data: [WorkspaceMembership]
  public var totalCount: Int

  public init(data: [WorkspaceMembership], totalCount: Int) {
    self.data = data
    self.totalCount = totalCount
  }

  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
}
