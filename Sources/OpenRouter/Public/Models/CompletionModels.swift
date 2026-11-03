import Foundation

public struct CompletionRequest: Codable, Sendable, Equatable {
  public var model: String
  public var prompt: String
  public var maxTokens: Int?
  public var responseCache: ResponseCacheConfig?

  enum CodingKeys: String, CodingKey {
    case model
    case prompt
    case maxTokens = "max_tokens"
  }

  public init(
    model: String,
    prompt: String,
    maxTokens: Int? = nil,
    responseCache: ResponseCacheConfig? = nil
  ) {
    self.model = model
    self.prompt = prompt
    self.maxTokens = maxTokens
    self.responseCache = responseCache
  }
}

public struct CompletionResponse: Codable, Sendable, Equatable {
  public var id: String?
  public var model: String?
  public var choices: [Choice]
  public var usage: Usage?
  public var responseCache: ResponseCacheMetadata?

  enum CodingKeys: String, CodingKey {
    case id
    case model
    case choices
    case usage
  }

  public init(
    id: String? = nil,
    model: String? = nil,
    choices: [Choice],
    usage: Usage? = nil,
    responseCache: ResponseCacheMetadata? = nil
  ) {
    self.id = id
    self.model = model
    self.choices = choices
    self.usage = usage
    self.responseCache = responseCache
  }

  public struct Choice: Codable, Sendable, Equatable {
    public var index: Int?
    public var text: String
    public var finishReason: String?

    enum CodingKeys: String, CodingKey {
      case index
      case text
      case finishReason = "finish_reason"
    }

    public init(index: Int? = nil, text: String, finishReason: String? = nil) {
      self.index = index
      self.text = text
      self.finishReason = finishReason
    }
  }
}
