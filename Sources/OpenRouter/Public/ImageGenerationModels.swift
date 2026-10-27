import Foundation

/// Non-streaming image generation. Open strings and server-validated dimensions are intentional.
public struct ImageGenerationRequest: Codable, Sendable, Equatable {
  public var model: String
  public var prompt: String
  public var aspectRatio: String?
  public var background: String?
  public var inputReferences: [ImageGenerationReference]?
  public var n: Int?
  public var outputCompression: Int?
  public var outputFormat: String?
  public var provider: ImageGenerationProviderPreferences?
  public var quality: String?
  public var resolution: String?
  public var seed: Int?
  public var sessionID: String?
  public var size: String?
  /// Known trace keys and future metadata are passed through without schema validation.
  public var trace: [String: JSONValue]?
  public var user: String?
  public var stream: Bool { false }

  private enum CodingKeys: String, CodingKey {
    case model, prompt, background, n, provider, quality, resolution, seed, size, trace, user,
      stream
    case aspectRatio = "aspect_ratio"
    case inputReferences = "input_references"
    case outputCompression = "output_compression"
    case outputFormat = "output_format"
    case sessionID = "session_id"
  }

  public init(
    model: String, prompt: String, aspectRatio: String? = nil, background: String? = nil,
    inputReferences: [ImageGenerationReference]? = nil, n: Int? = nil,
    outputCompression: Int? = nil, outputFormat: String? = nil,
    provider: ImageGenerationProviderPreferences? = nil, quality: String? = nil,
    resolution: String? = nil, seed: Int? = nil, sessionID: String? = nil,
    size: String? = nil, trace: [String: JSONValue]? = nil, user: String? = nil
  ) {
    self.model = model
    self.prompt = prompt
    self.aspectRatio = aspectRatio
    self.background = background
    self.inputReferences = inputReferences
    self.n = n
    self.outputCompression = outputCompression
    self.outputFormat = outputFormat
    self.provider = provider
    self.quality = quality
    self.resolution = resolution
    self.seed = seed
    self.sessionID = sessionID
    self.size = size
    self.trace = trace
    self.user = user
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    if c.contains(.stream), try c.decode(Bool.self, forKey: .stream) {
      throw DecodingError.dataCorruptedError(
        forKey: .stream, in: c, debugDescription: "Image generation requires stream=false")
    }
    model = try c.decode(String.self, forKey: .model)
    prompt = try c.decode(String.self, forKey: .prompt)
    aspectRatio = try c.decodeIfPresent(String.self, forKey: .aspectRatio)
    background = try c.decodeIfPresent(String.self, forKey: .background)
    inputReferences = try c.decodeIfPresent(
      [ImageGenerationReference].self, forKey: .inputReferences)
    n = try c.decodeIfPresent(Int.self, forKey: .n)
    outputCompression = try c.decodeIfPresent(Int.self, forKey: .outputCompression)
    outputFormat = try c.decodeIfPresent(String.self, forKey: .outputFormat)
    provider = try c.decodeIfPresent(ImageGenerationProviderPreferences.self, forKey: .provider)
    quality = try c.decodeIfPresent(String.self, forKey: .quality)
    resolution = try c.decodeIfPresent(String.self, forKey: .resolution)
    seed = try c.decodeIfPresent(Int.self, forKey: .seed)
    sessionID = try c.decodeIfPresent(String.self, forKey: .sessionID)
    size = try c.decodeIfPresent(String.self, forKey: .size)
    trace = try c.decodeIfPresent([String: JSONValue].self, forKey: .trace)
    user = try c.decodeIfPresent(String.self, forKey: .user)
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(model, forKey: .model)
    try c.encode(prompt, forKey: .prompt)
    try c.encode(false, forKey: .stream)
    try c.encodeIfPresent(aspectRatio, forKey: .aspectRatio)
    try c.encodeIfPresent(background, forKey: .background)
    try c.encodeIfPresent(inputReferences, forKey: .inputReferences)
    try c.encodeIfPresent(n, forKey: .n)
    try c.encodeIfPresent(outputCompression, forKey: .outputCompression)
    try c.encodeIfPresent(outputFormat, forKey: .outputFormat)
    try c.encodeIfPresent(provider, forKey: .provider)
    try c.encodeIfPresent(quality, forKey: .quality)
    try c.encodeIfPresent(resolution, forKey: .resolution)
    try c.encodeIfPresent(seed, forKey: .seed)
    try c.encodeIfPresent(sessionID, forKey: .sessionID)
    try c.encodeIfPresent(size, forKey: .size)
    try c.encodeIfPresent(trace, forKey: .trace)
    try c.encodeIfPresent(user, forKey: .user)
  }
}

