import Foundation

public struct OpenRouterClient {
  public let configuration: Configuration

  public init(apiKey: String, configuration: Configuration = .init()) {
    self.configuration = configuration.withAPIKey(apiKey)
  }

  public func createChatCompletion(_ request: ChatCompletionRequest) async throws
    -> ChatCompletionResponse
  {
    throw OpenRouterError.notImplemented("createChatCompletion")
  }

  public func createChatCompletionStream(
    _ request: ChatCompletionRequest
  ) -> AsyncThrowingStream<ChatCompletionChunk, Error> {
    AsyncThrowingStream { continuation in
      continuation.finish(throwing: OpenRouterError.notImplemented("createChatCompletionStream"))
    }
  }

  public func createEmbeddings(_ request: EmbeddingRequest) async throws -> EmbeddingResponse {
    throw OpenRouterError.notImplemented("createEmbeddings")
  }

  public func createCompletion(_ request: CompletionRequest) async throws -> CompletionResponse {
    throw OpenRouterError.notImplemented("createCompletion")
  }

  public func createChatCompletionWithFallback(
    _ request: ChatCompletionRequest,
    fallbackModels: [String]
  ) async throws -> ChatCompletionResponse {
    _ = fallbackModels
    throw OpenRouterError.notImplemented("createChatCompletionWithFallback")
  }

  public func createChatCompletionStreamWithFallback(
    _ request: ChatCompletionRequest,
    fallbackModels: [String]
  ) -> AsyncThrowingStream<ChatCompletionChunk, Error> {
    _ = fallbackModels
    return createChatCompletionStream(request)
  }

  public func createChatCompletionWithFallbackPolicy(
    _ request: ChatCompletionRequest,
    policy: ChatCompletionFallbackPolicy
  ) async throws -> ChatCompletionResponse {
    _ = policy
    throw OpenRouterError.notImplemented("createChatCompletionWithFallbackPolicy")
  }
}

extension OpenRouterClient {
  public struct Configuration: Sendable {
    public var baseURL: URL
    public var timeout: TimeInterval
    public var httpReferer: String?
    public var xTitle: String?

    // Stored privately until transport layer is implemented.
    var apiKey: String?

    public init(
      baseURL: URL = URL(string: "https://openrouter.ai/api/v1")!,
      timeout: TimeInterval = 60,
      httpReferer: String? = nil,
      xTitle: String? = nil
    ) {
      self.baseURL = baseURL
      self.timeout = timeout
      self.httpReferer = httpReferer
      self.xTitle = xTitle
      self.apiKey = nil
    }

    public func withHTTPReferer(_ value: String?) -> Self {
      var copy = self
      copy.httpReferer = value
      return copy
    }

    public func withXTitle(_ value: String?) -> Self {
      var copy = self
      copy.xTitle = value
      return copy
    }

    fileprivate func withAPIKey(_ value: String) -> Self {
      var copy = self
      copy.apiKey = value
      return copy
    }
  }
}

public struct ChatCompletionFallbackPolicy: Sendable, Equatable {
  public var models: [String]
  public var errorCodes: [Int]

  public init(models: [String], errorCodes: [Int]) {
    self.models = models
    self.errorCodes = errorCodes
  }

  public static let defaultErrorCodes: [Int] = [402, 408, 429, 500, 502, 503, 504, 524, 529]
}

public enum OpenRouterError: Error, Equatable {
  case notImplemented(String)
}
