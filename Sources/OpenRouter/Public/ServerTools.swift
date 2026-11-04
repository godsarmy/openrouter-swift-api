// Server-tool catalog models. String values remain open to future server additions.

public struct ServerTool: Codable, Sendable, Equatable {
  public var aliases: [ServerToolInputName]
  public var defaultEngine: String?
  public var docsURL: String
  public var engines: [ServerToolEngine]
  public var fallbackEngine: String?
  public var id: String
  /// JSON Schema for arguments emitted by the model.
  public var inputSchema: [String: JSONValue]
  public var name: String
  public var nativeSupport: ServerToolNativeSupport
  public var outputSchema: [String: JSONValue]?
  /// JSON Schema for caller-side `tools[].parameters`.
  public var parametersSchema: [String: JSONValue]
  public var status: String
  public var summary: String
  public var supportedAPIFormats: [String]
  public var toolDescription: String
  public init(
    aliases: [ServerToolInputName], defaultEngine: String?, docsURL: String,
    engines: [ServerToolEngine], fallbackEngine: String?, id: String,
    inputSchema: [String: JSONValue], name: String, nativeSupport: ServerToolNativeSupport,
    outputSchema: [String: JSONValue]?, parametersSchema: [String: JSONValue], status: String,
    summary: String, supportedAPIFormats: [String], toolDescription: String
  ) {
    self.aliases = aliases
    self.defaultEngine = defaultEngine
    self.docsURL = docsURL
    self.engines = engines
    self.fallbackEngine = fallbackEngine
    self.id = id
    self.inputSchema = inputSchema
    self.name = name
    self.nativeSupport = nativeSupport
    self.outputSchema = outputSchema
    self.parametersSchema = parametersSchema
    self.status = status
    self.summary = summary
    self.supportedAPIFormats = supportedAPIFormats
    self.toolDescription = toolDescription
  }
  enum CodingKeys: String, CodingKey {
    case aliases
    case defaultEngine = "default_engine"
    case docsURL = "docs_url"
    case engines
    case fallbackEngine = "fallback_engine"
    case id
    case inputSchema = "input_schema"
    case name
    case nativeSupport = "native_support"
    case outputSchema = "output_schema"
    case parametersSchema = "parameters_schema"
    case status
    case summary
    case supportedAPIFormats = "supported_api_formats"
    case toolDescription = "tool_description"
  }
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    aliases = try container.decode([ServerToolInputName].self, forKey: .aliases)
    defaultEngine = try container.decode(String?.self, forKey: .defaultEngine)
    docsURL = try container.decode(String.self, forKey: .docsURL)
    engines = try container.decode([ServerToolEngine].self, forKey: .engines)
    fallbackEngine = try container.decode(String?.self, forKey: .fallbackEngine)
    id = try container.decode(String.self, forKey: .id)
    inputSchema = try container.decode([String: JSONValue].self, forKey: .inputSchema)
    name = try container.decode(String.self, forKey: .name)
    nativeSupport = try container.decode(ServerToolNativeSupport.self, forKey: .nativeSupport)
    outputSchema = try container.decode([String: JSONValue]?.self, forKey: .outputSchema)
    parametersSchema = try container.decode([String: JSONValue].self, forKey: .parametersSchema)
    status = try container.decode(String.self, forKey: .status)
    summary = try container.decode(String.self, forKey: .summary)
    supportedAPIFormats = try container.decode([String].self, forKey: .supportedAPIFormats)
    toolDescription = try container.decode(String.self, forKey: .toolDescription)
  }
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(aliases, forKey: .aliases)
    try container.encode(defaultEngine, forKey: .defaultEngine)
    try container.encode(docsURL, forKey: .docsURL)
    try container.encode(engines, forKey: .engines)
    try container.encode(fallbackEngine, forKey: .fallbackEngine)
    try container.encode(id, forKey: .id)
    try container.encode(inputSchema, forKey: .inputSchema)
    try container.encode(name, forKey: .name)
    try container.encode(nativeSupport, forKey: .nativeSupport)
    try container.encode(outputSchema, forKey: .outputSchema)
    try container.encode(parametersSchema, forKey: .parametersSchema)
    try container.encode(status, forKey: .status)
    try container.encode(summary, forKey: .summary)
    try container.encode(supportedAPIFormats, forKey: .supportedAPIFormats)
    try container.encode(toolDescription, forKey: .toolDescription)
  }
}

