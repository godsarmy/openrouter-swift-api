import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct OpenRouterClient {
  public let configuration: Configuration
  private let transport: HTTPTransport

  public init(apiKey: String, configuration: Configuration = .init()) {
    let resolved = configuration.withAPIKey(apiKey)
    self.configuration = resolved
    transport = HTTPTransport(configuration: resolved)
  }

  public func createChatCompletion(_ request: ChatCompletionRequest) async throws
    -> ChatCompletionResponse
  {
    try await transport.post(
      path: "chat/completions",
      requestBody: request,
      responseType: ChatCompletionResponse.self
    )
  }

  public func createChatCompletionStream(
    _ request: ChatCompletionRequest
  ) -> AsyncThrowingStream<ChatCompletionChunk, Error> {
    let transport = self.transport
    return AsyncThrowingStream { continuation in
      Task.detached {
        do {
          var streamRequest = request
          streamRequest.stream = true
          let urlRequest = try transport.buildRequest(path: "chat/completions", body: streamRequest)
          let (data, response) = try await transport.session.data(for: urlRequest)

          guard let http = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
          }

          guard (200..<300).contains(http.statusCode) else {
            throw OpenRouterError.apiError(
              statusCode: http.statusCode,
              code: nil,
              message: "Streaming request failed",
              rawBody: nil
            )
          }

          let raw = String(decoding: data, as: UTF8.self)
          for line in raw.split(separator: "\n").map(String.init) {
            guard let event = SSEParser.parse(line: line) else { continue }
            switch event {
            case .done:
              continuation.finish()
              return
            case .data(let payload):
              let data = Data(payload.utf8)
              let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: data)
              continuation.yield(chunk)
            }
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }

  public func createEmbeddings(_ request: EmbeddingRequest) async throws -> EmbeddingResponse {
    try await transport.post(
      path: "embeddings",
      requestBody: request,
      responseType: EmbeddingResponse.self
    )
  }

  public func createCompletion(_ request: CompletionRequest) async throws -> CompletionResponse {
    try await transport.post(
      path: "completions",
      requestBody: request,
      responseType: CompletionResponse.self
    )
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
  case missingAPIKey
  case invalidURL(String)
  case invalidResponse
  case decodingFailed(statusCode: Int, underlying: String)
  case apiError(statusCode: Int, code: Int?, message: String?, rawBody: String?)

  public static func == (lhs: OpenRouterError, rhs: OpenRouterError) -> Bool {
    switch (lhs, rhs) {
    case (.notImplemented(let a), .notImplemented(let b)):
      a == b
    case (.missingAPIKey, .missingAPIKey):
      true
    case (.invalidURL(let a), .invalidURL(let b)):
      a == b
    case (.invalidResponse, .invalidResponse):
      true
    case (
      .decodingFailed(let aStatus, let aUnderlying), .decodingFailed(let bStatus, let bUnderlying)
    ):
      aStatus == bStatus && aUnderlying == bUnderlying
    case (
      .apiError(let aStatus, let aCode, let aMessage, let aRaw),
      .apiError(let bStatus, let bCode, let bMessage, let bRaw)
    ):
      aStatus == bStatus && aCode == bCode && aMessage == bMessage && aRaw == bRaw
    default:
      false
    }
  }
}

extension OpenRouterError {
  static func decodingFailed(statusCode: Int, underlying: Error) -> Self {
    .decodingFailed(statusCode: statusCode, underlying: String(describing: underlying))
  }
}
