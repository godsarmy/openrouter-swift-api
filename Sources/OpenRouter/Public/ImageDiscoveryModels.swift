import Foundation

/// Image modalities remain open strings to accommodate future capabilities.
public struct ImageModelArchitecture: Codable, Sendable, Equatable {
  public var inputModalities: [String]
  public var outputModalities: [String]

  private enum CodingKeys: String, CodingKey {
    case inputModalities = "input_modalities"
    case outputModalities = "output_modalities"
  }

  public init(inputModalities: [String], outputModalities: [String]) {
    self.inputModalities = inputModalities
    self.outputModalities = outputModalities
  }

  fileprivate var payload: JSONValue {
    .object([
      "input_modalities": .array(inputModalities.map(JSONValue.string)),
      "output_modalities": .array(outputModalities.map(JSONValue.string)),
    ])
  }
}

public struct ImageModelListItem: Codable, Sendable, Equatable {
  public var id: String
  public var name: String
  public var description: String
  /// Unix timestamp in seconds.
  public var created: Int
  public var architecture: ImageModelArchitecture
  /// Coarse union across endpoints; endpoint records provide definitive capabilities.
  /// Descriptor types and extension keys are preserved as open JSON.
  public var supportedParameters: [String: JSONValue]
  /// Upstream native SSE capability across endpoints, not SDK generation support.
  public var supportsStreaming: Bool
  /// Relative URL metadata only; reading this value does not fetch endpoint records.
  public var endpoints: String

  private enum CodingKeys: String, CodingKey {
    case id, name, description, created, architecture, endpoints
    case supportedParameters = "supported_parameters"
    case supportsStreaming = "supports_streaming"
  }

  public init(
    id: String, name: String, description: String, created: Int,
    architecture: ImageModelArchitecture, supportedParameters: [String: JSONValue],
    supportsStreaming: Bool, endpoints: String
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.created = created
    self.architecture = architecture
    self.supportedParameters = supportedParameters
    self.supportsStreaming = supportsStreaming
    self.endpoints = endpoints
  }

  fileprivate var payload: JSONValue {
    .object([
      "id": .string(id), "name": .string(name), "description": .string(description),
      "created": .number(Double(created)), "architecture": architecture.payload,
      "supported_parameters": .object(supportedParameters),
      "supports_streaming": .bool(supportsStreaming), "endpoints": .string(endpoints),
    ])
  }
}

/// Pricing billables and units remain open strings for future upstream values.
public struct ImagePricingEntry: Codable, Sendable, Equatable {
  public var billable: String
  public var unit: String
  public var costUSD: Double
  public var variant: String?

  private enum CodingKeys: String, CodingKey {
    case billable, unit, variant
    case costUSD = "cost_usd"
  }

  public init(billable: String, unit: String, costUSD: Double, variant: String? = nil) {
    self.billable = billable
    self.unit = unit
    self.costUSD = costUSD
    self.variant = variant
  }

  fileprivate var payload: JSONValue {
    var fields: [String: JSONValue] = [
      "billable": .string(billable), "unit": .string(unit), "cost_usd": .number(costUSD),
    ]
    if let variant { fields["variant"] = .string(variant) }
    return .object(fields)
  }
}

public struct ImageEndpoint: Codable, Sendable, Equatable {
  public var providerName: String
  public var providerSlug: String
  public var providerTag: String?
  /// Definitive capabilities for this endpoint, including unknown descriptor extensions.
  public var supportedParameters: [String: JSONValue]
  public var allowedPassthroughParameters: [String]
  /// Upstream native SSE capability, not an SDK image-generation implementation.
  public var supportsStreaming: Bool
  public var pricing: [ImagePricingEntry]

  private enum CodingKeys: String, CodingKey {
    case pricing
    case providerName = "provider_name"
    case providerSlug = "provider_slug"
    case providerTag = "provider_tag"
    case supportedParameters = "supported_parameters"
    case allowedPassthroughParameters = "allowed_passthrough_parameters"
    case supportsStreaming = "supports_streaming"
  }

  public init(
    providerName: String, providerSlug: String, providerTag: String? = nil,
    supportedParameters: [String: JSONValue], allowedPassthroughParameters: [String],
    supportsStreaming: Bool, pricing: [ImagePricingEntry]
  ) {
    self.providerName = providerName
    self.providerSlug = providerSlug
    self.providerTag = providerTag
    self.supportedParameters = supportedParameters
    self.allowedPassthroughParameters = allowedPassthroughParameters
    self.supportsStreaming = supportsStreaming
    self.pricing = pricing
  }

  fileprivate var payload: JSONValue {
    .object([
      "provider_name": .string(providerName), "provider_slug": .string(providerSlug),
      "provider_tag": providerTag.map(JSONValue.string) ?? .null,
      "supported_parameters": .object(supportedParameters),
      "allowed_passthrough_parameters": .array(allowedPassthroughParameters.map(JSONValue.string)),
      "supports_streaming": .bool(supportsStreaming), "pricing": .array(pricing.map(\.payload)),
    ])
  }
}

/// Encoding preserves the authoritative raw payload, including nested extensions.
/// Mutating typed fields does not rebuild `rawPayload`.
public struct ImageModelsListResponse: Codable, Sendable, Equatable {
  public var data: [ImageModelListItem]
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey { case data }

  public init(data: [ImageModelListItem], rawPayload: JSONValue? = nil) {
    self.data = data
    self.rawPayload = rawPayload ?? .object(["data": .array(data.map(\.payload))])
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    data = try container.decode([ImageModelListItem].self, forKey: .data)
  }

  public func encode(to encoder: Encoder) throws {
    try rawPayload.encode(to: encoder)
  }
}

/// Encoding preserves the authoritative raw payload, including nested extensions.
/// Mutating typed fields does not rebuild `rawPayload`.
public struct ImageModelEndpointsResponse: Codable, Sendable, Equatable {
  public var id: String
  public var endpoints: [ImageEndpoint]
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey { case id, endpoints }

  public init(id: String, endpoints: [ImageEndpoint], rawPayload: JSONValue? = nil) {
    self.id = id
    self.endpoints = endpoints
    self.rawPayload =
      rawPayload
      ?? .object([
        "id": .string(id), "endpoints": .array(endpoints.map(\.payload)),
      ])
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    endpoints = try container.decode([ImageEndpoint].self, forKey: .endpoints)
  }

  public func encode(to encoder: Encoder) throws {
    try rawPayload.encode(to: encoder)
  }
}
