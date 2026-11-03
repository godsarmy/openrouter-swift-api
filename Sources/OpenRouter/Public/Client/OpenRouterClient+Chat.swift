import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  public func createChatCompletion(
    _ request: ChatCompletionRequest,
    options: RequestOptions? = nil
  ) async throws
    -> ChatCompletionResponse
  {
    try await transport.post(
      path: "chat/completions",
      requestBody: request,
      responseType: ChatCompletionResponse.self,
      options: options
    )
  }

  public func createChatCompletionStream(
    _ request: ChatCompletionRequest
  ) -> AsyncThrowingStream<ChatCompletionChunk, Error> {
    let transport = self.transport
    return makeIncrementalStream(
      transport: transport, path: "chat/completions", request: request,
      prepare: { $0.stream = true },
      decode: { data, _ in
        try JSONDecoder().decode(ChatCompletionChunk.self, from: data)
      })
  }

  public func createChatCompletionStreamSession(
    _ request: ChatCompletionRequest
  ) async throws -> ChatCompletionStreamSession {
    let transport = self.transport
    let metadataBox = StreamMetadataBox()
    let metadataTask = metadataBox.makeTask()
    let stream = makeIncrementalStream(
      transport: transport, path: "chat/completions", request: request,
      prepare: { $0.stream = true },
      metadataBox: metadataBox,
      decode: { data, _ in
        try JSONDecoder().decode(ChatCompletionChunk.self, from: data)
      })
    return ChatCompletionStreamSession(
      stream: stream,
      responseCacheMetadata: try await metadataTask.value
    )
  }

  public func createCompletion(
    _ request: CompletionRequest,
    options: RequestOptions? = nil
  ) async throws -> CompletionResponse {
    try await transport.post(
      path: "completions",
      requestBody: request,
      responseType: CompletionResponse.self,
      options: options
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

extension OpenRouterClient {

  public var chat: ChatResource { ChatResource(client: self) }

  public struct ChatResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func send(
      _ request: ChatCompletionRequest,
      options: RequestOptions? = nil
    ) async throws -> ChatCompletionResponse {
      try await client.createChatCompletion(request, options: options)
    }

    public func stream(
      _ request: ChatCompletionRequest
    ) -> AsyncThrowingStream<ChatCompletionChunk, Error> {
      client.createChatCompletionStream(request)
    }
  }
}
