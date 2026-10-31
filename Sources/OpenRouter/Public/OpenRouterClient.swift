import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct OpenRouterClient: Sendable {
  public let configuration: Configuration
  private let transport: HTTPTransport

  /// Omit `apiKey` only for unauthenticated authorization-code exchange.
  public init(
    apiKey: String = "",
    configuration: Configuration = .init(),
    session: URLSession = .shared
  ) {
    let resolved = configuration.withAPIKey(apiKey)
    self.configuration = resolved
    transport = HTTPTransport(configuration: resolved, session: session)
  }

  /// Starts provider work and may incur image-generation costs. Requires a normal API key
  /// with the server-required authorization scope. Only nonstreaming responses are supported.
  /// `n` is an upper bound: providers may return fewer images. A seed does not guarantee determinism.
  public func createImage(
    _ request: ImageGenerationRequest,
    options: RequestOptions? = nil
  ) async throws -> ImageGenerationResponse {
    try await transport.post(
      path: "images", requestBody: request,
      responseType: ImageGenerationResponse.self, options: options)
  }

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

  /// Streams image generation without retrying or resubmitting provider work.
  public func createImageStream(
    _ request: ImageGenerationRequest, options: RequestOptions? = nil
  ) -> AsyncThrowingStream<ImageGenerationStreamEvent, Error> {
    let state = ImageStreamState()
    return makeIncrementalStream(
      transport: transport, path: "images", request: StreamingImageRequest(request: request),
      prepare: { _ in }, options: options, accept: "text/event-stream, application/json",
      decodeBufferedJSON: { data in
        let response = try JSONDecoder().decode(ImageGenerationResponse.self, from: data)
        state.buffered = true
        return ImageGenerationStreamEvent(bufferedResponse: response)
      },
      validateFinish: { done in
        guard state.buffered || (state.completed && done) else {
          throw ImageGenerationStreamError.incompleteStream
        }
      },
      decode: { data, name in
        var event = try JSONDecoder().decode(ImageGenerationStreamEvent.self, from: data)
        guard event.bufferedResponse == nil else {
          throw DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "Buffered response in SSE"))
        }
        event.eventName = name
        if let error = event.error { throw ImageGenerationStreamError.provider(error) }
        if event.type == "image_generation.completed" { state.completed = true }
        return event
      })
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

  private func makeIncrementalStream<Request: Encodable, Element: Sendable>(
    transport: HTTPTransport,
    path: String,
    request: Request,
    prepare: @escaping @Sendable (inout Request) -> Void,
    metadataBox: StreamMetadataBox? = nil,
    options: RequestOptions? = nil,
    accept: String? = nil,
    decodeBufferedJSON: (@Sendable (Data) throws -> Element)? = nil,
    validateFinish: (@Sendable (Bool) throws -> Void)? = nil,
    decode: @escaping @Sendable (Data, String?) throws -> Element
  ) -> AsyncThrowingStream<Element, Error> {
    let stream = AsyncThrowingStream<Element, Error> { continuation in
      do {
        var streamRequest = request
        prepare(&streamRequest)
        let urlRequest = try transport.buildRequest(
          path: path, body: streamRequest, accept: accept ?? "application/json", options: options)

        let delegate = IncrementalSSEDelegate(
          transport: transport,
          onMetadata: { metadata in
            metadataBox?.resume(with: .success(metadata))
          },
          decode: decode,
          decodeBufferedJSON: decodeBufferedJSON,
          onElement: { element in
            continuation.yield(element)
          },
          onError: { error in
            metadataBox?.resume(with: .failure(error))
            continuation.finish(throwing: error)
          },
          onDone: { done in
            do {
              try validateFinish?(done)
              continuation.finish()
            } catch {
              continuation.finish(throwing: error)
            }
          }
        )
        let runtime = IncrementalStreamRuntime(
          request: urlRequest,
          delegate: delegate,
          protocolClasses: transport.session.configuration.protocolClasses
        )

        continuation.onTermination = { _ in
          runtime.cancel()
          metadataBox?.resume(with: .failure(OpenRouterError.streamCancelled))
        }

        runtime.start()
      } catch {
        metadataBox?.resume(with: .failure(error))
        continuation.finish(throwing: error)
      }
    }

    return stream
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

  public func createEmbeddings(
    _ request: EmbeddingRequest,
    options: RequestOptions? = nil
  ) async throws -> EmbeddingResponse {
    try await transport.post(
      path: "embeddings",
      requestBody: request,
      responseType: EmbeddingResponse.self,
      options: options
    )
  }

  public func createAudioSpeech(
    _ request: AudioSpeechRequest,
    options: RequestOptions? = nil
  ) async throws -> Data {
    try await transport.postData(
      path: "audio/speech",
      requestBody: request,
      accept: "audio/mpeg, audio/pcm",
      options: options
    )
  }

  public func createAudioTranscriptions(
    _ request: AudioTranscriptionRequest,
    options: RequestOptions? = nil
  ) async throws -> AudioTranscriptionResponse {
    let boundary = "OpenRouterBoundary-\(UUID().uuidString)"
    return try await transport.postMultipart(
      path: "audio/transcriptions",
      body: makeAudioTranscriptionMultipartBody(request, boundary: boundary),
      boundary: boundary,
      responseType: AudioTranscriptionResponse.self,
      options: options
    )
  }

  public func uploadFile(
    _ file: FileUpload,
    workspaceID: UUID? = nil,
    options: RequestOptions? = nil
  ) async throws -> FileMetadata {
    let boundary = "OpenRouterBoundary-\(UUID().uuidString)"
    let queryItems =
      workspaceID.map {
        [URLQueryItem(name: "workspace_id", value: $0.uuidString)]
      } ?? []
    return try await transport.postMultipart(
      path: "files",
      body: makeFileUploadMultipartBody(file, boundary: boundary),
      boundary: boundary,
      queryItems: queryItems,
      responseType: FileMetadata.self,
      options: options
    )
  }

  /// Submits a batch, starting potentially costly provider work. Requests are not retried by default.
  /// The server validates body size, models, endpoints, routing, and HTTPS callback URLs.
  public func createBatch(
    _ request: CreateBatchRequest, options: RequestOptions? = nil
  ) async throws -> BatchObject {
    try await transport.post(
      path: "batches", requestBody: request, responseType: BatchObject.self,
      sortedKeys: true, options: options)
  }

  /// Lists batches in the API key's workspace. Statuses and time filters are passed through unchanged.
  public func listBatches(
    limit: Int? = nil, after: String? = nil, statuses: [String]? = nil,
    createdAfter: String? = nil, createdBefore: String? = nil, options: RequestOptions? = nil
  ) async throws -> BatchListResponse {
    var queryItems: [URLQueryItem] = []
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    if let after { queryItems.append(.init(name: "after", value: after)) }
    for status in statuses ?? [] { queryItems.append(.init(name: "status", value: status)) }
    if let createdAfter { queryItems.append(.init(name: "created_after", value: createdAfter)) }
    if let createdBefore { queryItems.append(.init(name: "created_before", value: createdBefore)) }
    return try await transport.get(
      path: "batches", queryItems: queryItems, responseType: BatchListResponse.self,
      options: options)
  }

  /// Retrieves batch status and any inline results in the API key's workspace.
  public func getBatch(id: String, options: RequestOptions? = nil) async throws -> BatchObject {
    try await transport.get(
      path: .preEscaped("batches/\(escapePathSegment(id))"), responseType: BatchObject.self,
      options: options)
  }

  /// Irreversibly purges a terminal batch's requests and results; this is not cancellation.
  /// Billing and audit records are not erased. The server checks eligibility without a client
  /// status preflight (which would race with deletion). Default retries remain disabled.
  public func deleteBatch(
    id: String, options: RequestOptions? = nil
  ) async throws -> BatchDeleteResponse {
    try await transport.delete(
      path: .preEscaped("batches/\(escapePathSegment(id))"),
      responseType: BatchDeleteResponse.self, options: options)
  }

  /// Lists files. The server validates limit (1...1000); cursors and provider filters are opaque.
  public func listFiles(
    limit: Int? = nil, cursor: String? = nil, workspaceID: UUID? = nil,
    provider: String? = nil, after: String? = nil, afterID: String? = nil,
    beforeID: String? = nil, order: String? = nil, options: RequestOptions? = nil
  ) async throws -> FileListResponse {
    var queryItems: [URLQueryItem] = []
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    if let cursor { queryItems.append(.init(name: "cursor", value: cursor)) }
    if let workspaceID {
      queryItems.append(.init(name: "workspace_id", value: workspaceID.uuidString))
    }
    if let provider { queryItems.append(.init(name: "provider", value: provider)) }
    if let after { queryItems.append(.init(name: "after", value: after)) }
    if let afterID { queryItems.append(.init(name: "after_id", value: afterID)) }
    if let beforeID { queryItems.append(.init(name: "before_id", value: beforeID)) }
    if let order { queryItems.append(.init(name: "order", value: order)) }
    return try await transport.get(
      path: "files", queryItems: queryItems, responseType: FileListResponse.self, options: options)
  }

  /// Retrieves metadata. The server validates IDs (1...256 word characters or hyphens).
  public func getFile(
    id: String, workspaceID: UUID? = nil, provider: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> FileResponse {
    var queryItems: [URLQueryItem] = []
    if let workspaceID {
      queryItems.append(.init(name: "workspace_id", value: workspaceID.uuidString))
    }
    if let provider { queryItems.append(.init(name: "provider", value: provider)) }
    return try await transport.get(
      path: .preEscaped("files/\(escapePathSegment(id))"), queryItems: queryItems,
      responseType: FileResponse.self, options: options)
  }

  /// Irreversibly deletes a file; callers must obtain explicit authorization before calling.
  /// Uploaded/downloadable status does not determine deletion eligibility.
  /// The server validates IDs against `^[\w-]+$` with length 1...256; IDs are passed through safely escaped.
  public func deleteFile(
    id: String, workspaceID: UUID? = nil, provider: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> FileDeleteResponse {
    var queryItems: [URLQueryItem] = []
    if let workspaceID {
      queryItems.append(.init(name: "workspace_id", value: workspaceID.uuidString))
    }
    if let provider { queryItems.append(.init(name: "provider", value: provider)) }
    return try await transport.delete(
      path: .preEscaped("files/\(escapePathSegment(id))"), queryItems: queryItems,
      responseType: FileDeleteResponse.self, options: options)
  }

  /// Buffers downloadable file bytes. Uploaded files are not downloadable (server returns 400).
  /// The server validates IDs (1...256 word characters or hyphens).
  public func downloadFileContent(
    id: String, workspaceID: UUID? = nil, provider: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> FileContentDownload {
    var queryItems: [URLQueryItem] = []
    if let workspaceID {
      queryItems.append(.init(name: "workspace_id", value: workspaceID.uuidString))
    }
    if let provider { queryItems.append(.init(name: "provider", value: provider)) }
    let response = try await transport.getData(
      path: .preEscaped("files/\(escapePathSegment(id))/content"), queryItems: queryItems,
      accept: "application/octet-stream", options: options)
    return .init(data: response.data, contentType: response.contentType)
  }

  public func createVideos(
    _ request: VideoRequest,
    options: RequestOptions? = nil
  ) async throws -> VideoResponse {
    try await transport.post(
      path: "videos", requestBody: request, responseType: VideoResponse.self, options: options)
  }

  public func getVideos(jobId: String, options: RequestOptions? = nil) async throws -> VideoResponse
  {
    try await transport.get(
      path: .preEscaped("videos/\(escapePathSegment(jobId))"),
      responseType: VideoResponse.self,
      options: options
    )
  }

  public func listVideosContent(
    _ request: VideoContentRequest,
    options: RequestOptions? = nil
  ) async throws -> VideoContentResponse {
    var queryItems: [URLQueryItem] = []
    if let index = request.index { queryItems.append(.init(name: "index", value: String(index))) }
    let response = try await transport.getData(
      path: .preEscaped("videos/\(escapePathSegment(request.jobID))/content"),
      queryItems: queryItems, accept: "application/octet-stream", options: options)
    return .init(data: response.data, contentType: response.contentType)
  }

  public func listVideosModels(options: RequestOptions? = nil) async throws
    -> VideoModelsListResponse
  {
    try await transport.get(
      path: "videos/models", responseType: VideoModelsListResponse.self, options: options)
  }

  private func escapePathSegment(_ value: String) -> String {
    let allowed = CharacterSet(
      charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
  }

  private func makeAudioTranscriptionMultipartBody(
    _ request: AudioTranscriptionRequest, boundary: String
  ) -> Data {
    var body = Data()
    func append(_ value: String) { body.append(contentsOf: value.utf8) }
    func field(_ name: String, _ value: String) {
      append(
        "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n")
    }
    let filename = sanitizeMultipartFilename(request.file.filename)
    append("--\(boundary)\r\n")
    append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
    append("Content-Type: \(request.file.mediaType ?? "application/octet-stream")\r\n\r\n")
    body.append(request.file.data)
    append("\r\n")
    field("model", request.model)
    if let language = request.language { field("language", language) }
    if let temperature = request.temperature { field("temperature", String(temperature)) }
    if let responseFormat = request.responseFormat {
      field("response_format", responseFormat.rawValue)
    }
    for granularity in request.timestampGranularities ?? [] {
      field("timestamp_granularities[]", granularity.rawValue)
    }
    if let prompt = request.prompt { field("prompt", prompt) }
    append("--\(boundary)--\r\n")
    return body
  }

  private func makeFileUploadMultipartBody(_ file: FileUpload, boundary: String) -> Data {
    var body = Data()
    func append(_ value: String) { body.append(contentsOf: value.utf8) }
    append("--\(boundary)\r\n")
    append(
      "Content-Disposition: form-data; name=\"file\"; filename=\"\(sanitizeMultipartFilename(file.filename))\"\r\n"
    )
    append("Content-Type: \(file.mediaType ?? "application/octet-stream")\r\n\r\n")
    body.append(file.data)
    append("\r\n--\(boundary)--\r\n")
    return body
  }

  private func sanitizeMultipartFilename(_ filename: String) -> String {
    filename
      .replacingOccurrences(of: "\"", with: "%22")
      .replacingOccurrences(of: "\r", with: "")
      .replacingOccurrences(of: "\n", with: "")
  }

  public func listEmbeddingsModels(
    offset: Int? = nil,
    limit: Int? = nil,
    options: RequestOptions? = nil
  ) async throws -> EmbeddingsModelsResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(URLQueryItem(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(URLQueryItem(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: "embeddings/models",
      queryItems: queryItems,
      responseType: EmbeddingsModelsResponse.self,
      options: options
    )
  }

  public func createRerank(_ request: RerankRequest, options: RequestOptions? = nil) async throws
    -> RerankResponse
  {
    try await transport.post(
      path: "rerank", requestBody: request, responseType: RerankResponse.self, options: options)
  }

  public func createResponse(
    _ request: ResponsesRequest,
    options: RequestOptions? = nil
  ) async throws -> ResponsesResponse {
    try await transport.post(
      path: "responses",
      requestBody: request,
      responseType: ResponsesResponse.self,
      options: options
    )
  }

  public func createMessage(_ request: MessagesRequest, options: RequestOptions? = nil) async throws
    -> MessagesResponse
  {
    try await transport.post(
      path: "messages", requestBody: request, responseType: MessagesResponse.self, options: options)
  }

  public func createMessageStream(_ request: MessagesRequest) -> AsyncThrowingStream<
    MessagesStreamEvent, Error
  > {
    makeIncrementalStream(
      transport: transport, path: "messages", request: request, prepare: { $0.stream = true },
      decode: { data, eventName in
        let event = try JSONDecoder().decode(MessagesStreamEvent.self, from: data).withEventName(
          eventName)
        if event.type == "error" { throw OpenRouterError.messageStreamError(from: event) }
        return event
      })
  }

  public func createResponseStream(
    _ request: ResponsesRequest
  ) -> AsyncThrowingStream<ResponsesStreamEvent, Error> {
    let transport = self.transport
    return makeResponsesIncrementalStream(transport: transport, request: request)
  }

  private func makeResponsesIncrementalStream(
    transport: HTTPTransport,
    request: ResponsesRequest
  ) -> AsyncThrowingStream<ResponsesStreamEvent, Error> {
    return makeIncrementalStream(
      transport: transport, path: "responses", request: request, prepare: { $0.stream = true },
      decode: { data, _ in
        let event = try JSONDecoder().decode(ResponsesStreamEvent.self, from: data)
        if ["response.failed", "response.error", "error"].contains(event.type) {
          throw OpenRouterError.streamEventError(from: event)
        }
        return event
      })
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

  public func getGeneration(id: String, options: RequestOptions? = nil) async throws
    -> GenerationResponse
  {
    try await transport.get(
      path: "generation",
      queryItems: [URLQueryItem(name: "id", value: id)],
      responseType: GenerationResponse.self,
      options: options
    )
  }

  public func getGenerationRaw(id: String, options: RequestOptions? = nil) async throws -> JSONValue
  {
    try await transport.get(
      path: "generation",
      queryItems: [URLQueryItem(name: "id", value: id)],
      responseType: JSONValue.self,
      options: options
    )
  }

  public func listGenerationContent(id: String, options: RequestOptions? = nil) async throws
    -> GenerationContentResponse
  {
    try await transport.get(
      path: "generation/content",
      queryItems: [URLQueryItem(name: "id", value: id)],
      responseType: GenerationContentResponse.self,
      options: options
    )
  }

  public func listGenerationContentRaw(id: String, options: RequestOptions? = nil) async throws
    -> JSONValue
  {
    try await transport.get(
      path: "generation/content",
      queryItems: [URLQueryItem(name: "id", value: id)],
      responseType: JSONValue.self,
      options: options
    )
  }

  public func listModels(options: RequestOptions? = nil) async throws -> ModelsResponse {
    try await transport.get(path: "models", responseType: ModelsResponse.self, options: options)
  }

  public func listModelsUser(
    offset: Int? = nil,
    limit: Int? = nil,
    options: RequestOptions? = nil
  ) async throws -> UserModelsResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(URLQueryItem(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(URLQueryItem(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: "models/user",
      queryItems: queryItems,
      responseType: UserModelsResponse.self,
      options: options
    )
  }

  public func listModelsCount(
    outputModalities: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> ModelsCountResponse {
    let queryItems =
      outputModalities.map { [URLQueryItem(name: "output_modalities", value: $0)] } ?? []
    return try await transport.get(
      path: "models/count",
      queryItems: queryItems,
      responseType: ModelsCountResponse.self,
      options: options
    )
  }

  public func getModel(
    author: String,
    slug: String,
    options: RequestOptions? = nil
  ) async throws -> ModelResponse {
    try await transport.get(
      path: .preEscaped("model/\(escapePathSegment(author))/\(escapePathSegment(slug))"),
      responseType: ModelResponse.self,
      options: options
    )
  }

  public func getCredits(options: RequestOptions? = nil) async throws -> CreditsResponse {
    try await transport.get(path: "credits", responseType: CreditsResponse.self, options: options)
  }

  public func getCurrentKey(options: RequestOptions? = nil) async throws -> CurrentKeyResponse {
    try await transport.get(path: "key", responseType: CurrentKeyResponse.self, options: options)
  }

  /// Exchanges a code without sending a bearer key, even when this client has one configured.
  /// Throws `OpenRouterError.unauthenticatedSessionRequired` if the session has an Authorization header.
  public func exchangeAuthCodeForAPIKey(
    _ request: ExchangeAuthCodeForAPIKeyRequest,
    options: RequestOptions? = nil
  ) async throws -> ExchangeAuthCodeForAPIKeyResponse {
    try await transport.post(
      path: "auth/keys",
      requestBody: request,
      responseType: ExchangeAuthCodeForAPIKeyResponse.self,
      requiresAPIKey: false,
      options: options
    )
  }

  public func createAuthKeysCode(
    _ request: CreateAuthKeysCodeRequest,
    options: RequestOptions? = nil
  ) async throws -> CreateAuthKeysCodeResponse {
    try await transport.post(
      path: "auth/keys/code",
      requestBody: request,
      responseType: CreateAuthKeysCodeResponse.self,
      options: options
    )
  }

  /// Lists BYOK credentials using a management key. Nil filters use server defaults.
  public func listBYOKKeys(
    offset: Int? = nil, limit: Int? = nil, workspaceID: String? = nil,
    provider: String? = nil, options: RequestOptions? = nil
  ) async throws -> ListBYOKKeysResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    if let workspaceID { queryItems.append(.init(name: "workspace_id", value: workspaceID)) }
    if let provider { queryItems.append(.init(name: "provider", value: provider)) }
    return try await transport.get(
      path: "byok", queryItems: queryItems,
      responseType: ListBYOKKeysResponse.self, options: options)
  }

  /// Creates a write-only provider credential using a management key.
  public func createBYOKKey(_ request: CreateBYOKKeyRequest, options: RequestOptions? = nil)
    async throws -> CreateBYOKKeyResponse
  {
    try await transport.post(
      path: "byok", requestBody: request,
      responseType: CreateBYOKKeyResponse.self, options: options)
  }

  /// Gets a masked credential using a management key.
  public func getBYOKKey(id: String, options: RequestOptions? = nil) async throws
    -> GetBYOKKeyResponse
  {
    try await transport.get(
      path: .preEscaped("byok/\(escapePathSegment(id))"),
      responseType: GetBYOKKeyResponse.self, options: options)
  }

  /// Updates a credential, optionally rotating its secret, using a management key.
  public func updateBYOKKey(
    id: String, _ request: UpdateBYOKKeyRequest, options: RequestOptions? = nil
  )
    async throws -> UpdateBYOKKeyResponse
  {
    try await transport.patch(
      path: .preEscaped("byok/\(escapePathSegment(id))"), requestBody: request,
      responseType: UpdateBYOKKeyResponse.self, options: options)
  }

  /// Soft-deletes a credential and wipes its secret using a management key.
  public func deleteBYOKKey(id: String, options: RequestOptions? = nil) async throws
    -> DeleteBYOKKeyResponse
  {
    try await transport.delete(
      path: .preEscaped("byok/\(escapePathSegment(id))"),
      responseType: DeleteBYOKKeyResponse.self, options: options)
  }

  public var byok: BYOKResource { BYOKResource(client: self) }

  public struct BYOKResource: Sendable {
    let client: OpenRouterClient
    public func list(
      offset: Int? = nil, limit: Int? = nil, workspaceID: String? = nil,
      provider: String? = nil, options: RequestOptions? = nil
    ) async throws -> ListBYOKKeysResponse {
      try await client.listBYOKKeys(
        offset: offset, limit: limit, workspaceID: workspaceID,
        provider: provider, options: options)
    }
    public func create(_ request: CreateBYOKKeyRequest, options: RequestOptions? = nil) async throws
      -> CreateBYOKKeyResponse
    {
      try await client.createBYOKKey(request, options: options)
    }
    public func get(id: String, options: RequestOptions? = nil) async throws -> GetBYOKKeyResponse {
      try await client.getBYOKKey(id: id, options: options)
    }
    public func update(id: String, _ request: UpdateBYOKKeyRequest, options: RequestOptions? = nil)
      async throws -> UpdateBYOKKeyResponse
    {
      try await client.updateBYOKKey(id: id, request, options: options)
    }
    public func delete(id: String, options: RequestOptions? = nil) async throws
      -> DeleteBYOKKeyResponse
    {
      try await client.deleteBYOKKey(id: id, options: options)
    }
  }

  /// Lists budgets using a management key. The workspace UUID or slug is one path segment.
  public func listWorkspaceBudgets(workspaceRef: String, options: RequestOptions? = nil)
    async throws -> WorkspaceBudgetsResponse
  {
    try await transport.get(
      path: .preEscaped("workspaces/\(escapePathSegment(workspaceRef))/budgets"),
      responseType: WorkspaceBudgetsResponse.self, options: options)
  }

  /// Gets one budget using a management key.
  public func getWorkspaceBudget(
    workspaceRef: String, interval: WorkspaceBudgetInterval, options: RequestOptions? = nil
  ) async throws -> WorkspaceBudgetResponse {
    try await transport.get(
      path: .preEscaped(
        "workspaces/\(escapePathSegment(workspaceRef))/budgets/\(interval.rawValue)"),
      responseType: WorkspaceBudgetResponse.self, options: options)
  }

  /// Creates or updates a budget using a management key. Enforcement is immediate.
  /// The server requires positive limits and lifetime > monthly > weekly > daily.
  public func upsertWorkspaceBudget(
    workspaceRef: String, interval: WorkspaceBudgetInterval,
    _ request: UpsertWorkspaceBudgetRequest, options: RequestOptions? = nil
  ) async throws -> WorkspaceBudgetResponse {
    try await transport.put(
      path: .preEscaped(
        "workspaces/\(escapePathSegment(workspaceRef))/budgets/\(interval.rawValue)"),
      requestBody: request, responseType: WorkspaceBudgetResponse.self, options: options)
  }

  /// Deletes only this interval using a management key, without resetting workspace BYOK settings.
  /// Returns deleted even when the interval was already absent.
  public func deleteWorkspaceBudget(
    workspaceRef: String, interval: WorkspaceBudgetInterval, options: RequestOptions? = nil
  ) async throws -> DeleteWorkspaceBudgetResponse {
    try await transport.delete(
      path: .preEscaped(
        "workspaces/\(escapePathSegment(workspaceRef))/budgets/\(interval.rawValue)"),
      responseType: DeleteWorkspaceBudgetResponse.self, options: options)
  }

  /// Lists organization members using a management API key.
  /// Nil pagination uses server defaults (offset: 0, limit: 50).
  /// The server validates offset >= 0 and limit in 1...100.
  public func listOrganizationMembers(
    offset: Int? = nil,
    limit: Int? = nil,
    options: RequestOptions? = nil
  ) async throws -> OrganizationMembersResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: "organization/members", queryItems: queryItems,
      responseType: OrganizationMembersResponse.self, options: options)
  }

  /// Lists workspace members using a management API key. The default workspace
  /// returns all organization members through implicit membership.
  /// Nil pagination uses server defaults (offset: 0, limit: 50).
  /// The server validates offset >= 0 and limit in 1...100.
  public func listWorkspaceMembers(
    id: String, offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil
  ) async throws -> WorkspaceMembersResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: .preEscaped("workspaces/\(escapePathSegment(id))/members"), queryItems: queryItems,
      responseType: WorkspaceMembersResponse.self, options: options)
  }

  /// Lists workspaces using a management API key.
  ///
  /// - Parameters:
  ///   - offset: Starting offset (API minimum: 0). Nil uses the server default.
  ///   - limit: Page size (API range: 1...100; server default: 50).
  ///     Nil uses the server default.
  ///   - options: Per-request overrides.
  public func listWorkspaces(
    offset: Int? = nil,
    limit: Int? = nil,
    options: RequestOptions? = nil
  ) async throws -> WorkspacesResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: "workspaces", queryItems: queryItems, responseType: WorkspacesResponse.self,
      options: options
    )
  }

  /// Gets a workspace using a management API key.
  ///
  /// - Parameters:
  ///   - id: The workspace UUID or slug, treated as a single path segment.
  ///   - options: Per-request overrides.
  public func getWorkspace(id: String, options: RequestOptions? = nil) async throws
    -> WorkspaceResponse
  {
    try await transport.get(
      path: .preEscaped("workspaces/\(escapePathSegment(id))"),
      responseType: WorkspaceResponse.self,
      options: options
    )
  }

  /// Creates a workspace using a management API key.
  public func createWorkspace(_ request: CreateWorkspaceRequest, options: RequestOptions? = nil)
    async throws -> WorkspaceResponse
  {
    try await transport.post(
      path: "workspaces", requestBody: request, responseType: WorkspaceResponse.self,
      options: options)
  }

  /// Updates a workspace using a management API key. IDs are single path segments.
  public func updateWorkspace(
    id: String, _ request: UpdateWorkspaceRequest, options: RequestOptions? = nil
  ) async throws -> WorkspaceResponse {
    try await transport.patch(
      path: .preEscaped("workspaces/\(escapePathSegment(id))"), requestBody: request,
      responseType: WorkspaceResponse.self, options: options)
  }

  /// Permanently deletes a workspace, its budgets and guardrails, and disables its classifiers
  /// and broadcast destinations. Active API keys must first be removed.
  /// Opting into default workspace deletion also permanently disables unscoped inference keys;
  /// management and provisioning keys are retained. Requires a management API key.
  public func deleteWorkspace(
    id: String, confirmDefaultWorkspaceDeletion: Bool = false, options: RequestOptions? = nil
  ) async throws -> DeleteWorkspaceResponse {
    let queryItems: [URLQueryItem] =
      confirmDefaultWorkspaceDeletion
      ? [.init(name: "confirm_default_workspace_deletion", value: "true")] : []
    return try await transport.delete(
      path: .preEscaped("workspaces/\(escapePathSegment(id))"), queryItems: queryItems,
      responseType: DeleteWorkspaceResponse.self, options: options)
  }

  /// Adds 1...100 users with their organization roles. Requires a management API key.
  public func addWorkspaceMembers(
    id: String, _ request: WorkspaceMembersRequest, options: RequestOptions? = nil
  ) async throws -> AddWorkspaceMembersResponse {
    try await transport.post(
      path: .preEscaped("workspaces/\(escapePathSegment(id))/members/add"), requestBody: request,
      responseType: AddWorkspaceMembersResponse.self, options: options)
  }

  /// Removes 1...100 users. Active workspace API keys block removal; change SCIM-managed
  /// members through the identity provider. Requires a management API key.
  public func removeWorkspaceMembers(
    id: String, _ request: WorkspaceMembersRequest, options: RequestOptions? = nil
  ) async throws -> RemoveWorkspaceMembersResponse {
    try await transport.post(
      path: .preEscaped("workspaces/\(escapePathSegment(id))/members/remove"), requestBody: request,
      responseType: RemoveWorkspaceMembersResponse.self, options: options)
  }

  public func listAPIKeys(
    includeDisabled: Bool? = nil,
    offset: Int? = nil,
    workspaceID: UUID? = nil,
    options: RequestOptions? = nil
  ) async throws -> APIKeysResponse {
    var queryItems: [URLQueryItem] = []
    if let includeDisabled {
      queryItems.append(.init(name: "include_disabled", value: includeDisabled ? "true" : "false"))
    }
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let workspaceID {
      queryItems.append(.init(name: "workspace_id", value: workspaceID.uuidString))
    }
    return try await transport.get(
      path: "keys", queryItems: queryItems, responseType: APIKeysResponse.self, options: options)
  }

  public func getAPIKey(hash: String, options: RequestOptions? = nil) async throws -> APIKeyResponse
  {
    try await transport.get(
      path: .preEscaped("keys/\(escapePathSegment(hash))"),
      responseType: APIKeyResponse.self,
      options: options
    )
  }

  public func createAPIKey(
    _ request: CreateAPIKeyRequest,
    options: RequestOptions? = nil
  ) async throws -> CreateAPIKeyResponse {
    try await transport.post(
      path: "keys", requestBody: request, responseType: CreateAPIKeyResponse.self, options: options)
  }

  public func updateAPIKey(
    hash: String,
    _ request: UpdateAPIKeyRequest,
    options: RequestOptions? = nil
  ) async throws -> APIKeyResponse {
    try await transport.patch(
      path: .preEscaped("keys/\(escapePathSegment(hash))"),
      requestBody: request,
      responseType: APIKeyResponse.self,
      options: options
    )
  }

  public func deleteAPIKey(
    hash: String,
    options: RequestOptions? = nil
  ) async throws -> DeleteAPIKeyResponse {
    try await transport.delete(
      path: .preEscaped("keys/\(escapePathSegment(hash))"),
      responseType: DeleteAPIKeyResponse.self,
      options: options
    )
  }

  public func getUserActivity(
    date: String? = nil,
    apiKeyHash: String? = nil,
    userID: String? = nil,
    groupBy: String? = nil,
    workspaceID: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> ActivityResponse {
    var queryItems: [URLQueryItem] = []
    if let date { queryItems.append(URLQueryItem(name: "date", value: date)) }
    if let apiKeyHash { queryItems.append(URLQueryItem(name: "api_key_hash", value: apiKeyHash)) }
    if let userID { queryItems.append(URLQueryItem(name: "user_id", value: userID)) }
    if let groupBy { queryItems.append(URLQueryItem(name: "group_by", value: groupBy)) }
    if let workspaceID { queryItems.append(URLQueryItem(name: "workspace_id", value: workspaceID)) }
    return try await transport.get(
      path: "activity",
      queryItems: queryItems,
      responseType: ActivityResponse.self,
      options: options
    )
  }

  public func getRankingsDaily(
    startDate: String? = nil,
    endDate: String? = nil,
    period: String? = nil,
    modality: String? = nil,
    contextBucket: String? = nil,
    category: String? = nil,
    languageType: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> RankingsDailyResponse {
    var queryItems: [URLQueryItem] = []
    if let startDate { queryItems.append(URLQueryItem(name: "start_date", value: startDate)) }
    if let endDate { queryItems.append(URLQueryItem(name: "end_date", value: endDate)) }
    if let period { queryItems.append(URLQueryItem(name: "period", value: period)) }
    if let modality { queryItems.append(URLQueryItem(name: "modality", value: modality)) }
    if let contextBucket {
      queryItems.append(URLQueryItem(name: "context_bucket", value: contextBucket))
    }
    if let category { queryItems.append(URLQueryItem(name: "category", value: category)) }
    if let languageType {
      queryItems.append(URLQueryItem(name: "language_type", value: languageType))
    }
    return try await transport.get(
      path: "datasets/rankings-daily",
      queryItems: queryItems,
      responseType: RankingsDailyResponse.self,
      options: options
    )
  }

  public func listImageModels(options: RequestOptions? = nil) async throws
    -> ImageModelsListResponse
  {
    try await transport.get(
      path: "images/models", responseType: ImageModelsListResponse.self, options: options)
  }

  public func listImageModelEndpoints(
    author: String, slug: String, options: RequestOptions? = nil
  ) async throws -> ImageModelEndpointsResponse {
    try await transport.get(
      path: .preEscaped(
        "images/models/\(escapePathSegment(author))/\(escapePathSegment(slug))/endpoints"),
      responseType: ImageModelEndpointsResponse.self,
      options: options
    )
  }

  public func listProviders(options: RequestOptions? = nil) async throws -> ProvidersResponse {
    try await transport.get(
      path: "providers", responseType: ProvidersResponse.self, options: options)
  }

  public func listModelEndpoints(
    author: String,
    slug: String,
    options: RequestOptions? = nil
  ) async throws -> ModelEndpointsResponse {
    try await transport.get(
      path: .preEscaped(
        "models/\(escapePathSegment(author))/\(escapePathSegment(slug))/endpoints"),
      responseType: ModelEndpointsResponse.self,
      options: options
    )
  }

  public func listZDREndpoints(options: RequestOptions? = nil) async throws -> ZDREndpointsResponse
  {
    try await transport.get(
      path: "endpoints/zdr", responseType: ZDREndpointsResponse.self, options: options)
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
  public var responses: ResponsesResource { ResponsesResource(client: self) }
  public var messages: MessagesResource { MessagesResource(client: self) }
  public var embeddings: EmbeddingsResource { EmbeddingsResource(client: self) }
  public var audio: AudioResource { AudioResource(client: self) }
  public var videos: VideosResource { VideosResource(client: self) }
  public var images: ImagesResource { ImagesResource(client: self) }
  public var rerank: RerankResource { RerankResource(client: self) }
  public var generations: GenerationsResource { GenerationsResource(client: self) }
  public var models: ModelsResource { ModelsResource(client: self) }
  public var credits: CreditsResource { CreditsResource(client: self) }
  public var keys: KeysResource { KeysResource(client: self) }
  public var workspaces: WorkspacesResource { WorkspacesResource(client: self) }
  public var organization: OrganizationResource { OrganizationResource(client: self) }
  public var auth: AuthResource { AuthResource(client: self) }
  public var activity: ActivityResource { ActivityResource(client: self) }
  public var datasets: DatasetsResource { DatasetsResource(client: self) }
  public var providers: ProvidersResource { ProvidersResource(client: self) }
  public var endpoints: EndpointsResource { EndpointsResource(client: self) }
  public var files: FilesResource { FilesResource(client: self) }
  public var batches: BatchesResource { BatchesResource(client: self) }

  public struct BatchesResource: Sendable {
    fileprivate let client: OpenRouterClient

    /// Submits potentially costly provider work; no retries are performed by default.
    public func create(
      _ request: CreateBatchRequest, options: RequestOptions? = nil
    ) async throws -> BatchObject {
      try await client.createBatch(request, options: options)
    }

    public func list(
      limit: Int? = nil, after: String? = nil, statuses: [String]? = nil,
      createdAfter: String? = nil, createdBefore: String? = nil, options: RequestOptions? = nil
    ) async throws -> BatchListResponse {
      try await client.listBatches(
        limit: limit, after: after, statuses: statuses, createdAfter: createdAfter,
        createdBefore: createdBefore, options: options)
    }

    public func get(id: String, options: RequestOptions? = nil) async throws -> BatchObject {
      try await client.getBatch(id: id, options: options)
    }

    /// Irreversibly purges terminal batch requests/results, not billing or audit records.
    /// This is not cancellation; eligibility is checked by the server, without a status preflight.
    /// Default retries remain disabled.
    public func delete(
      id: String, options: RequestOptions? = nil
    ) async throws -> BatchDeleteResponse {
      try await client.deleteBatch(id: id, options: options)
    }
  }

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

  public struct ResponsesResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func create(
      _ request: ResponsesRequest,
      options: RequestOptions? = nil
    ) async throws -> ResponsesResponse {
      try await client.createResponse(request, options: options)
    }

    public func stream(
      _ request: ResponsesRequest
    ) -> AsyncThrowingStream<ResponsesStreamEvent, Error> {
      client.createResponseStream(request)
    }
  }

  public struct MessagesResource: Sendable {
    fileprivate let client: OpenRouterClient
    public func create(_ request: MessagesRequest, options: RequestOptions? = nil) async throws
      -> MessagesResponse
    { try await client.createMessage(request, options: options) }
    public func stream(_ request: MessagesRequest) -> AsyncThrowingStream<
      MessagesStreamEvent, Error
    > { client.createMessageStream(request) }
  }

  public struct EmbeddingsResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func create(
      _ request: EmbeddingRequest,
      options: RequestOptions? = nil
    ) async throws -> EmbeddingResponse {
      try await client.createEmbeddings(request, options: options)
    }

    public func listModels(
      offset: Int? = nil,
      limit: Int? = nil,
      options: RequestOptions? = nil
    ) async throws -> EmbeddingsModelsResponse {
      try await client.listEmbeddingsModels(offset: offset, limit: limit, options: options)
    }
  }

  public struct AudioResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func speech(
      _ request: AudioSpeechRequest,
      options: RequestOptions? = nil
    ) async throws -> Data {
      try await client.createAudioSpeech(request, options: options)
    }

    public func transcribe(
      _ request: AudioTranscriptionRequest,
      options: RequestOptions? = nil
    ) async throws -> AudioTranscriptionResponse {
      try await client.createAudioTranscriptions(request, options: options)
    }
  }

  public struct RerankResource: Sendable {
    fileprivate let client: OpenRouterClient
    public func create(_ request: RerankRequest, options: RequestOptions? = nil) async throws
      -> RerankResponse
    { try await client.createRerank(request, options: options) }
  }

  public struct ImagesResource: Sendable {
    fileprivate let client: OpenRouterClient

    /// Starts provider work and may incur costs; requires a normal API key with the
    /// server-required authorization scope. Nonstreaming only. `n` is an upper bound,
    /// and a seed does not guarantee deterministic output.
    public func create(
      _ request: ImageGenerationRequest, options: RequestOptions? = nil
    ) async throws -> ImageGenerationResponse {
      try await client.createImage(request, options: options)
    }

    public func stream(
      _ request: ImageGenerationRequest, options: RequestOptions? = nil
    ) -> AsyncThrowingStream<ImageGenerationStreamEvent, Error> {
      client.createImageStream(request, options: options)
    }

    public var models: ModelsResource { ModelsResource(client: client) }

    public struct ModelsResource: Sendable {
      fileprivate let client: OpenRouterClient

      public func list(options: RequestOptions? = nil) async throws -> ImageModelsListResponse {
        try await client.listImageModels(options: options)
      }

      public func endpoints(
        author: String, slug: String, options: RequestOptions? = nil
      ) async throws -> ImageModelEndpointsResponse {
        try await client.listImageModelEndpoints(author: author, slug: slug, options: options)
      }
    }
  }

  public struct VideosResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func create(_ request: VideoRequest, options: RequestOptions? = nil) async throws
      -> VideoResponse
    {
      try await client.createVideos(request, options: options)
    }

    public func get(jobId: String, options: RequestOptions? = nil) async throws -> VideoResponse {
      try await client.getVideos(jobId: jobId, options: options)
    }

    public func content(
      _ request: VideoContentRequest,
      options: RequestOptions? = nil
    ) async throws -> VideoContentResponse {
      try await client.listVideosContent(request, options: options)
    }

    public var models: ModelsResource { ModelsResource(client: client) }

    public struct ModelsResource: Sendable {
      fileprivate let client: OpenRouterClient

      public func list(options: RequestOptions? = nil) async throws -> VideoModelsListResponse {
        try await client.listVideosModels(options: options)
      }
    }
  }

  public struct GenerationsResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func get(
      id: String,
      options: RequestOptions? = nil
    ) async throws -> GenerationResponse {
      try await client.getGeneration(id: id, options: options)
    }

    public func content(
      id: String,
      options: RequestOptions? = nil
    ) async throws -> GenerationContentResponse {
      try await client.listGenerationContent(id: id, options: options)
    }
  }

  public struct ModelsResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func list(options: RequestOptions? = nil) async throws -> ModelsResponse {
      try await client.listModels(options: options)
    }

    public func listUser(
      offset: Int? = nil,
      limit: Int? = nil,
      options: RequestOptions? = nil
    ) async throws -> UserModelsResponse {
      try await client.listModelsUser(offset: offset, limit: limit, options: options)
    }

    public func count(
      outputModalities: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> ModelsCountResponse {
      try await client.listModelsCount(outputModalities: outputModalities, options: options)
    }

    public func get(author: String, slug: String, options: RequestOptions? = nil) async throws
      -> ModelResponse
    {
      try await client.getModel(author: author, slug: slug, options: options)
    }
  }

  public struct FilesResource: Sendable {
    fileprivate let client: OpenRouterClient

    /// Irreversibly deletes a file. Explicit caller authorization is required.
    /// Uploaded/downloadable status is irrelevant to deletion.
    public func delete(
      id: String, workspaceID: UUID? = nil, provider: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> FileDeleteResponse {
      try await client.deleteFile(
        id: id, workspaceID: workspaceID, provider: provider, options: options)
    }

    public func list(
      limit: Int? = nil, cursor: String? = nil, workspaceID: UUID? = nil,
      provider: String? = nil, after: String? = nil, afterID: String? = nil,
      beforeID: String? = nil, order: String? = nil, options: RequestOptions? = nil
    ) async throws -> FileListResponse {
      try await client.listFiles(
        limit: limit, cursor: cursor, workspaceID: workspaceID, provider: provider,
        after: after, afterID: afterID, beforeID: beforeID, order: order, options: options)
    }

    public func get(
      id: String, workspaceID: UUID? = nil, provider: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> FileResponse {
      try await client.getFile(
        id: id, workspaceID: workspaceID, provider: provider, options: options)
    }

    public func content(
      id: String, workspaceID: UUID? = nil, provider: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> FileContentDownload {
      try await client.downloadFileContent(
        id: id, workspaceID: workspaceID, provider: provider, options: options)
    }

    public func upload(
      _ file: FileUpload,
      workspaceID: UUID? = nil,
      options: RequestOptions? = nil
    ) async throws -> FileMetadata {
      try await client.uploadFile(file, workspaceID: workspaceID, options: options)
    }
  }

  public struct CreditsResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func get(options: RequestOptions? = nil) async throws -> CreditsResponse {
      try await client.getCredits(options: options)
    }
  }

  /// Organization member discovery requiring a management API key.
  public struct OrganizationResource: Sendable {
    fileprivate let client: OpenRouterClient

    /// Iterates members, fetching pages only as needed. The server validates
    /// offset >= 0 and limit in 1...100. Errors terminate the iterator.
    public func members(
      offset: Int = 0, limit: Int = 50, options: RequestOptions? = nil
    ) -> OffsetPaginatedSequence<OrganizationMember> {
      OffsetPaginatedSequence(offset: offset) { offset in
        let page = try await client.listOrganizationMembers(
          offset: offset, limit: limit, options: options)
        return (page.data, page.totalCount)
      }
    }

    /// Lists members. Nil pagination uses server defaults (offset: 0, limit: 50).
    /// The server validates offset >= 0 and limit in 1...100.
    public func listMembers(
      offset: Int? = nil,
      limit: Int? = nil,
      options: RequestOptions? = nil
    ) async throws -> OrganizationMembersResponse {
      try await client.listOrganizationMembers(offset: offset, limit: limit, options: options)
    }
  }

  /// Workspace endpoints requiring a management API key.
  public struct WorkspacesResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func listBudgets(workspaceRef: String, options: RequestOptions? = nil) async throws
      -> WorkspaceBudgetsResponse
    {
      try await client.listWorkspaceBudgets(workspaceRef: workspaceRef, options: options)
    }

    public func getBudget(
      workspaceRef: String, interval: WorkspaceBudgetInterval, options: RequestOptions? = nil
    ) async throws -> WorkspaceBudgetResponse {
      try await client.getWorkspaceBudget(
        workspaceRef: workspaceRef, interval: interval, options: options)
    }

    public func upsertBudget(
      workspaceRef: String, interval: WorkspaceBudgetInterval,
      _ request: UpsertWorkspaceBudgetRequest, options: RequestOptions? = nil
    ) async throws -> WorkspaceBudgetResponse {
      try await client.upsertWorkspaceBudget(
        workspaceRef: workspaceRef, interval: interval, request, options: options)
    }

    public func deleteBudget(
      workspaceRef: String, interval: WorkspaceBudgetInterval, options: RequestOptions? = nil
    ) async throws -> DeleteWorkspaceBudgetResponse {
      try await client.deleteWorkspaceBudget(
        workspaceRef: workspaceRef, interval: interval, options: options)
    }

    public func create(_ request: CreateWorkspaceRequest, options: RequestOptions? = nil)
      async throws -> WorkspaceResponse
    {
      try await client.createWorkspace(request, options: options)
    }

    public func update(
      id: String, _ request: UpdateWorkspaceRequest, options: RequestOptions? = nil
    ) async throws -> WorkspaceResponse {
      try await client.updateWorkspace(id: id, request, options: options)
    }

    /// See `deleteWorkspace` for destructive effects of default workspace confirmation.
    public func delete(
      id: String, confirmDefaultWorkspaceDeletion: Bool = false, options: RequestOptions? = nil
    ) async throws -> DeleteWorkspaceResponse {
      try await client.deleteWorkspace(
        id: id, confirmDefaultWorkspaceDeletion: confirmDefaultWorkspaceDeletion, options: options)
    }

    /// Iterates memberships, fetching pages only as needed. The server validates
    /// offset >= 0 and limit in 1...100. Errors terminate the iterator.
    public func members(
      id: String, offset: Int = 0, limit: Int = 50, options: RequestOptions? = nil
    ) -> OffsetPaginatedSequence<WorkspaceMembership> {
      OffsetPaginatedSequence(offset: offset) { offset in
        let page = try await client.listWorkspaceMembers(
          id: id, offset: offset, limit: limit, options: options)
        return (page.data, page.totalCount)
      }
    }

    /// Lists members by workspace UUID or slug, encoded as a single path segment.
    public func listMembers(
      id: String, offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil
    ) async throws -> WorkspaceMembersResponse {
      try await client.listWorkspaceMembers(id: id, offset: offset, limit: limit, options: options)
    }

    public func addMembers(
      id: String, _ request: WorkspaceMembersRequest, options: RequestOptions? = nil
    ) async throws -> AddWorkspaceMembersResponse {
      try await client.addWorkspaceMembers(id: id, request, options: options)
    }

    public func removeMembers(
      id: String, _ request: WorkspaceMembersRequest, options: RequestOptions? = nil
    ) async throws -> RemoveWorkspaceMembersResponse {
      try await client.removeWorkspaceMembers(id: id, request, options: options)
    }

    /// Lists workspaces. Offset must be at least 0 and limit must be 1...100.
    /// Nil pagination values use server defaults (limit: 50).
    public func list(
      offset: Int? = nil,
      limit: Int? = nil,
      options: RequestOptions? = nil
    ) async throws -> WorkspacesResponse {
      try await client.listWorkspaces(offset: offset, limit: limit, options: options)
    }

    /// Gets a workspace by UUID or slug, treated as a single path segment.
    public func get(id: String, options: RequestOptions? = nil) async throws -> WorkspaceResponse {
      try await client.getWorkspace(id: id, options: options)
    }
  }

  /// Accesses metadata for the key used to authenticate the current client.
  public struct KeysResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func current(options: RequestOptions? = nil) async throws -> CurrentKeyResponse {
      try await client.getCurrentKey(options: options)
    }

    public func list(
      includeDisabled: Bool? = nil,
      offset: Int? = nil,
      workspaceID: UUID? = nil,
      options: RequestOptions? = nil
    ) async throws -> APIKeysResponse {
      try await client.listAPIKeys(
        includeDisabled: includeDisabled, offset: offset, workspaceID: workspaceID, options: options
      )
    }

    public func get(hash: String, options: RequestOptions? = nil) async throws -> APIKeyResponse {
      try await client.getAPIKey(hash: hash, options: options)
    }

    public func create(
      _ request: CreateAPIKeyRequest,
      options: RequestOptions? = nil
    ) async throws -> CreateAPIKeyResponse {
      try await client.createAPIKey(request, options: options)
    }

    public func update(
      hash: String,
      _ request: UpdateAPIKeyRequest,
      options: RequestOptions? = nil
    ) async throws -> APIKeyResponse {
      try await client.updateAPIKey(hash: hash, request, options: options)
    }

    public func delete(
      hash: String,
      options: RequestOptions? = nil
    ) async throws -> DeleteAPIKeyResponse {
      try await client.deleteAPIKey(hash: hash, options: options)
    }
  }

  /// Authorization-code creation (management key) and unauthenticated exchange.
  public struct AuthResource: Sendable {
    fileprivate let client: OpenRouterClient
    public var keys: KeysResource { KeysResource(client: client) }

    public struct KeysResource: Sendable {
      fileprivate let client: OpenRouterClient

      public func exchange(
        _ request: ExchangeAuthCodeForAPIKeyRequest,
        options: RequestOptions? = nil
      ) async throws -> ExchangeAuthCodeForAPIKeyResponse {
        try await client.exchangeAuthCodeForAPIKey(request, options: options)
      }

      public func createCode(
        _ request: CreateAuthKeysCodeRequest,
        options: RequestOptions? = nil
      ) async throws -> CreateAuthKeysCodeResponse {
        try await client.createAuthKeysCode(request, options: options)
      }
    }
  }

  public struct ActivityResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func get(
      date: String? = nil,
      apiKeyHash: String? = nil,
      userID: String? = nil,
      groupBy: String? = nil,
      workspaceID: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> ActivityResponse {
      try await client.getUserActivity(
        date: date,
        apiKeyHash: apiKeyHash,
        userID: userID,
        groupBy: groupBy,
        workspaceID: workspaceID,
        options: options
      )
    }
  }

  public struct DatasetsResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func rankingsDaily(
      startDate: String? = nil,
      endDate: String? = nil,
      period: String? = nil,
      modality: String? = nil,
      contextBucket: String? = nil,
      category: String? = nil,
      languageType: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> RankingsDailyResponse {
      try await client.getRankingsDaily(
        startDate: startDate, endDate: endDate, period: period, modality: modality,
        contextBucket: contextBucket, category: category, languageType: languageType,
        options: options)
    }
  }

  public struct ProvidersResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func list(options: RequestOptions? = nil) async throws -> ProvidersResponse {
      try await client.listProviders(options: options)
    }
  }

  public struct EndpointsResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func list(
      author: String,
      slug: String,
      options: RequestOptions? = nil
    ) async throws -> ModelEndpointsResponse {
      try await client.listModelEndpoints(author: author, slug: slug, options: options)
    }

    public func listZDR(options: RequestOptions? = nil) async throws -> ZDREndpointsResponse {
      try await client.listZDREndpoints(options: options)
    }
  }
}

