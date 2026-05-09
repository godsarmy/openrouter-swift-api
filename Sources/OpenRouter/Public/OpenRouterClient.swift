import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct OpenRouterClient {
  public let configuration: Configuration
  private let transport: HTTPTransport

  public init(
    apiKey: String,
    configuration: Configuration = .init(),
    session: URLSession = .shared
  ) {
    let resolved = configuration.withAPIKey(apiKey)
    self.configuration = resolved
    transport = HTTPTransport(configuration: resolved, session: session)
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
      do {
        var streamRequest = request
        streamRequest.stream = true
        let urlRequest = try transport.buildRequest(path: "chat/completions", body: streamRequest)

        let task = transport.session.dataTask(with: urlRequest) { data, response, error in
          if let error {
            continuation.finish(throwing: error)
            return
          }

          guard let response, let data else {
            continuation.finish(throwing: OpenRouterError.invalidResponse)
            return
          }

          guard let http = response as? HTTPURLResponse else {
            continuation.finish(throwing: OpenRouterError.invalidResponse)
            return
          }

          guard (200..<300).contains(http.statusCode) else {
            continuation.finish(
              throwing: OpenRouterError.apiError(
                statusCode: http.statusCode,
                code: nil,
                message: "Streaming request failed",
                rawBody: nil
              ))
            return
          }

          do {
            let chunks = try Self.decodeStreamChunks(from: data)
            for chunk in chunks {
              continuation.yield(chunk)
            }
            continuation.finish()
          } catch {
            continuation.finish(throwing: error)
          }
        }

        continuation.onTermination = { _ in task.cancel() }
        task.resume()
      } catch {
        continuation.finish(throwing: error)
      }
    }
  }

  public func createChatCompletionStreamSession(
    _ request: ChatCompletionRequest
  ) async throws -> ChatCompletionStreamSession {
    let transport = self.transport
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

    let chunks = try Self.decodeStreamChunks(from: data)
    let stream = AsyncThrowingStream<ChatCompletionChunk, Error> { continuation in
      for chunk in chunks {
        continuation.yield(chunk)
      }
      continuation.finish()
    }

    return ChatCompletionStreamSession(
      stream: stream,
      responseCacheMetadata: transport.parseResponseCacheMetadata(from: http)
    )
  }

  private static func decodeStreamChunks(from data: Data) throws -> [ChatCompletionChunk] {
    let raw = String(decoding: data, as: UTF8.self)
    var chunks: [ChatCompletionChunk] = []
    for line in raw.split(separator: "\n").map(String.init) {
      guard let event = SSEParser.parse(line: line) else { continue }
      switch event {
      case .done:
        return chunks
      case .data(let payload):
        let payloadData = Data(payload.utf8)
        let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: payloadData)
        chunks.append(chunk)
      }
    }
    return chunks
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
    let policy = ChatCompletionFallbackPolicy(
      models: fallbackModels,
      errorCodes: ChatCompletionFallbackPolicy.defaultErrorCodes
    )
    return try await createChatCompletionWithFallbackPolicy(request, policy: policy)
  }

  public func createChatCompletionStreamWithFallback(
    _ request: ChatCompletionRequest,
    fallbackModels: [String]
  ) -> AsyncThrowingStream<ChatCompletionChunk, Error> {
    let policy = ChatCompletionFallbackPolicy(
      models: fallbackModels,
      errorCodes: ChatCompletionFallbackPolicy.defaultErrorCodes
    )

    let transport = self.transport
    let modelsToTry = [request.model] + policy.models

    let (stream, continuation) = AsyncThrowingStream.makeStream(of: ChatCompletionChunk.self)
    Task {
      var lastError: Error?

      for (index, model) in modelsToTry.enumerated() {
        do {
          var candidate = request
          candidate.model = model
          var streamRequest = candidate
          streamRequest.stream = true

          let urlRequest = try transport.buildRequest(
            path: "chat/completions", body: streamRequest)
          let (data, response) = try await transport.session.data(for: urlRequest)

          guard let http = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
          }

          guard (200..<300).contains(http.statusCode) else {
            let apiError = try? JSONDecoder().decode(OpenRouterAPIErrorEnvelope.self, from: data)
            throw OpenRouterError.apiError(
              statusCode: http.statusCode,
              code: apiError?.error.code,
              message: apiError?.error.message,
              rawBody: String(data: data, encoding: .utf8)
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
              let payloadData = Data(payload.utf8)
              let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: payloadData)
              continuation.yield(chunk)
            }
          }
          continuation.finish()
          return
        } catch {
          lastError = error
          let hasMoreModels = index < modelsToTry.count - 1
          if hasMoreModels,
            OpenRouterClient.shouldFallback(for: error, policy: policy)
          {
            continue
          }
          continuation.finish(throwing: error)
          return
        }
      }

      continuation.finish(
        throwing: lastError ?? OpenRouterError.notImplemented("stream fallback exhausted"))
    }
    return stream
  }

  public func createChatCompletionWithFallbackPolicy(
    _ request: ChatCompletionRequest,
    policy: ChatCompletionFallbackPolicy
  ) async throws -> ChatCompletionResponse {
    let modelsToTry = [request.model] + policy.models
    var lastError: Error?

    for (index, model) in modelsToTry.enumerated() {
      do {
        var candidate = request
        candidate.model = model
        return try await createChatCompletion(candidate)
      } catch {
        lastError = error
        let hasMoreModels = index < modelsToTry.count - 1
        if hasMoreModels,
          OpenRouterClient.shouldFallback(for: error, policy: policy)
        {
          continue
        }
        throw error
      }
    }

    throw lastError ?? OpenRouterError.notImplemented("fallback exhausted")
  }

  static func shouldFallback(for error: Error, policy: ChatCompletionFallbackPolicy) -> Bool {
    guard case OpenRouterError.apiError(let statusCode, let code, _, _) = error else {
      return false
    }

    if let code, policy.errorCodes.contains(code) {
      return true
    }

    return policy.errorCodes.contains(statusCode)
  }
}

public struct ChatCompletionStreamSession {
  public let stream: AsyncThrowingStream<ChatCompletionChunk, Error>
  public let responseCacheMetadata: ResponseCacheMetadata?

  public init(
    stream: AsyncThrowingStream<ChatCompletionChunk, Error>,
    responseCacheMetadata: ResponseCacheMetadata?
  ) {
    self.stream = stream
    self.responseCacheMetadata = responseCacheMetadata
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