public struct ServerToolDetails: Codable, Sendable, Equatable {
  public var aliases: [ServerToolInputName]
  public var defaultEngine: String?
  public var docsURL: String
  public var engines: [ServerToolEngine]
  public var fallbackEngine: String?
  public var id: String
  /// JSON Schema for arguments emitted by the model.
  public var inputSchema: [String: JSONValue]
  public var name: String
  public var nativeSupport: ServerToolNativeSupportDetails
  public var outputSchema: [String: JSONValue]?
  /// JSON Schema for caller-side `tools[].parameters`.
  public var parametersSchema: [String: JSONValue]
  public var status: String
  public var summary: String
  public var supportedAPIFormats: [String]
  public var toolDescription: String
  public init(
    aliases: [ServerToolInputName], defaultEngine: String?, docsURL: String,
    engines: [ServerToolEngine], fallbackEngine: String?, id: String,
    inputSchema: [String: JSONValue], name: String, nativeSupport: ServerToolNativeSupportDetails,
    outputSchema: [String: JSONValue]?, parametersSchema: [String: JSONValue], status: String,
    summary: String, supportedAPIFormats: [String], toolDescription: String
  ) {
    self.aliases = aliases
    self.defaultEngine = defaultEngine
    self.docsURL = docsURL
    self.engines = engines
    self.fallbackEngine = fallbackEngine
    self.id = id
    self.inputSchema = inputSchema
    self.name = name
    self.nativeSupport = nativeSupport
    self.outputSchema = outputSchema
    self.parametersSchema = parametersSchema
    self.status = status
    self.summary = summary
    self.supportedAPIFormats = supportedAPIFormats
    self.toolDescription = toolDescription
  }
  enum CodingKeys: String, CodingKey {
    case aliases
    case defaultEngine = "default_engine"
    case docsURL = "docs_url"
    case engines
    case fallbackEngine = "fallback_engine"
    case id
    case inputSchema = "input_schema"
    case name
    case nativeSupport = "native_support"
    case outputSchema = "output_schema"
    case parametersSchema = "parameters_schema"
    case status
    case summary
    case supportedAPIFormats = "supported_api_formats"
    case toolDescription = "tool_description"
  }
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    aliases = try container.decode([ServerToolInputName].self, forKey: .aliases)
    defaultEngine = try container.decode(String?.self, forKey: .defaultEngine)
    docsURL = try container.decode(String.self, forKey: .docsURL)
    engines = try container.decode([ServerToolEngine].self, forKey: .engines)
    fallbackEngine = try container.decode(String?.self, forKey: .fallbackEngine)
    id = try container.decode(String.self, forKey: .id)
    inputSchema = try container.decode([String: JSONValue].self, forKey: .inputSchema)
    name = try container.decode(String.self, forKey: .name)
    nativeSupport = try container.decode(
      ServerToolNativeSupportDetails.self, forKey: .nativeSupport)
    outputSchema = try container.decode([String: JSONValue]?.self, forKey: .outputSchema)
    parametersSchema = try container.decode([String: JSONValue].self, forKey: .parametersSchema)
    status = try container.decode(String.self, forKey: .status)
    summary = try container.decode(String.self, forKey: .summary)
    supportedAPIFormats = try container.decode([String].self, forKey: .supportedAPIFormats)
    toolDescription = try container.decode(String.self, forKey: .toolDescription)
  }
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(aliases, forKey: .aliases)
    try container.encode(defaultEngine, forKey: .defaultEngine)
    try container.encode(docsURL, forKey: .docsURL)
    try container.encode(engines, forKey: .engines)
    try container.encode(fallbackEngine, forKey: .fallbackEngine)
    try container.encode(id, forKey: .id)
    try container.encode(inputSchema, forKey: .inputSchema)
    try container.encode(name, forKey: .name)
    try container.encode(nativeSupport, forKey: .nativeSupport)
    try container.encode(outputSchema, forKey: .outputSchema)
    try container.encode(parametersSchema, forKey: .parametersSchema)
    try container.encode(status, forKey: .status)
    try container.encode(summary, forKey: .summary)
    try container.encode(supportedAPIFormats, forKey: .supportedAPIFormats)
    try container.encode(toolDescription, forKey: .toolDescription)
  }
}

public struct ServerToolEngine: Codable, Sendable, Equatable {
  public var byok: String
  public var dataRegions: [String]
  public var defaultMode: String?
  public var executedBy: String
  public var id: String?
  public var name: String
  public var pricing: [ServerToolPrice]
  public var pricingDocUrl: String?
  public var pricingSource: String
  public init(
    byok: String, dataRegions: [String], defaultMode: String?, executedBy: String,
    id: String?, name: String, pricing: [ServerToolPrice], pricingDocUrl: String?,
    pricingSource: String
  ) {
    self.byok = byok
    self.dataRegions = dataRegions
    self.defaultMode = defaultMode
    self.executedBy = executedBy
    self.id = id
    self.name = name
    self.pricing = pricing
    self.pricingDocUrl = pricingDocUrl
    self.pricingSource = pricingSource
  }
  enum CodingKeys: String, CodingKey {
    case byok
    case dataRegions = "data_regions"
    case defaultMode = "default_mode"
    case executedBy = "executed_by"
    case id
    case name
    case pricing
    case pricingDocUrl = "pricing_doc_url"
    case pricingSource = "pricing_source"
  }
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    byok = try container.decode(String.self, forKey: .byok)
    dataRegions = try container.decode([String].self, forKey: .dataRegions)
    defaultMode = try container.decode(String?.self, forKey: .defaultMode)
    executedBy = try container.decode(String.self, forKey: .executedBy)
    id = try container.decode(String?.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    pricing = try container.decode([ServerToolPrice].self, forKey: .pricing)
    pricingDocUrl = try container.decode(String?.self, forKey: .pricingDocUrl)
    pricingSource = try container.decode(String.self, forKey: .pricingSource)
  }
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(byok, forKey: .byok)
    try container.encode(dataRegions, forKey: .dataRegions)
    try container.encode(defaultMode, forKey: .defaultMode)
    try container.encode(executedBy, forKey: .executedBy)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(pricing, forKey: .pricing)
    try container.encode(pricingDocUrl, forKey: .pricingDocUrl)
    try container.encode(pricingSource, forKey: .pricingSource)
  }
}

