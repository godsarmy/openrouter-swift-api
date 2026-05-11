import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct OpenRouterClient: Sendable {
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
    let (stream, _) = makeIncrementalStream(transport: transport, request: request)
    return stream
  }

  public func createChatCompletionStreamSession(
    _ request: ChatCompletionRequest
  ) async throws -> ChatCompletionStreamSession {
    let transport = self.transport
    let (stream, metadataTask) = makeIncrementalStream(transport: transport, request: request)
    return ChatCompletionStreamSession(
      stream: stream,
      responseCacheMetadata: try await metadataTask.value
    )
  }

  private func makeIncrementalStream(
    transport: HTTPTransport,
    request: ChatCompletionRequest
  ) -> (
    stream: AsyncThrowingStream<ChatCompletionChunk, Error>,
    metadataTask: Task<ResponseCacheMetadata?, Error>
  ) {
    let metadataBox = StreamMetadataBox()
    let metadataTask = Task<ResponseCacheMetadata?, Error> {
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<ResponseCacheMetadata?, Error>) in
        metadataBox.continuation = continuation
      }
    }

    let stream = AsyncThrowingStream<ChatCompletionChunk, Error> { continuation in
      do {
        var streamRequest = request
        streamRequest.stream = true
        let urlRequest = try transport.buildRequest(path: "chat/completions", body: streamRequest)

        let delegate = IncrementalSSEDelegate(
          transport: transport,
          onMetadata: { metadata in
            metadataBox.resume(with: .success(metadata))
          },
          onChunk: { chunk in
            continuation.yield(chunk)
          },
          onError: { error in
            metadataBox.resume(with: .failure(error))
            continuation.finish(throwing: error)
          },
          onDone: {
            continuation.finish()
          }
        )
        let runtime = IncrementalStreamRuntime(
          request: urlRequest,
          delegate: delegate,
          protocolClasses: transport.session.configuration.protocolClasses
        )

        continuation.onTermination = { _ in
          runtime.cancel()
          metadataBox.resume(with: .failure(OpenRouterError.streamCancelled))
        }

        runtime.start()
      } catch {
        metadataBox.resume(with: .failure(error))
        continuation.finish(throwing: error)
      }
    }

    return (stream, metadataTask)
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

  public func getGeneration(id: String) async throws -> JSONValue {
    try await transport.get(
      path: "generation",
      queryItems: [URLQueryItem(name: "id", value: id)],
      responseType: JSONValue.self
    )
  }

  public func getGenerationResponse(id: String) async throws -> GenerationResponse {
    try await transport.get(
      path: "generation",
      queryItems: [URLQueryItem(name: "id", value: id)],
      responseType: GenerationResponse.self
    )
  }

  public func listGenerationContent(id: String) async throws -> JSONValue {
    try await transport.get(
      path: "generation/content",
      queryItems: [URLQueryItem(name: "id", value: id)],
      responseType: JSONValue.self
    )
  }

  public func listGenerationContentResponse(id: String) async throws -> GenerationContentResponse {
    try await transport.get(
      path: "generation/content",
      queryItems: [URLQueryItem(name: "id", value: id)],
      responseType: GenerationContentResponse.self
    )
  }

  public func listModels() async throws -> ModelsResponse {
    try await transport.get(path: "models", responseType: ModelsResponse.self)
  }

  public func getCredits() async throws -> CreditsResponse {
    try await transport.get(path: "credits", responseType: CreditsResponse.self)
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

    let modelsToTry = [request.model] + policy.models

    let (stream, continuation) = AsyncThrowingStream.makeStream(of: ChatCompletionChunk.self)
    Task {
      var lastError: Error?

      for (index, model) in modelsToTry.enumerated() {
        do {
          var candidate = request
          candidate.model = model
          let session = try await createChatCompletionStreamSession(candidate)
          for try await chunk in session.stream {
            continuation.yield(chunk)
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
    public var appTitle: String?
    public var appCategories: [String]?
    public var experimentalMetadata: String?
    public var xTitle: String?

    // Stored privately until transport layer is implemented.
    var apiKey: String?

    public init(
      baseURL: URL = URL(string: "https://openrouter.ai/api/v1/")!,
      timeout: TimeInterval = 60,
      httpReferer: String? = nil,
      appTitle: String? = nil,
      appCategories: [String]? = nil,
      experimentalMetadata: String? = nil,
      xTitle: String? = nil
    ) {
      self.baseURL = baseURL
      self.timeout = timeout
      self.httpReferer = httpReferer
      self.appTitle = appTitle
      self.appCategories = appCategories
      self.experimentalMetadata = experimentalMetadata
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
  case streamCancelled

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
    case (.streamCancelled, .streamCancelled):
      true
    default:
      false
    }
  }
}

private final class StreamMetadataBox: @unchecked Sendable {
  var continuation: CheckedContinuation<ResponseCacheMetadata?, Error>?
  private var didResume = false

  func resume(with result: Result<ResponseCacheMetadata?, Error>) {
    guard !didResume else { return }
    didResume = true
    guard let continuation else { return }
    switch result {
    case .success(let metadata):
      continuation.resume(returning: metadata)
    case .failure(let error):
      continuation.resume(throwing: error)
    }
    self.continuation = nil
  }
}

private final class IncrementalStreamRuntime: @unchecked Sendable {
  private let session: URLSession
  private let task: URLSessionDataTask
  private let delegate: IncrementalSSEDelegate

  init(
    request: URLRequest,
    delegate: IncrementalSSEDelegate,
    protocolClasses: [AnyClass]?
  ) {
    self.delegate = delegate
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = protocolClasses
    session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    task = session.dataTask(with: request)
  }

  func start() {
    task.resume()
  }

  func cancel() {
    task.cancel()
    session.invalidateAndCancel()
    _ = delegate
  }
}

private final class IncrementalSSEDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
  private let transport: HTTPTransport
  private let onMetadata: @Sendable (ResponseCacheMetadata?) -> Void
  private let onChunk: @Sendable (ChatCompletionChunk) -> Void
  private let onError: @Sendable (Error) -> Void
  private let onDone: @Sendable () -> Void
  private var buffer = Data()
  private var didTerminate = false

  init(
    transport: HTTPTransport,
    onMetadata: @escaping @Sendable (ResponseCacheMetadata?) -> Void,
    onChunk: @escaping @Sendable (ChatCompletionChunk) -> Void,
    onError: @escaping @Sendable (Error) -> Void,
    onDone: @escaping @Sendable () -> Void
  ) {
    self.transport = transport
    self.onMetadata = onMetadata
    self.onChunk = onChunk
    self.onError = onError
    self.onDone = onDone
  }

  func urlSession(
    _ session: URLSession,
    dataTask: URLSessionDataTask,
    didReceive response: URLResponse,
    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
  ) {
    guard let http = response as? HTTPURLResponse else {
      didTerminate = true
      onError(OpenRouterError.invalidResponse)
      completionHandler(.cancel)
      return
    }

    guard (200..<300).contains(http.statusCode) else {
      didTerminate = true
      onError(
        OpenRouterError.apiError(
          statusCode: http.statusCode,
          code: nil,
          message: "Streaming request failed",
          rawBody: nil
        ))
      completionHandler(.cancel)
      return
    }

    onMetadata(transport.parseResponseCacheMetadata(from: http))
    completionHandler(.allow)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    guard !didTerminate else { return }
    buffer.append(data)

    while let newlineRange = buffer.range(of: Data([0x0A])) {
      let lineData = buffer.subdata(in: buffer.startIndex..<newlineRange.lowerBound)
      buffer.removeSubrange(buffer.startIndex...newlineRange.lowerBound)
      let line = String(decoding: lineData, as: UTF8.self)

      guard let event = SSEParser.parse(line: line) else { continue }

      switch event {
      case .done:
        didTerminate = true
        onDone()
        session.invalidateAndCancel()
        return
      case .data(let payload):
        do {
          let payloadData = Data(payload.utf8)
          let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: payloadData)
          onChunk(chunk)
        } catch {
          didTerminate = true
          onError(error)
          session.invalidateAndCancel()
          return
        }
      }
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard !didTerminate else { return }
    didTerminate = true
    if let error {
      onError(error)
    } else {
      onDone()
    }
  }
}

extension OpenRouterError {
  static func decodingFailed(statusCode: Int, underlying: Error) -> Self {
    .decodingFailed(statusCode: statusCode, underlying: String(describing: underlying))
  }
}