/// An opaque HTTP(S) or data URL. No fetching or image decoding is performed.
public struct ImageGenerationReference: Codable, Sendable, Equatable {
  public var url: String
  public init(url: String) { self.url = url }
  private enum CodingKeys: String, CodingKey {
    case type
    case imageURL = "image_url"
  }
  private struct ImageURL: Codable { var url: String }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    guard try c.decode(String.self, forKey: .type) == "image_url" else {
      throw DecodingError.dataCorruptedError(
        forKey: .type, in: c, debugDescription: "Expected image_url reference")
    }
    url = try c.decode(ImageURL.self, forKey: .imageURL).url
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode("image_url", forKey: .type)
    try c.encode(ImageURL(url: url), forKey: .imageURL)
  }
}

public struct ImageGenerationProviderPreferences: Codable, Sendable, Equatable {
  public var only: [String]?
  public var ignore: [String]?
  public var order: [String]?
  public var allowFallbacks: Bool?
  public var sort: JSONValue?
  /// Provider slugs and passthrough options remain open; the server may drop unknown options.
  public var options: [String: [String: JSONValue]]?

  private enum CodingKeys: String, CodingKey {
    case only, ignore, order, sort, options
    case allowFallbacks = "allow_fallbacks"
  }

  public init(
    only: [String]? = nil, ignore: [String]? = nil, order: [String]? = nil,
    allowFallbacks: Bool? = nil, sort: JSONValue? = nil,
    options: [String: [String: JSONValue]]? = nil
  ) {
    self.only = only
    self.ignore = ignore
    self.order = order
    self.allowFallbacks = allowFallbacks
    self.sort = sort
    self.options = options
  }
}

/// Opaque base64 text, including SVG markup; no base64 decoding is performed.
public struct ImageGenerationImage: Codable, Sendable, Equatable {
  public var b64JSON: String
  public var mediaType: String?
  private enum CodingKeys: String, CodingKey {
    case b64JSON = "b64_json"
    case mediaType = "media_type"
  }

  public init(b64JSON: String, mediaType: String? = nil) {
    self.b64JSON = b64JSON
    self.mediaType = mediaType
  }

  fileprivate var payload: JSONValue {
    var fields: [String: JSONValue] = ["b64_json": .string(b64JSON)]
    if let mediaType { fields["media_type"] = .string(mediaType) }
    return .object(fields)
  }
}

/// Additional usage details are retained in `rawPayload`, which is authoritative for encoding.
/// Mutating typed fields does not rebuild the raw payload.
public struct ImageGenerationUsage: Codable, Sendable, Equatable {
  public var promptTokens: Int
  public var completionTokens: Int
  public var totalTokens: Int
  public var cost: Double?
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey {
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case totalTokens = "total_tokens"
    case cost
  }

  public init(
    promptTokens: Int, completionTokens: Int, totalTokens: Int, cost: Double? = nil,
    rawPayload: JSONValue? = nil
  ) {
    self.promptTokens = promptTokens
    self.completionTokens = completionTokens
    self.totalTokens = totalTokens
    self.cost = cost
    var fields: [String: JSONValue] = [
      "prompt_tokens": .number(Double(promptTokens)),
      "completion_tokens": .number(Double(completionTokens)),
      "total_tokens": .number(Double(totalTokens)),
    ]
    if let cost { fields["cost"] = .number(cost) }
    self.rawPayload = rawPayload ?? .object(fields)
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    promptTokens = try c.decode(Int.self, forKey: .promptTokens)
    completionTokens = try c.decode(Int.self, forKey: .completionTokens)
    totalTokens = try c.decode(Int.self, forKey: .totalTokens)
    cost = try c.decodeIfPresent(Double.self, forKey: .cost)
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}

/// Encoding preserves the authoritative raw payload, including nested image extensions.
/// Mutating typed fields does not rebuild `rawPayload`.
public struct ImageGenerationResponse: Codable, Sendable, Equatable {
  public var created: Int
  public var data: [ImageGenerationImage]
  public var usage: ImageGenerationUsage?
  public var rawPayload: JSONValue
  private enum CodingKeys: String, CodingKey { case created, data, usage }

  public init(
    created: Int, data: [ImageGenerationImage], usage: ImageGenerationUsage? = nil,
    rawPayload: JSONValue? = nil
  ) {
    self.created = created
    self.data = data
    self.usage = usage
    var fields: [String: JSONValue] = [
      "created": .number(Double(created)), "data": .array(data.map(\.payload)),
    ]
    if let usage { fields["usage"] = usage.rawPayload }
    self.rawPayload = rawPayload ?? .object(fields)
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    created = try c.decode(Int.self, forKey: .created)
    data = try c.decode([ImageGenerationImage].self, forKey: .data)
    usage = try c.decodeIfPresent(ImageGenerationUsage.self, forKey: .usage)
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}
