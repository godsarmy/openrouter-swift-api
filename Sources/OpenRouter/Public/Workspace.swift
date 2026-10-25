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
