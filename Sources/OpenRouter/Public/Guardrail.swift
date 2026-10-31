/// A nullable guardrail patch: omit, explicitly clear, or assign a value.
public enum GuardrailField<Value> {
  case unchanged, null
  case value(Value)
}
extension GuardrailField: Sendable where Value: Sendable {}
extension GuardrailField: Equatable where Value: Equatable {}
/// A custom regex content filter that scans request messages for matching patterns.
public struct ContentFilterEntry: Codable, Sendable, Equatable {
  ///  Known actions: redact, block, flag.
  public var action: String
  /// Optional label used in redaction placeholders or error messages
  public var label: String?
  /// A regex pattern to match against request content
  public var pattern: String
  public init(action: String, label: String? = nil, pattern: String) {
    self.action = action
    self.label = label
    self.pattern = pattern
  }
  enum CodingKeys: String, CodingKey {
    case action
    case label
    case pattern
  }
}
/// A builtin content filter entry for create/update requests. Labels are system-assigned and cannot be set by the caller.
public struct ContentFilterBuiltinEntryInput: Codable, Sendable, Equatable {
  ///  Known actions: redact, block, flag.
  public var action: String
  /// Deprecated: labels are system-assigned and cannot be set by the caller. Accepted for backward compatibility but silently ignored.
  public var label: String?
  /// Known values: user_only, all_messages; applies only to regex-prompt-injection.
  public var scanScope: String?
  ///  Known slugs: email, phone, ssn, credit-card, ip-address, secrets, person-name, address, regex-prompt-injection.
  public var slug: String
  public init(action: String, label: String? = nil, scanScope: String? = nil, slug: String) {
    self.action = action
    self.label = label
    self.scanScope = scanScope
    self.slug = slug
  }
  enum CodingKeys: String, CodingKey {
    case action
    case label
    case scanScope = "scan_scope"
    case slug
  }
}
/// A builtin content filter entry. Builtin filters include PII detectors, API-key and secret detectors, and the regex-based prompt injection detector.
public struct ContentFilterBuiltinEntry: Codable, Sendable, Equatable {
  ///  Known actions: redact, block, flag.
  public var action: String
  /// Read-only, system-assigned redaction placeholder derived from the slug (e.g. "[EMAIL]", "[PHONE]"). Not settable by the caller.
  public var label: String?
  /// Known values: user_only, all_messages; applies only to regex-prompt-injection.
  public var scanScope: String?
  ///  Known slugs: email, phone, ssn, credit-card, ip-address, secrets, person-name, address, regex-prompt-injection.
  public var slug: String
  public init(action: String, label: String? = nil, scanScope: String? = nil, slug: String) {
    self.action = action
    self.label = label
    self.scanScope = scanScope
    self.slug = slug
  }
  enum CodingKeys: String, CodingKey {
    case action
    case label
    case scanScope = "scan_scope"
    case slug
  }
}
/// Guardrail
public struct Guardrail: Codable, Sendable, Equatable {
  /// Whether ZDR-only requests to google/* models may use endpoints that may retain prompts for safety monitoring. false allows only zero-retention endpoints. A guardrail can only be more restrictive than the account setting. Inherits the account setting when not provided.
  public var allowSafetyRetentionGoogle: Bool?
  /// Whether ZDR-only requests to models outside the named providers (for example open-weight models on Vertex) may use endpoints that may retain prompts for safety monitoring. false allows only zero-retention endpoints. A guardrail can only be more restrictive than the account setting. Inherits the account setting when not provided.
  public var allowSafetyRetentionOther: Bool?
  /// Data regions through which requests governed by this guardrail must arrive. `global` is https://openrouter.ai, `europe` is https://eu.openrouter.ai, and `us` is https://us.openrouter.ai. Requests arriving through any other region are rejected. `null` leaves the ingress region unrestricted. When several guardrails apply (workspace default, member, API key), the effective regions are the intersection of every non-null value. Known regions: global, europe, us.
  public var allowedDataRegions: [String]?
  /// Array of model canonical_slugs (immutable identifiers)
  public var allowedModels: [String]?
  /// List of allowed provider IDs
  public var allowedProviders: [String]?
  /// Builtin content filters applied to requests. Includes PII detectors and the regex-based prompt injection detector.
  public var contentFilterBuiltins: [ContentFilterBuiltinEntry]?
  /// Custom regex content filters applied to request messages
  public var contentFilters: [ContentFilterEntry]?
  /// ISO 8601 timestamp of when the guardrail was created
  public var createdAt: String
  /// Description of the guardrail
  public var description: String?
  /// Whether this guardrail allows free endpoints that publish prompts.
  public var enableFreeModelPublication: Bool?
  /// Whether this guardrail allows free endpoints that train on request data.
  public var enableFreeModelTraining: Bool?
  /// Whether this guardrail allows paid endpoints that train on request data.
  public var enablePaidModelTraining: Bool?
  /// Whether coding harnesses list only their vendor's own models: Codex lists OpenAI models and Claude Code and Claude Desktop list Anthropic models. Affects only the model list those harnesses request from GET /models; a model the client names directly is still routed. Any true across the workspace default, member, and API key guardrails applies.
  public var enforceFirstPartyHarnessModels: Bool?
  /// Deprecated. Use enforce_zdr_anthropic, enforce_zdr_openai, enforce_zdr_google, enforce_zdr_xai, and enforce_zdr_other instead. When provided, its value is copied into any of those per-provider fields that are not explicitly specified on the request.
  public var enforceZDR: Bool?
  /// Whether to enforce zero data retention for Anthropic models. Falls back to enforce_zdr when not provided.
  public var enforceZDRAnthropic: Bool?
  /// Whether to enforce zero data retention for Google models. Falls back to enforce_zdr when not provided.
  public var enforceZDRGoogle: Bool?
  /// Whether to enforce zero data retention for OpenAI models. Falls back to enforce_zdr when not provided.
  public var enforceZDROpenAI: Bool?
  /// Whether to enforce zero data retention for models that are not from Anthropic, OpenAI, Google, or xAI. Falls back to enforce_zdr when not provided.
  public var enforceZDROther: Bool?
  /// Whether to enforce zero data retention for xAI models. Falls back to enforce_zdr when not provided.
  public var enforceZDRXAI: Bool?
  /// Unique identifier for the guardrail
  public var id: String
  /// Array of model canonical_slugs to exclude from routing
  public var ignoredModels: [String]?
  /// List of provider IDs to exclude from routing
  public var ignoredProviders: [String]?
  /// Whether BYOK (bring-your-own-key) inference spend counts toward this guardrail's limit_usd, in addition to OpenRouter credit spend.
  public var includeBYOKInBudgets: Bool
  /// Spending limit in USD
  public var limitUSD: Double?
  /// Name of the guardrail
  public var name: String
  ///  Known values: daily, weekly, monthly.
  public var resetInterval: String?
  /// ISO 8601 timestamp of when the guardrail was last updated
  public var updatedAt: String?
  /// The workspace this guardrail belongs to, or `null` for an unscoped legacy guardrail predating workspaces. Workspace membership organizes the guardrail; it does not apply the guardrail to the workspace's traffic. A `null` value does not mean the default workspace, and does not apply the guardrail across every workspace.
  public var workspaceID: String?
  public init(
    allowSafetyRetentionGoogle: Bool? = nil, allowSafetyRetentionOther: Bool? = nil,
    allowedDataRegions: [String]? = nil, allowedModels: [String]? = nil,
    allowedProviders: [String]? = nil, contentFilterBuiltins: [ContentFilterBuiltinEntry]? = nil,
    contentFilters: [ContentFilterEntry]? = nil, createdAt: String, description: String? = nil,
    enableFreeModelPublication: Bool? = nil, enableFreeModelTraining: Bool? = nil,
    enablePaidModelTraining: Bool? = nil, enforceFirstPartyHarnessModels: Bool? = nil,
    enforceZDR: Bool? = nil, enforceZDRAnthropic: Bool? = nil, enforceZDRGoogle: Bool? = nil,
    enforceZDROpenAI: Bool? = nil, enforceZDROther: Bool? = nil, enforceZDRXAI: Bool? = nil,
    id: String, ignoredModels: [String]? = nil, ignoredProviders: [String]? = nil,
    includeBYOKInBudgets: Bool, limitUSD: Double? = nil, name: String, resetInterval: String? = nil,
    updatedAt: String? = nil, workspaceID: String? = nil
  ) {
    self.allowSafetyRetentionGoogle = allowSafetyRetentionGoogle
    self.allowSafetyRetentionOther = allowSafetyRetentionOther
    self.allowedDataRegions = allowedDataRegions
    self.allowedModels = allowedModels
    self.allowedProviders = allowedProviders
    self.contentFilterBuiltins = contentFilterBuiltins
    self.contentFilters = contentFilters
    self.createdAt = createdAt
    self.description = description
    self.enableFreeModelPublication = enableFreeModelPublication
    self.enableFreeModelTraining = enableFreeModelTraining
    self.enablePaidModelTraining = enablePaidModelTraining
    self.enforceFirstPartyHarnessModels = enforceFirstPartyHarnessModels
    self.enforceZDR = enforceZDR
    self.enforceZDRAnthropic = enforceZDRAnthropic
    self.enforceZDRGoogle = enforceZDRGoogle
    self.enforceZDROpenAI = enforceZDROpenAI
    self.enforceZDROther = enforceZDROther
    self.enforceZDRXAI = enforceZDRXAI
    self.id = id
    self.ignoredModels = ignoredModels
    self.ignoredProviders = ignoredProviders
    self.includeBYOKInBudgets = includeBYOKInBudgets
    self.limitUSD = limitUSD
    self.name = name
    self.resetInterval = resetInterval
    self.updatedAt = updatedAt
    self.workspaceID = workspaceID
  }
  enum CodingKeys: String, CodingKey {
    case allowSafetyRetentionGoogle = "allow_safety_retention_google"
    case allowSafetyRetentionOther = "allow_safety_retention_other"
    case allowedDataRegions = "allowed_data_regions"
    case allowedModels = "allowed_models"
    case allowedProviders = "allowed_providers"
    case contentFilterBuiltins = "content_filter_builtins"
    case contentFilters = "content_filters"
    case createdAt = "created_at"
    case description
    case enableFreeModelPublication = "enable_free_model_publication"
    case enableFreeModelTraining = "enable_free_model_training"
    case enablePaidModelTraining = "enable_paid_model_training"
    case enforceFirstPartyHarnessModels = "enforce_first_party_harness_models"
    case enforceZDR = "enforce_zdr"
    case enforceZDRAnthropic = "enforce_zdr_anthropic"
    case enforceZDRGoogle = "enforce_zdr_google"
    case enforceZDROpenAI = "enforce_zdr_openai"
    case enforceZDROther = "enforce_zdr_other"
    case enforceZDRXAI = "enforce_zdr_xai"
    case id
    case ignoredModels = "ignored_models"
    case ignoredProviders = "ignored_providers"
    case includeBYOKInBudgets = "include_byok_in_budgets"
    case limitUSD = "limit_usd"
    case name
    case resetInterval = "reset_interval"
    case updatedAt = "updated_at"
    case workspaceID = "workspace_id"
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encodeIfPresent(allowSafetyRetentionGoogle, forKey: .allowSafetyRetentionGoogle)
    try c.encodeIfPresent(allowSafetyRetentionOther, forKey: .allowSafetyRetentionOther)
    try c.encodeIfPresent(allowedDataRegions, forKey: .allowedDataRegions)
    try c.encodeIfPresent(allowedModels, forKey: .allowedModels)
    try c.encodeIfPresent(allowedProviders, forKey: .allowedProviders)
    try c.encodeIfPresent(contentFilterBuiltins, forKey: .contentFilterBuiltins)
    try c.encodeIfPresent(contentFilters, forKey: .contentFilters)
    try c.encode(createdAt, forKey: .createdAt)
    try c.encodeIfPresent(description, forKey: .description)
    try c.encodeIfPresent(enableFreeModelPublication, forKey: .enableFreeModelPublication)
    try c.encodeIfPresent(enableFreeModelTraining, forKey: .enableFreeModelTraining)
    try c.encodeIfPresent(enablePaidModelTraining, forKey: .enablePaidModelTraining)
    try c.encodeIfPresent(enforceFirstPartyHarnessModels, forKey: .enforceFirstPartyHarnessModels)
    try c.encodeIfPresent(enforceZDR, forKey: .enforceZDR)
    try c.encodeIfPresent(enforceZDRAnthropic, forKey: .enforceZDRAnthropic)
    try c.encodeIfPresent(enforceZDRGoogle, forKey: .enforceZDRGoogle)
    try c.encodeIfPresent(enforceZDROpenAI, forKey: .enforceZDROpenAI)
    try c.encodeIfPresent(enforceZDROther, forKey: .enforceZDROther)
    try c.encodeIfPresent(enforceZDRXAI, forKey: .enforceZDRXAI)
    try c.encode(id, forKey: .id)
    try c.encodeIfPresent(ignoredModels, forKey: .ignoredModels)
    try c.encodeIfPresent(ignoredProviders, forKey: .ignoredProviders)
    try c.encode(includeBYOKInBudgets, forKey: .includeBYOKInBudgets)
    try c.encodeIfPresent(limitUSD, forKey: .limitUSD)
    try c.encode(name, forKey: .name)
    try c.encodeIfPresent(resetInterval, forKey: .resetInterval)
    try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
    try c.encode(workspaceID, forKey: .workspaceID)
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    allowSafetyRetentionGoogle = try c.decodeIfPresent(
      Bool.self, forKey: .allowSafetyRetentionGoogle)
    allowSafetyRetentionOther = try c.decodeIfPresent(Bool.self, forKey: .allowSafetyRetentionOther)
    allowedDataRegions = try c.decodeIfPresent([String].self, forKey: .allowedDataRegions)
    allowedModels = try c.decodeIfPresent([String].self, forKey: .allowedModels)
    allowedProviders = try c.decodeIfPresent([String].self, forKey: .allowedProviders)
    contentFilterBuiltins = try c.decodeIfPresent(
      [ContentFilterBuiltinEntry].self, forKey: .contentFilterBuiltins)
    contentFilters = try c.decodeIfPresent([ContentFilterEntry].self, forKey: .contentFilters)
    createdAt = try c.decode(String.self, forKey: .createdAt)
    description = try c.decodeIfPresent(String.self, forKey: .description)
    enableFreeModelPublication = try c.decodeIfPresent(
      Bool.self, forKey: .enableFreeModelPublication)
    enableFreeModelTraining = try c.decodeIfPresent(Bool.self, forKey: .enableFreeModelTraining)
    enablePaidModelTraining = try c.decodeIfPresent(Bool.self, forKey: .enablePaidModelTraining)
    enforceFirstPartyHarnessModels = try c.decodeIfPresent(
      Bool.self, forKey: .enforceFirstPartyHarnessModels)
    enforceZDR = try c.decodeIfPresent(Bool.self, forKey: .enforceZDR)
    enforceZDRAnthropic = try c.decodeIfPresent(Bool.self, forKey: .enforceZDRAnthropic)
    enforceZDRGoogle = try c.decodeIfPresent(Bool.self, forKey: .enforceZDRGoogle)
    enforceZDROpenAI = try c.decodeIfPresent(Bool.self, forKey: .enforceZDROpenAI)
    enforceZDROther = try c.decodeIfPresent(Bool.self, forKey: .enforceZDROther)
    enforceZDRXAI = try c.decodeIfPresent(Bool.self, forKey: .enforceZDRXAI)
    id = try c.decode(String.self, forKey: .id)
    ignoredModels = try c.decodeIfPresent([String].self, forKey: .ignoredModels)
    ignoredProviders = try c.decodeIfPresent([String].self, forKey: .ignoredProviders)
    includeBYOKInBudgets = try c.decode(Bool.self, forKey: .includeBYOKInBudgets)
    limitUSD = try c.decodeIfPresent(Double.self, forKey: .limitUSD)
    name = try c.decode(String.self, forKey: .name)
    resetInterval = try c.decodeIfPresent(String.self, forKey: .resetInterval)
    updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
    guard c.contains(.workspaceID) else {
      throw DecodingError.keyNotFound(
        CodingKeys.workspaceID,
        .init(codingPath: c.codingPath, debugDescription: "Missing required nullable field"))
    }
    workspaceID = try c.decodeIfPresent(String.self, forKey: .workspaceID)
  }
}
/// CreateGuardrailRequest
public struct CreateGuardrailRequest: Encodable, Sendable, Equatable {
  /// Whether ZDR-only requests to google/* models may use endpoints that may retain prompts for safety monitoring. false allows only zero-retention endpoints. A guardrail can only be more restrictive than the account setting. Inherits the account setting when not provided.
  public var allowSafetyRetentionGoogle: Bool?
  /// Whether ZDR-only requests to models outside the named providers (for example open-weight models on Vertex) may use endpoints that may retain prompts for safety monitoring. false allows only zero-retention endpoints. A guardrail can only be more restrictive than the account setting. Inherits the account setting when not provided.
  public var allowSafetyRetentionOther: Bool?
  /// Data regions through which requests governed by this guardrail must arrive. `global` is https://openrouter.ai, `europe` is https://eu.openrouter.ai, and `us` is https://us.openrouter.ai. Requests arriving through any other region are rejected. `null` leaves the ingress region unrestricted. When several guardrails apply (workspace default, member, API key), the effective regions are the intersection of every non-null value. An empty array is rejected. Known regions: global, europe, us.
  public var allowedDataRegions: [String]?
  /// Array of model identifiers (slug or canonical_slug accepted)
  public var allowedModels: [String]?
  /// List of allowed provider IDs
  public var allowedProviders: [String]?
  /// Builtin content filters to apply. Every builtin slug supports "block", "redact", and the detect-only "flag" action.
  public var contentFilterBuiltins: [ContentFilterBuiltinEntryInput]?
  /// Custom regex content filters to apply to request messages
  public var contentFilters: [ContentFilterEntry]?
  /// Description of the guardrail
  public var description: String?
  /// Whether this guardrail allows free endpoints that publish prompts.
  public var enableFreeModelPublication: Bool?
  /// Whether this guardrail allows free endpoints that train on request data.
  public var enableFreeModelTraining: Bool?
  /// Whether this guardrail allows paid endpoints that train on request data.
  public var enablePaidModelTraining: Bool?
  /// Whether coding harnesses list only their vendor's own models: Codex lists OpenAI models and Claude Code and Claude Desktop list Anthropic models. Affects only the model list those harnesses request from GET /models; a model the client names directly is still routed. Any true across the workspace default, member, and API key guardrails applies.
  public var enforceFirstPartyHarnessModels: Bool?
  /// Deprecated. Use enforce_zdr_anthropic, enforce_zdr_openai, enforce_zdr_google, enforce_zdr_xai, and enforce_zdr_other instead. When provided, its value is copied into any of those per-provider fields that are not explicitly specified on the request.
  public var enforceZDR: Bool?
  /// Whether to enforce zero data retention for Anthropic models. Falls back to enforce_zdr when not provided.
  public var enforceZDRAnthropic: Bool?
  /// Whether to enforce zero data retention for Google models. Falls back to enforce_zdr when not provided.
  public var enforceZDRGoogle: Bool?
  /// Whether to enforce zero data retention for OpenAI models. Falls back to enforce_zdr when not provided.
  public var enforceZDROpenAI: Bool?
  /// Whether to enforce zero data retention for models that are not from Anthropic, OpenAI, Google, or xAI. Falls back to enforce_zdr when not provided.
  public var enforceZDROther: Bool?
  /// Whether to enforce zero data retention for xAI models. Falls back to enforce_zdr when not provided.
  public var enforceZDRXAI: Bool?
  /// Array of model identifiers to exclude from routing (slug or canonical_slug accepted)
  public var ignoredModels: [String]?
  /// List of provider IDs to exclude from routing
  public var ignoredProviders: [String]?
  /// Whether BYOK (bring-your-own-key) inference spend counts toward this guardrail's limit_usd, in addition to OpenRouter credit spend. Defaults to false.
  public var includeBYOKInBudgets: Bool?
  /// Spending limit in USD. Must be provided together with `reset_interval`: a request that sets only one of the two is rejected with a 400.
  public var limitUSD: Double?
  /// Name for the new guardrail
  public var name: String
  ///  Known values: daily, weekly, monthly.
  public var resetInterval: String?
  /// The workspace to create the guardrail in. When omitted, the guardrail is created in the default workspace; if that default has been deleted, the request returns a 400 and you must pass `workspace_id` explicitly. This only places the guardrail in the workspace; the created guardrail enforces nothing for that workspace's traffic until it is assigned to API keys or members. To restrict all traffic in a workspace, update the workspace's default guardrail instead.
  public var workspaceID: String?
  public init(
    allowSafetyRetentionGoogle: Bool? = nil, allowSafetyRetentionOther: Bool? = nil,
    allowedDataRegions: [String]? = nil, allowedModels: [String]? = nil,
    allowedProviders: [String]? = nil,
    contentFilterBuiltins: [ContentFilterBuiltinEntryInput]? = nil,
    contentFilters: [ContentFilterEntry]? = nil, description: String? = nil,
    enableFreeModelPublication: Bool? = nil, enableFreeModelTraining: Bool? = nil,
    enablePaidModelTraining: Bool? = nil, enforceFirstPartyHarnessModels: Bool? = nil,
    enforceZDR: Bool? = nil, enforceZDRAnthropic: Bool? = nil, enforceZDRGoogle: Bool? = nil,
    enforceZDROpenAI: Bool? = nil, enforceZDROther: Bool? = nil, enforceZDRXAI: Bool? = nil,
    ignoredModels: [String]? = nil, ignoredProviders: [String]? = nil,
    includeBYOKInBudgets: Bool? = nil, limitUSD: Double? = nil, name: String,
    resetInterval: String? = nil, workspaceID: String? = nil
  ) {
    self.allowSafetyRetentionGoogle = allowSafetyRetentionGoogle
    self.allowSafetyRetentionOther = allowSafetyRetentionOther
    self.allowedDataRegions = allowedDataRegions
    self.allowedModels = allowedModels
    self.allowedProviders = allowedProviders
    self.contentFilterBuiltins = contentFilterBuiltins
    self.contentFilters = contentFilters
    self.description = description
    self.enableFreeModelPublication = enableFreeModelPublication
    self.enableFreeModelTraining = enableFreeModelTraining
    self.enablePaidModelTraining = enablePaidModelTraining
    self.enforceFirstPartyHarnessModels = enforceFirstPartyHarnessModels
    self.enforceZDR = enforceZDR
    self.enforceZDRAnthropic = enforceZDRAnthropic
    self.enforceZDRGoogle = enforceZDRGoogle
    self.enforceZDROpenAI = enforceZDROpenAI
    self.enforceZDROther = enforceZDROther
    self.enforceZDRXAI = enforceZDRXAI
    self.ignoredModels = ignoredModels
    self.ignoredProviders = ignoredProviders
    self.includeBYOKInBudgets = includeBYOKInBudgets
    self.limitUSD = limitUSD
    self.name = name
    self.resetInterval = resetInterval
    self.workspaceID = workspaceID
  }
  enum CodingKeys: String, CodingKey {
    case allowSafetyRetentionGoogle = "allow_safety_retention_google"
    case allowSafetyRetentionOther = "allow_safety_retention_other"
    case allowedDataRegions = "allowed_data_regions"
    case allowedModels = "allowed_models"
    case allowedProviders = "allowed_providers"
    case contentFilterBuiltins = "content_filter_builtins"
    case contentFilters = "content_filters"
    case description
    case enableFreeModelPublication = "enable_free_model_publication"
    case enableFreeModelTraining = "enable_free_model_training"
    case enablePaidModelTraining = "enable_paid_model_training"
    case enforceFirstPartyHarnessModels = "enforce_first_party_harness_models"
    case enforceZDR = "enforce_zdr"
    case enforceZDRAnthropic = "enforce_zdr_anthropic"
    case enforceZDRGoogle = "enforce_zdr_google"
    case enforceZDROpenAI = "enforce_zdr_openai"
    case enforceZDROther = "enforce_zdr_other"
    case enforceZDRXAI = "enforce_zdr_xai"
    case ignoredModels = "ignored_models"
    case ignoredProviders = "ignored_providers"
    case includeBYOKInBudgets = "include_byok_in_budgets"
    case limitUSD = "limit_usd"
    case name
    case resetInterval = "reset_interval"
    case workspaceID = "workspace_id"
  }
}
/// UpdateGuardrailRequest
public struct UpdateGuardrailRequest: Encodable, Sendable, Equatable {
  /// Whether ZDR-only requests to google/* models may use endpoints that may retain prompts for safety monitoring. false allows only zero-retention endpoints. A guardrail can only be more restrictive than the account setting. Inherits the account setting when not provided.
  public var allowSafetyRetentionGoogle: GuardrailField<Bool>
  /// Whether ZDR-only requests to models outside the named providers (for example open-weight models on Vertex) may use endpoints that may retain prompts for safety monitoring. false allows only zero-retention endpoints. A guardrail can only be more restrictive than the account setting. Inherits the account setting when not provided.
  public var allowSafetyRetentionOther: GuardrailField<Bool>
  /// Data regions through which requests governed by this guardrail must arrive. `global` is https://openrouter.ai, `europe` is https://eu.openrouter.ai, and `us` is https://us.openrouter.ai. Requests arriving through any other region are rejected. `null` leaves the ingress region unrestricted. When several guardrails apply (workspace default, member, API key), the effective regions are the intersection of every non-null value. An empty array is rejected. Known regions: global, europe, us.
  public var allowedDataRegions: GuardrailField<[String]>
  /// Array of model identifiers (slug or canonical_slug accepted)
  public var allowedModels: GuardrailField<[String]>
  /// New list of allowed provider IDs
  public var allowedProviders: GuardrailField<[String]>
  /// Builtin content filters to apply. Set to null to remove. Every builtin slug supports "block", "redact", and the detect-only "flag" action.
  public var contentFilterBuiltins: GuardrailField<[ContentFilterBuiltinEntryInput]>
  /// Custom regex content filters to apply. Set to null to remove.
  public var contentFilters: GuardrailField<[ContentFilterEntry]>
  /// New description for the guardrail
  public var description: GuardrailField<String>
  /// Whether this guardrail allows free endpoints that publish prompts.
  public var enableFreeModelPublication: GuardrailField<Bool>
  /// Whether this guardrail allows free endpoints that train on request data.
  public var enableFreeModelTraining: GuardrailField<Bool>
  /// Whether this guardrail allows paid endpoints that train on request data.
  public var enablePaidModelTraining: GuardrailField<Bool>
  /// Whether coding harnesses list only their vendor's own models: Codex lists OpenAI models and Claude Code and Claude Desktop list Anthropic models. Affects only the model list those harnesses request from GET /models; a model the client names directly is still routed. Any true across the workspace default, member, and API key guardrails applies.
  public var enforceFirstPartyHarnessModels: GuardrailField<Bool>
  /// Deprecated. Use enforce_zdr_anthropic, enforce_zdr_openai, enforce_zdr_google, enforce_zdr_xai, and enforce_zdr_other instead. When provided, its value is copied into any of those per-provider fields that are not explicitly specified on the request.
  public var enforceZDR: GuardrailField<Bool>
  /// Whether to enforce zero data retention for Anthropic models. Falls back to enforce_zdr when not provided.
  public var enforceZDRAnthropic: GuardrailField<Bool>
  /// Whether to enforce zero data retention for Google models. Falls back to enforce_zdr when not provided.
  public var enforceZDRGoogle: GuardrailField<Bool>
  /// Whether to enforce zero data retention for OpenAI models. Falls back to enforce_zdr when not provided.
  public var enforceZDROpenAI: GuardrailField<Bool>
  /// Whether to enforce zero data retention for models that are not from Anthropic, OpenAI, Google, or xAI. Falls back to enforce_zdr when not provided.
  public var enforceZDROther: GuardrailField<Bool>
  /// Whether to enforce zero data retention for xAI models. Falls back to enforce_zdr when not provided.
  public var enforceZDRXAI: GuardrailField<Bool>
  /// Array of model identifiers to exclude from routing (slug or canonical_slug accepted)
  public var ignoredModels: GuardrailField<[String]>
  /// List of provider IDs to exclude from routing
  public var ignoredProviders: GuardrailField<[String]>
  /// Whether BYOK (bring-your-own-key) inference spend counts toward this guardrail's limit_usd, in addition to OpenRouter credit spend. Omit to leave unchanged.
  public var includeBYOKInBudgets: Bool?
  /// New spending limit in USD
  public var limitUSD: GuardrailField<Double>
  /// New name for the guardrail
  public var name: String?
  ///  Known values: daily, weekly, monthly.
  public var resetInterval: GuardrailField<String>
  public init(
    allowSafetyRetentionGoogle: GuardrailField<Bool> = .unchanged,
    allowSafetyRetentionOther: GuardrailField<Bool> = .unchanged,
    allowedDataRegions: GuardrailField<[String]> = .unchanged,
    allowedModels: GuardrailField<[String]> = .unchanged,
    allowedProviders: GuardrailField<[String]> = .unchanged,
    contentFilterBuiltins: GuardrailField<[ContentFilterBuiltinEntryInput]> = .unchanged,
    contentFilters: GuardrailField<[ContentFilterEntry]> = .unchanged,
    description: GuardrailField<String> = .unchanged,
    enableFreeModelPublication: GuardrailField<Bool> = .unchanged,
    enableFreeModelTraining: GuardrailField<Bool> = .unchanged,
    enablePaidModelTraining: GuardrailField<Bool> = .unchanged,
    enforceFirstPartyHarnessModels: GuardrailField<Bool> = .unchanged,
    enforceZDR: GuardrailField<Bool> = .unchanged,
    enforceZDRAnthropic: GuardrailField<Bool> = .unchanged,
    enforceZDRGoogle: GuardrailField<Bool> = .unchanged,
    enforceZDROpenAI: GuardrailField<Bool> = .unchanged,
    enforceZDROther: GuardrailField<Bool> = .unchanged,
    enforceZDRXAI: GuardrailField<Bool> = .unchanged,
    ignoredModels: GuardrailField<[String]> = .unchanged,
    ignoredProviders: GuardrailField<[String]> = .unchanged, includeBYOKInBudgets: Bool? = nil,
    limitUSD: GuardrailField<Double> = .unchanged, name: String? = nil,
    resetInterval: GuardrailField<String> = .unchanged
  ) {
    self.allowSafetyRetentionGoogle = allowSafetyRetentionGoogle
    self.allowSafetyRetentionOther = allowSafetyRetentionOther
    self.allowedDataRegions = allowedDataRegions
    self.allowedModels = allowedModels
    self.allowedProviders = allowedProviders
    self.contentFilterBuiltins = contentFilterBuiltins
    self.contentFilters = contentFilters
    self.description = description
    self.enableFreeModelPublication = enableFreeModelPublication
    self.enableFreeModelTraining = enableFreeModelTraining
    self.enablePaidModelTraining = enablePaidModelTraining
    self.enforceFirstPartyHarnessModels = enforceFirstPartyHarnessModels
    self.enforceZDR = enforceZDR
    self.enforceZDRAnthropic = enforceZDRAnthropic
    self.enforceZDRGoogle = enforceZDRGoogle
    self.enforceZDROpenAI = enforceZDROpenAI
    self.enforceZDROther = enforceZDROther
    self.enforceZDRXAI = enforceZDRXAI
    self.ignoredModels = ignoredModels
    self.ignoredProviders = ignoredProviders
    self.includeBYOKInBudgets = includeBYOKInBudgets
    self.limitUSD = limitUSD
    self.name = name
    self.resetInterval = resetInterval
  }
  enum CodingKeys: String, CodingKey {
    case allowSafetyRetentionGoogle = "allow_safety_retention_google"
    case allowSafetyRetentionOther = "allow_safety_retention_other"
    case allowedDataRegions = "allowed_data_regions"
    case allowedModels = "allowed_models"
    case allowedProviders = "allowed_providers"
    case contentFilterBuiltins = "content_filter_builtins"
    case contentFilters = "content_filters"
    case description
    case enableFreeModelPublication = "enable_free_model_publication"
    case enableFreeModelTraining = "enable_free_model_training"
    case enablePaidModelTraining = "enable_paid_model_training"
    case enforceFirstPartyHarnessModels = "enforce_first_party_harness_models"
    case enforceZDR = "enforce_zdr"
    case enforceZDRAnthropic = "enforce_zdr_anthropic"
    case enforceZDRGoogle = "enforce_zdr_google"
    case enforceZDROpenAI = "enforce_zdr_openai"
    case enforceZDROther = "enforce_zdr_other"
    case enforceZDRXAI = "enforce_zdr_xai"
    case ignoredModels = "ignored_models"
    case ignoredProviders = "ignored_providers"
    case includeBYOKInBudgets = "include_byok_in_budgets"
    case limitUSD = "limit_usd"
    case name
    case resetInterval = "reset_interval"
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    switch allowSafetyRetentionGoogle {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .allowSafetyRetentionGoogle)
    case .value(let value): try c.encode(value, forKey: .allowSafetyRetentionGoogle)
    }
    switch allowSafetyRetentionOther {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .allowSafetyRetentionOther)
    case .value(let value): try c.encode(value, forKey: .allowSafetyRetentionOther)
    }
    switch allowedDataRegions {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .allowedDataRegions)
    case .value(let value): try c.encode(value, forKey: .allowedDataRegions)
    }
    switch allowedModels {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .allowedModels)
    case .value(let value): try c.encode(value, forKey: .allowedModels)
    }
    switch allowedProviders {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .allowedProviders)
    case .value(let value): try c.encode(value, forKey: .allowedProviders)
    }
    switch contentFilterBuiltins {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .contentFilterBuiltins)
    case .value(let value): try c.encode(value, forKey: .contentFilterBuiltins)
    }
    switch contentFilters {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .contentFilters)
    case .value(let value): try c.encode(value, forKey: .contentFilters)
    }
    switch description {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .description)
    case .value(let value): try c.encode(value, forKey: .description)
    }
    switch enableFreeModelPublication {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .enableFreeModelPublication)
    case .value(let value): try c.encode(value, forKey: .enableFreeModelPublication)
    }
    switch enableFreeModelTraining {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .enableFreeModelTraining)
    case .value(let value): try c.encode(value, forKey: .enableFreeModelTraining)
    }
    switch enablePaidModelTraining {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .enablePaidModelTraining)
    case .value(let value): try c.encode(value, forKey: .enablePaidModelTraining)
    }
    switch enforceFirstPartyHarnessModels {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .enforceFirstPartyHarnessModels)
    case .value(let value): try c.encode(value, forKey: .enforceFirstPartyHarnessModels)
    }
    switch enforceZDR {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .enforceZDR)
    case .value(let value): try c.encode(value, forKey: .enforceZDR)
    }
    switch enforceZDRAnthropic {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .enforceZDRAnthropic)
    case .value(let value): try c.encode(value, forKey: .enforceZDRAnthropic)
    }
    switch enforceZDRGoogle {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .enforceZDRGoogle)
    case .value(let value): try c.encode(value, forKey: .enforceZDRGoogle)
    }
    switch enforceZDROpenAI {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .enforceZDROpenAI)
    case .value(let value): try c.encode(value, forKey: .enforceZDROpenAI)
    }
    switch enforceZDROther {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .enforceZDROther)
    case .value(let value): try c.encode(value, forKey: .enforceZDROther)
    }
    switch enforceZDRXAI {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .enforceZDRXAI)
    case .value(let value): try c.encode(value, forKey: .enforceZDRXAI)
    }
    switch ignoredModels {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .ignoredModels)
    case .value(let value): try c.encode(value, forKey: .ignoredModels)
    }
    switch ignoredProviders {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .ignoredProviders)
    case .value(let value): try c.encode(value, forKey: .ignoredProviders)
    }
    try c.encodeIfPresent(includeBYOKInBudgets, forKey: .includeBYOKInBudgets)
    switch limitUSD {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .limitUSD)
    case .value(let value): try c.encode(value, forKey: .limitUSD)
    }
    try c.encodeIfPresent(name, forKey: .name)
    switch resetInterval {
    case .unchanged: break
    case .null: try c.encodeNil(forKey: .resetInterval)
    case .value(let value): try c.encode(value, forKey: .resetInterval)
    }
  }
}
/// KeyAssignment
public struct KeyAssignment: Codable, Sendable, Equatable {
  /// User ID of who made the assignment
  public var assignedBy: String?
  /// ISO 8601 timestamp of when the assignment was created
  public var createdAt: String
  /// ID of the guardrail
  public var guardrailID: String
  /// Unique identifier for the assignment
  public var id: String
  /// Hash of the assigned API key
  public var keyHash: String
  /// Label of the API key
  public var keyLabel: String
  /// Name of the API key
  public var keyName: String
  public init(
    assignedBy: String? = nil, createdAt: String, guardrailID: String, id: String, keyHash: String,
    keyLabel: String, keyName: String
  ) {
    self.assignedBy = assignedBy
    self.createdAt = createdAt
    self.guardrailID = guardrailID
    self.id = id
    self.keyHash = keyHash
    self.keyLabel = keyLabel
    self.keyName = keyName
  }
  enum CodingKeys: String, CodingKey {
    case assignedBy = "assigned_by"
    case createdAt = "created_at"
    case guardrailID = "guardrail_id"
    case id
    case keyHash = "key_hash"
    case keyLabel = "key_label"
    case keyName = "key_name"
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(assignedBy, forKey: .assignedBy)
    try c.encode(createdAt, forKey: .createdAt)
    try c.encode(guardrailID, forKey: .guardrailID)
    try c.encode(id, forKey: .id)
    try c.encode(keyHash, forKey: .keyHash)
    try c.encode(keyLabel, forKey: .keyLabel)
    try c.encode(keyName, forKey: .keyName)
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    guard c.contains(.assignedBy) else {
      throw DecodingError.keyNotFound(
        CodingKeys.assignedBy,
        .init(codingPath: c.codingPath, debugDescription: "Missing required nullable field"))
    }
    assignedBy = try c.decodeIfPresent(String.self, forKey: .assignedBy)
    createdAt = try c.decode(String.self, forKey: .createdAt)
    guardrailID = try c.decode(String.self, forKey: .guardrailID)
    id = try c.decode(String.self, forKey: .id)
    keyHash = try c.decode(String.self, forKey: .keyHash)
    keyLabel = try c.decode(String.self, forKey: .keyLabel)
    keyName = try c.decode(String.self, forKey: .keyName)
  }
}
/// MemberAssignment
public struct MemberAssignment: Codable, Sendable, Equatable {
  /// User ID of who made the assignment
  public var assignedBy: String?
  /// ISO 8601 timestamp of when the assignment was created
  public var createdAt: String
  /// ID of the guardrail
  public var guardrailID: String
  /// Unique identifier for the assignment
  public var id: String
  /// Organization ID
  public var organizationID: String
  /// Clerk user ID of the assigned member
  public var userID: String
  public init(
    assignedBy: String? = nil, createdAt: String, guardrailID: String, id: String,
    organizationID: String, userID: String
  ) {
    self.assignedBy = assignedBy
    self.createdAt = createdAt
    self.guardrailID = guardrailID
    self.id = id
    self.organizationID = organizationID
    self.userID = userID
  }
  enum CodingKeys: String, CodingKey {
    case assignedBy = "assigned_by"
    case createdAt = "created_at"
    case guardrailID = "guardrail_id"
    case id
    case organizationID = "organization_id"
    case userID = "user_id"
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(assignedBy, forKey: .assignedBy)
    try c.encode(createdAt, forKey: .createdAt)
    try c.encode(guardrailID, forKey: .guardrailID)
    try c.encode(id, forKey: .id)
    try c.encode(organizationID, forKey: .organizationID)
    try c.encode(userID, forKey: .userID)
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    guard c.contains(.assignedBy) else {
      throw DecodingError.keyNotFound(
        CodingKeys.assignedBy,
        .init(codingPath: c.codingPath, debugDescription: "Missing required nullable field"))
    }
    assignedBy = try c.decodeIfPresent(String.self, forKey: .assignedBy)
    createdAt = try c.decode(String.self, forKey: .createdAt)
    guardrailID = try c.decode(String.self, forKey: .guardrailID)
    id = try c.decode(String.self, forKey: .id)
    organizationID = try c.decode(String.self, forKey: .organizationID)
    userID = try c.decode(String.self, forKey: .userID)
  }
}
/// CreateGuardrailResponse
public struct CreateGuardrailResponse: Codable, Sendable, Equatable {
  public var data: Guardrail
  public init(data: Guardrail) {
    self.data = data
  }
  enum CodingKeys: String, CodingKey {
    case data
  }
}
/// GetGuardrailResponse
public struct GetGuardrailResponse: Codable, Sendable, Equatable {
  public var data: Guardrail
  public init(data: Guardrail) {
    self.data = data
  }
  enum CodingKeys: String, CodingKey {
    case data
  }
}
/// UpdateGuardrailResponse
public struct UpdateGuardrailResponse: Codable, Sendable, Equatable {
  public var data: Guardrail
  public init(data: Guardrail) {
    self.data = data
  }
  enum CodingKeys: String, CodingKey {
    case data
  }
}
/// ListGuardrailsResponse
public struct ListGuardrailsResponse: Codable, Sendable, Equatable {
  /// List of guardrails
  public var data: [Guardrail]
  /// Total number of guardrails
  public var totalCount: Int
  public init(data: [Guardrail], totalCount: Int) {
    self.data = data
    self.totalCount = totalCount
  }
  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
}
/// ListKeyAssignmentsResponse
public struct ListKeyAssignmentsResponse: Codable, Sendable, Equatable {
  /// List of key assignments
  public var data: [KeyAssignment]
  /// Total number of key assignments for this guardrail
  public var totalCount: Int
  public init(data: [KeyAssignment], totalCount: Int) {
    self.data = data
    self.totalCount = totalCount
  }
  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
}
/// ListMemberAssignmentsResponse
public struct ListMemberAssignmentsResponse: Codable, Sendable, Equatable {
  /// List of member assignments
  public var data: [MemberAssignment]
  /// Total number of member assignments
  public var totalCount: Int
  public init(data: [MemberAssignment], totalCount: Int) {
    self.data = data
    self.totalCount = totalCount
  }
  enum CodingKeys: String, CodingKey {
    case data
    case totalCount = "total_count"
  }
}
/// Bulk mutations accept 1...500 nonempty identifiers; the server validates bounds.
public struct BulkAssignKeysRequest: Encodable, Sendable, Equatable {
  /// Array of API key hashes to assign to the guardrail
  public var keyHashes: [String]
  public init(keyHashes: [String]) {
    self.keyHashes = keyHashes
  }
  enum CodingKeys: String, CodingKey {
    case keyHashes = "key_hashes"
  }
}
/// Bulk mutations accept 1...500 nonempty identifiers; the server validates bounds.
public struct BulkUnassignKeysRequest: Encodable, Sendable, Equatable {
  /// Array of API key hashes to unassign from the guardrail
  public var keyHashes: [String]
  public init(keyHashes: [String]) {
    self.keyHashes = keyHashes
  }
  enum CodingKeys: String, CodingKey {
    case keyHashes = "key_hashes"
  }
}
/// Bulk mutations accept 1...500 nonempty identifiers; the server validates bounds.
public struct BulkAssignMembersRequest: Encodable, Sendable, Equatable {
  /// Array of member user IDs to assign to the guardrail
  public var memberUserIDs: [String]
  public init(memberUserIDs: [String]) {
    self.memberUserIDs = memberUserIDs
  }
  enum CodingKeys: String, CodingKey {
    case memberUserIDs = "member_user_ids"
  }
}
/// Bulk mutations accept 1...500 nonempty identifiers; the server validates bounds.
public struct BulkUnassignMembersRequest: Encodable, Sendable, Equatable {
  /// Array of member user IDs to unassign from the guardrail
  public var memberUserIDs: [String]
  public init(memberUserIDs: [String]) {
    self.memberUserIDs = memberUserIDs
  }
  enum CodingKeys: String, CodingKey {
    case memberUserIDs = "member_user_ids"
  }
}
/// BulkAssignKeysResponse
public struct BulkAssignKeysResponse: Codable, Sendable, Equatable {
  /// Number of keys successfully assigned
  public var assignedCount: Int
  public init(assignedCount: Int) {
    self.assignedCount = assignedCount
  }
  enum CodingKeys: String, CodingKey {
    case assignedCount = "assigned_count"
  }
}
/// BulkUnassignKeysResponse
public struct BulkUnassignKeysResponse: Codable, Sendable, Equatable {
  /// Number of keys successfully unassigned
  public var unassignedCount: Int
  public init(unassignedCount: Int) {
    self.unassignedCount = unassignedCount
  }
  enum CodingKeys: String, CodingKey {
    case unassignedCount = "unassigned_count"
  }
}
/// BulkAssignMembersResponse
public struct BulkAssignMembersResponse: Codable, Sendable, Equatable {
  /// Number of members successfully assigned
  public var assignedCount: Int
  public init(assignedCount: Int) {
    self.assignedCount = assignedCount
  }
  enum CodingKeys: String, CodingKey {
    case assignedCount = "assigned_count"
  }
}
/// BulkUnassignMembersResponse
public struct BulkUnassignMembersResponse: Codable, Sendable, Equatable {
  /// Number of members successfully unassigned
  public var unassignedCount: Int
  public init(unassignedCount: Int) {
    self.unassignedCount = unassignedCount
  }
  enum CodingKeys: String, CodingKey {
    case unassignedCount = "unassigned_count"
  }
}
/// Successful deletion is always confirmed with `deleted: true`.
public struct DeleteGuardrailResponse: Codable, Sendable, Equatable {
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