public struct OpenRouterDebugEvent: Sendable, Equatable {
  public var message: String
  public var method: String?
  public var path: String?
  public var statusCode: Int?
  public var retryAttempt: Int?

  public init(
    message: String,
    method: String? = nil,
    path: String? = nil,
    statusCode: Int? = nil,
    retryAttempt: Int? = nil
  ) {
    self.message = message
    self.method = method
    self.path = path
    self.statusCode = statusCode
    self.retryAttempt = retryAttempt
  }
}

public struct RequestOptions: Sendable, Equatable {
  public var timeout: TimeInterval?
  public var retries: RetryPolicy?
  public var baseURL: URL?
  public var extraHeaders: [String: String]

  public init(
    timeout: TimeInterval? = nil,
    retries: RetryPolicy? = nil,
    baseURL: URL? = nil,
    extraHeaders: [String: String] = [:]
  ) {
    self.timeout = timeout
    self.retries = retries
    self.baseURL = baseURL
    self.extraHeaders = extraHeaders
  }
}

public enum RetryPolicy: Sendable, Equatable {
  case none
  case backoff(
    maxAttempts: Int,
    initialDelay: TimeInterval,
    maxDelay: TimeInterval,
    exponent: Double,
    retryStatusCodes: Set<Int>,
    retryConnectionErrors: Bool
  )
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
    public var debugLogger: (@Sendable (OpenRouterDebugEvent) -> Void)?

