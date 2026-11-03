import Foundation

public struct RerankRequest: Codable, Sendable, Equatable {
  public var model: String
  public var query: String
  public var documents: [RerankDocument]
  public var topN: Int?
  public var provider: ProviderPreferences?
  enum CodingKeys: String, CodingKey {
    case model, query, documents
    case topN = "top_n"
    case provider
  }
  public init(
    model: String, query: String, documents: [RerankDocument], topN: Int? = nil,
    provider: ProviderPreferences? = nil
  ) {
    self.model = model
    self.query = query
    self.documents = documents
    self.topN = topN
    self.provider = provider
  }
}

public enum RerankDocument: Codable, Sendable, Equatable {
  case text(String)
  case object(RerankDocumentObject)
  public init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if let text = try? c.decode(String.self) {
      self = .text(text)
    } else {
      self = .object(try c.decode(RerankDocumentObject.self))
    }
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .text(let value): try c.encode(value)
    case .object(let value): try c.encode(value)
    }
  }
}
public struct RerankDocumentObject: Codable, Sendable, Equatable {
  public var text: String?
  public var image: String?
  public var rawPayload: JSONValue?
  public init(text: String? = nil, image: String? = nil) {
    self.text = text
    self.image = image
    rawPayload = nil
  }
  enum CodingKeys: String, CodingKey { case text, image }
  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    text = try c.decodeIfPresent(String.self, forKey: .text)
    image = try c.decodeIfPresent(String.self, forKey: .image)
  }
  public func encode(to encoder: Encoder) throws {
    if let rawPayload {
      try rawPayload.encode(to: encoder)
    } else {
      var c = encoder.container(keyedBy: CodingKeys.self)
      try c.encodeIfPresent(text, forKey: .text)
      try c.encodeIfPresent(image, forKey: .image)
    }
  }
}
public struct RerankResponse: Codable, Sendable, Equatable {
  public var model: String?
  public var results: [RerankResult]
  public var id: String?
  public var provider: JSONValue?
  public var usage: RerankUsage?
  public var rawPayload: JSONValue
  enum CodingKeys: String, CodingKey { case model, results, id, provider, usage }
  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    model = try c.decodeIfPresent(String.self, forKey: .model)
    results = try c.decode([RerankResult].self, forKey: .results)
    id = try c.decodeIfPresent(String.self, forKey: .id)
    provider = try c.decodeIfPresent(JSONValue.self, forKey: .provider)
    usage = try c.decodeIfPresent(RerankUsage.self, forKey: .usage)
  }
  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}
public struct RerankResult: Codable, Sendable, Equatable {
  public var index: Int
  public var relevanceScore: Double
  public var document: RerankDocumentObject
  public var rawPayload: JSONValue
  enum CodingKeys: String, CodingKey {
    case index, document
    case relevanceScore = "relevance_score"
  }
  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    index = try c.decode(Int.self, forKey: .index)
    relevanceScore = try c.decode(Double.self, forKey: .relevanceScore)
    document = try c.decode(RerankDocumentObject.self, forKey: .document)
  }
  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}
public struct RerankUsage: Codable, Sendable, Equatable {
  public var cost: Double?
  public var searchUnits: Int?
  public var totalTokens: Int?
  public var rawPayload: JSONValue
  enum CodingKeys: String, CodingKey {
    case cost
    case searchUnits = "search_units"
    case totalTokens = "total_tokens"
  }
  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    cost = try c.decodeIfPresent(Double.self, forKey: .cost)
    searchUnits = try c.decodeIfPresent(Int.self, forKey: .searchUnits)
    totalTokens = try c.decodeIfPresent(Int.self, forKey: .totalTokens)
  }
  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}
