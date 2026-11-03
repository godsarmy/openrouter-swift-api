import Foundation

public struct EmbeddingRequest: Codable, Sendable, Equatable {
  public var model: String
  public var input: EmbeddingInput
  public var responseCache: ResponseCacheConfig?

  enum CodingKeys: String, CodingKey {
    case model
    case input
  }

  public init(model: String, input: EmbeddingInput, responseCache: ResponseCacheConfig? = nil) {
    self.model = model
    self.input = input
    self.responseCache = responseCache
  }
}

public struct EmbeddingResponse: Codable, Sendable, Equatable {
  public var model: String?
  public var data: [EmbeddingData]
  public var usage: Usage?
  public var responseCache: ResponseCacheMetadata?

  enum CodingKeys: String, CodingKey {
    case model
    case data
    case usage
  }

  public init(
    model: String? = nil,
    data: [EmbeddingData],
    usage: Usage? = nil,
    responseCache: ResponseCacheMetadata? = nil
  ) {
    self.model = model
    self.data = data
    self.usage = usage
    self.responseCache = responseCache
  }
}

public struct EmbeddingData: Codable, Sendable, Equatable {
  public var index: Int
  public var embedding: [Double]

  public init(index: Int, embedding: [Double]) {
    self.index = index
    self.embedding = embedding
  }
}

public enum EmbeddingInput: Codable, Sendable, Equatable {
  case string(String)
  case strings([String])

  public init(from decoder: Decoder) throws {
    let single = try decoder.singleValueContainer()
    if let value = try? single.decode(String.self) {
      self = .string(value)
      return
    }
    if let value = try? single.decode([String].self) {
      self = .strings(value)
      return
    }
    throw DecodingError.typeMismatch(
      EmbeddingInput.self,
      .init(codingPath: decoder.codingPath, debugDescription: "Expected string or array of strings")
    )
  }

  public func encode(to encoder: Encoder) throws {
    var single = encoder.singleValueContainer()
    switch self {
    case .string(let value):
      try single.encode(value)
    case .strings(let value):
      try single.encode(value)
    }
  }
}