    // Stored privately until transport layer is implemented.
    var apiKey: String?

    public init(
      baseURL: URL = URL(string: "https://openrouter.ai/api/v1/")!,
      timeout: TimeInterval = 60,
      httpReferer: String? = nil,
      appTitle: String? = nil,
      appCategories: [String]? = nil,
      experimentalMetadata: String? = nil,
      xTitle: String? = nil,
      debugLogger: (@Sendable (OpenRouterDebugEvent) -> Void)? = nil
    ) {
      self.baseURL = baseURL
      self.timeout = timeout
      self.httpReferer = httpReferer
      self.appTitle = appTitle
      self.appCategories = appCategories
      self.experimentalMetadata = experimentalMetadata
      self.xTitle = xTitle
      self.debugLogger = debugLogger
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
  /// Remove session-level Authorization from `URLSessionConfiguration.httpAdditionalHeaders`
  /// before creating the session used for authorization code exchange.
  case unauthenticatedSessionRequired
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
    case (.unauthenticatedSessionRequired, .unauthenticatedSessionRequired):
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

extension OpenRouterError {
  static func messageStreamError(from event: MessagesStreamEvent) -> Self {
    let payload = event.error ?? event.rawPayload
    var code: Int?
    var message: String?
    if case .object(let object) = payload {
      if case .number(let value)? = object["code"] { code = Int(value) }
      if case .string(let value)? = object["message"] { message = value }
    }
    return .apiError(
      statusCode: code ?? 0, code: code, message: message ?? "Messages stream error",
      rawBody: try? String(data: JSONEncoder().encode(payload), encoding: .utf8))
  }

  static func streamEventError(from event: ResponsesStreamEvent) -> Self {
    let payload = event.rawPayload
    let errorPayload: JSONValue
    if case .object(let object) = payload, let error = object["error"] {
      errorPayload = error
    } else if case .object(let object) = payload,
      case .object(let response)? = object["response"],
      let error = response["error"]
    {
      errorPayload = error
    } else {
      errorPayload = payload
    }

    var code: Int?
    var message: String?
    if case .object(let object) = errorPayload {
      if case .number(let value)? = object["code"] { code = Int(value) }
      if case .string(let value)? = object["message"] { message = value }
    }
    if message == nil { message = "Responses stream event: \(event.type)" }
    let rawBody = try? String(data: JSONEncoder().encode(payload), encoding: .utf8)
    return .apiError(statusCode: code ?? 0, code: code, message: message, rawBody: rawBody)
  }

  public var statusCode: Int? {
    guard case .apiError(let statusCode, _, _, _) = self else { return nil }
    return statusCode
  }

  public var isUnauthorized: Bool { statusCode == 401 }
  public var isPaymentRequired: Bool { statusCode == 402 }
  public var isRateLimited: Bool { statusCode == 429 }
  public var isBadRequest: Bool { statusCode == 400 }
  public var isForbidden: Bool { statusCode == 403 }
  public var isNotFound: Bool { statusCode == 404 }
  public var isServerError: Bool {
    guard let statusCode else { return false }
    return (500...599).contains(statusCode)
  }

  public var apiCode: Int? {
    guard case .apiError(_, let code, _, _) = self else { return nil }
    return code
  }

  public var isRetryable: Bool {
    guard let statusCode else { return false }
    return ChatCompletionFallbackPolicy.defaultErrorCodes.contains(statusCode)
  }

  public var retryAfter: TimeInterval? {
    guard case .apiError(_, _, _, let rawBody) = self,
      let rawBody,
      let value = OpenRouterError.extractRetryAfter(from: rawBody)
    else { return nil }
    return value
  }

  private static func extractRetryAfter(from rawBody: String) -> TimeInterval? {
    let pattern = #"retry[_\s-]?after"\s*:\s*(\d+(?:\.\d+)?)"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
      return nil
    }
    let ns = rawBody as NSString
    let range = NSRange(location: 0, length: ns.length)
    guard let match = regex.firstMatch(in: rawBody, options: [], range: range),
      match.numberOfRanges > 1
    else { return nil }
    let value = ns.substring(with: match.range(at: 1))
    return TimeInterval(value)
  }
}

private final class StreamMetadataBox: @unchecked Sendable {
  private let lock = NSLock()
  private var continuation: CheckedContinuation<ResponseCacheMetadata?, Error>?
  private var pendingResult: Result<ResponseCacheMetadata?, Error>?
  private var didResume = false