public struct ServerToolInputName: Codable, Sendable, Equatable {
  public var apiFormats: [String]
  public var outputNames: [ServerToolOutputName]
  public var type: String
  public init(apiFormats: [String], outputNames: [ServerToolOutputName], type: String) {
    self.apiFormats = apiFormats
    self.outputNames = outputNames
    self.type = type
  }
  enum CodingKeys: String, CodingKey {
    case apiFormats = "api_formats"
    case outputNames = "output_names"
    case type
  }
}

public struct ServerToolNativeModel: Codable, Sendable, Equatable {
  public var providers: [String]
  public var slug: String
  public init(providers: [String], slug: String) {
    self.providers = providers
    self.slug = slug
  }
  enum CodingKeys: String, CodingKey {
    case providers
    case slug
  }
}

public struct ServerToolNativeSupport: Codable, Sendable, Equatable {
  public var endpointCount: Int
  public var modelCount: Int
  public init(endpointCount: Int, modelCount: Int) {
    self.endpointCount = endpointCount
    self.modelCount = modelCount
  }
  enum CodingKeys: String, CodingKey {
    case endpointCount = "endpoint_count"
    case modelCount = "model_count"
  }
}

public struct ServerToolNativeSupportDetails: Codable, Sendable, Equatable {
  public var endpointCount: Int
  public var modelCount: Int
  public var models: [ServerToolNativeModel]
  public init(endpointCount: Int, modelCount: Int, models: [ServerToolNativeModel]) {
    self.endpointCount = endpointCount
    self.modelCount = modelCount
    self.models = models
  }
  enum CodingKeys: String, CodingKey {
    case endpointCount = "endpoint_count"
    case modelCount = "model_count"
    case models
  }
}

public struct ServerToolOutputName: Codable, Sendable, Equatable {
  public var apiFormat: String
  public var name: String?
  public var type: String
  public init(apiFormat: String, name: String? = nil, type: String) {
    self.apiFormat = apiFormat
    self.name = name
    self.type = type
  }
  enum CodingKeys: String, CodingKey {
    case apiFormat = "api_format"
    case name
    case type
  }
}

public struct ServerToolPrice: Codable, Sendable, Equatable {
  public var maxUnitsPerCall: Int
  public var mode: String?
  /// USD per unit, retained as a decimal string to preserve precision.
  public var price: String
  public var unit: String
  public init(maxUnitsPerCall: Int, mode: String?, price: String, unit: String) {
    self.maxUnitsPerCall = maxUnitsPerCall
    self.mode = mode
    self.price = price
    self.unit = unit
  }
  enum CodingKeys: String, CodingKey {
    case maxUnitsPerCall = "max_units_per_call"
    case mode
    case price
    case unit
  }
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    maxUnitsPerCall = try container.decode(Int.self, forKey: .maxUnitsPerCall)
    mode = try container.decode(String?.self, forKey: .mode)
    price = try container.decode(String.self, forKey: .price)
    unit = try container.decode(String.self, forKey: .unit)
  }
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(maxUnitsPerCall, forKey: .maxUnitsPerCall)
    try container.encode(mode, forKey: .mode)
    try container.encode(price, forKey: .price)
    try container.encode(unit, forKey: .unit)
  }
}

public struct ServerToolPaginationLinks: Codable, Sendable, Equatable {
  public var next: String?
  public init(next: String?) {
    self.next = next
  }
  enum CodingKeys: String, CodingKey {
    case next
  }
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    next = try container.decode(String?.self, forKey: .next)
  }
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(next, forKey: .next)
  }
}

public struct ListToolsResponse: Codable, Sendable, Equatable {
  public var data: [ServerTool]
  public var links: ServerToolPaginationLinks
  public var totalCount: Int
  public init(data: [ServerTool], links: ServerToolPaginationLinks, totalCount: Int) {
    self.data = data
    self.links = links
    self.totalCount = totalCount
  }
  enum CodingKeys: String, CodingKey {
    case data
    case links
    case totalCount = "total_count"
  }
}

public struct GetToolResponse: Codable, Sendable, Equatable {
  public var data: ServerToolDetails
  public init(data: ServerToolDetails) {
    self.data = data
  }
  enum CodingKeys: String, CodingKey {
    case data
  }
}
