import Foundation

public struct ChatCompletionReasoning: Codable, Sendable, Equatable {
  public var effort: String?
  public var maxTokens: Int?
  public var exclude: Bool?
  public var enabled: Bool?

  enum CodingKeys: String, CodingKey {
    case effort
    case maxTokens = "max_tokens"
    case exclude
    case enabled
  }

  public init(
    effort: String? = nil, maxTokens: Int? = nil, exclude: Bool? = nil, enabled: Bool? = nil
  ) {
    self.effort = effort
    self.maxTokens = maxTokens
    self.exclude = exclude
    self.enabled = enabled
  }
}

public struct WebSearchOptions: Codable, Sendable, Equatable {
  public var searchContextSize: String

  enum CodingKeys: String, CodingKey {
    case searchContextSize = "search_context_size"
  }

  public init(searchContextSize: String) {
    self.searchContextSize = searchContextSize
  }
}

public struct CacheControl: Codable, Sendable, Equatable {
  public var type: String
  public var ttl: String?

  public init(type: String = "ephemeral", ttl: String? = nil) {
    self.type = type
    self.ttl = ttl
  }
}

public struct ResponseCacheConfig: Sendable, Equatable {
  public var enabled: Bool?
  public var ttlSeconds: Int?
  public var clear: Bool?

  public init(enabled: Bool? = nil, ttlSeconds: Int? = nil, clear: Bool? = nil) {
    self.enabled = enabled
    self.ttlSeconds = ttlSeconds
    self.clear = clear
  }
}

public struct ResponseCacheMetadata: Codable, Sendable, Equatable {
  public var status: String?
  public var ageSeconds: Int?
  public var ttlSeconds: Int?
  public var generationID: String?

  public init(
    status: String? = nil, ageSeconds: Int? = nil, ttlSeconds: Int? = nil,
    generationID: String? = nil
  ) {
    self.status = status
    self.ageSeconds = ageSeconds
    self.ttlSeconds = ttlSeconds
    self.generationID = generationID
  }
}

public struct ReasoningDetail: Codable, Sendable, Equatable {
  public var id: String?
  public var index: Int?
  public var type: String?
  public var text: String?
  public var summary: String?
  public var data: String?
  public var format: String?

  public init(
    id: String? = nil,
    index: Int? = nil,
    type: String? = nil,
    text: String? = nil,
    summary: String? = nil,
    data: String? = nil,
    format: String? = nil
  ) {
    self.id = id
    self.index = index
    self.type = type
    self.text = text
    self.summary = summary
    self.data = data
    self.format = format
  }
}