  func makeTask() -> Task<ResponseCacheMetadata?, Error> {
    Task {
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<ResponseCacheMetadata?, Error>) in
        setContinuation(continuation)
      }
    }
  }

  private func setContinuation(_ continuation: CheckedContinuation<ResponseCacheMetadata?, Error>) {
    lock.lock()
    if let pendingResult {
      self.pendingResult = nil
      self.continuation = nil
      lock.unlock()
      resume(continuation, with: pendingResult)
      return
    }
    self.continuation = continuation
    lock.unlock()
  }

  func resume(with result: Result<ResponseCacheMetadata?, Error>) {
    lock.lock()
    guard !didResume else {
      lock.unlock()
      return
    }
    didResume = true
    guard let continuation else {
      pendingResult = result
      lock.unlock()
      return
    }
    self.continuation = nil
    switch result {
    case .success(let metadata):
      lock.unlock()
      continuation.resume(returning: metadata)
    case .failure(let error):
      lock.unlock()
      continuation.resume(throwing: error)
    }
  }

  private func resume(
    _ continuation: CheckedContinuation<ResponseCacheMetadata?, Error>,
    with result: Result<ResponseCacheMetadata?, Error>
  ) {
    switch result {
    case .success(let metadata): continuation.resume(returning: metadata)
    case .failure(let error): continuation.resume(throwing: error)
    }
  }
}

private final class IncrementalStreamRuntime<Element: Sendable>: @unchecked Sendable {
  private let session: URLSession
  private let task: URLSessionDataTask
  private let delegate: IncrementalSSEDelegate<Element>

  init(
    request: URLRequest,
    delegate: IncrementalSSEDelegate<Element>,
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

private struct StreamingImageRequest: Encodable {
  let request: ImageGenerationRequest

  func encode(to encoder: Encoder) throws {
    try request.encode(to: encoder, stream: true)
  }
}

/// Accessed only by the serialized URLSession delegate callbacks for one invocation.
private final class ImageStreamState: @unchecked Sendable {
  var completed = false
  var buffered = false
}

private final class IncrementalSSEDelegate<Element: Sendable>: NSObject, URLSessionDataDelegate,
  @unchecked Sendable
{
  private let transport: HTTPTransport
  private let onMetadata: @Sendable (ResponseCacheMetadata?) -> Void
  private let decode: @Sendable (Data, String?) throws -> Element
  private let onElement: @Sendable (Element) -> Void
  private let onError: @Sendable (Error) -> Void
  private let onDone: @Sendable (Bool) -> Void
  private let decodeBufferedJSON: (@Sendable (Data) throws -> Element)?
  private var isBufferedJSON = false
  private var buffer = Data()
  private var frameLines: [String] = []
  private var errorBuffer = Data()
  private var responseStatusCode: Int?
  private var didTerminate = false

  init(
    transport: HTTPTransport,
    onMetadata: @escaping @Sendable (ResponseCacheMetadata?) -> Void,
    decode: @escaping @Sendable (Data, String?) throws -> Element,
    decodeBufferedJSON: (@Sendable (Data) throws -> Element)? = nil,
    onElement: @escaping @Sendable (Element) -> Void,
    onError: @escaping @Sendable (Error) -> Void,
    onDone: @escaping @Sendable (Bool) -> Void
  ) {
    self.transport = transport
    self.onMetadata = onMetadata
    self.decode = decode
    self.decodeBufferedJSON = decodeBufferedJSON
    self.onElement = onElement
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

    responseStatusCode = http.statusCode

    guard (200..<300).contains(http.statusCode) else {
      completionHandler(.allow)
      return
    }

    onMetadata(transport.parseResponseCacheMetadata(from: http))
    let mediaType = http.value(forHTTPHeaderField: "Content-Type")?
      .split(separator: ";", maxSplits: 1).first?
      .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    isBufferedJSON = decodeBufferedJSON != nil && mediaType == "application/json"
    completionHandler(.allow)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    guard !didTerminate else { return }

    if let responseStatusCode, !(200..<300).contains(responseStatusCode) {
      errorBuffer.append(data)
      return
    }

    buffer.append(data)
    if isBufferedJSON { return }

    while let newlineRange = buffer.range(of: Data([0x0A])) {
      let lineData = buffer.subdata(in: buffer.startIndex..<newlineRange.lowerBound)
      buffer.removeSubrange(buffer.startIndex...newlineRange.lowerBound)
      var line = String(decoding: lineData, as: UTF8.self)
      if line.last == "\r" { line.removeLast() }

      if line.isEmpty {
        if processFrame(session: session) { return }
      } else {
        if line.hasPrefix("data:"), frameContainsCompleteEvent(), processFrame(session: session) {
          return
        }
        frameLines.append(line)
      }
    }
  }

  private func processFrame(session: URLSession?) -> Bool {
    guard !frameLines.isEmpty else { return false }
    let lines = frameLines
    frameLines.removeAll(keepingCapacity: true)
    let frame = SSEParser.parseMetadataFrame(lines: lines)
    guard let event = SSEParser.parseFrame(lines: lines) else { return false }

    switch event {
    case .done:
      didTerminate = true
      onDone(true)
      session?.invalidateAndCancel()
      return true
    case .data(let payload):
      do {
        onElement(try decode(Data(payload.utf8), frame.event))
        return false
      } catch {
        didTerminate = true
        onError(error)
        session?.invalidateAndCancel()
        return true
      }
    }
  }

  /// Accept legacy streams that omit the blank SSE frame delimiter between complete JSON events.
  private func frameContainsCompleteEvent() -> Bool {
    guard let event = SSEParser.parseFrame(lines: frameLines) else { return false }
    switch event {
    case .done:
      return true
    case .data(let payload):
      return (try? JSONSerialization.jsonObject(with: Data(payload.utf8))) != nil
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard !didTerminate else { return }
    if let responseStatusCode, !(200..<300).contains(responseStatusCode) {
      didTerminate = true
      onError(transport.mapAPIError(statusCode: responseStatusCode, data: errorBuffer))
      return
    }

    if let error {
      didTerminate = true
      onError(error)
    } else {
      if isBufferedJSON, let decodeBufferedJSON {
        didTerminate = true
        do {
          onElement(try decodeBufferedJSON(buffer))
          onDone(false)
        } catch {
          onError(error)
        }
        return
      }
      if !buffer.isEmpty {
        var line = String(decoding: buffer, as: UTF8.self)
        if line.last == "\r" { line.removeLast() }
        if !line.isEmpty {
          if line.hasPrefix("data:"), frameContainsCompleteEvent(), processFrame(session: nil) {
            return
          }
          frameLines.append(line)
        }
        buffer.removeAll(keepingCapacity: false)
      }
      if processFrame(session: nil) { return }
      didTerminate = true
      onDone(false)
    }
  }
}

extension OpenRouterError {
  static func decodingFailed(statusCode: Int, underlying: Error) -> Self {
    .decodingFailed(statusCode: statusCode, underlying: String(describing: underlying))
  }
}
