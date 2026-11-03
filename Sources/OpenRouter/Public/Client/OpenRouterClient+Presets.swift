import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  /// Requires a management bearer key. Omitted pagination uses server defaults.
  public func listPresets(offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil)
    async throws -> ListPresetsResponse
  {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: .preEscaped("presets"), queryItems: queryItems, responseType: ListPresetsResponse.self,
      options: options)
  }

  /// Gets preset metadata and its designated version using a management bearer key.
  public func getPreset(slug: String, options: RequestOptions? = nil) async throws
    -> GetPresetResponse
  {
    return try await transport.get(
      path: .preEscaped("presets/\(escapePathSegment(slug))"), responseType: GetPresetResponse.self,
      options: options)
  }

  /// Requires a management bearer key. Omitted pagination uses server defaults.
  public func listPresetVersions(
    slug: String, offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil
  ) async throws -> ListPresetVersionsResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: .preEscaped("presets/\(escapePathSegment(slug))/versions"), queryItems: queryItems,
      responseType: ListPresetVersionsResponse.self, options: options)
  }

  /// Gets a version by number, not UUID, using a management bearer key.
  public func getPresetVersion(slug: String, version: String, options: RequestOptions? = nil)
    async throws -> GetPresetVersionResponse
  {
    return try await transport.get(
      path: .preEscaped(
        "presets/\(escapePathSegment(slug))/versions/\(escapePathSegment(version))"),
      responseType: GetPresetVersionResponse.self, options: options)
  }

  /// Creates a preset or a new version; repeated mutations can create additional versions.
  /// Requires a management bearer key. This does not run inference. Non-config fields are ignored server-side.
  public func createPresetsChatCompletions(
    slug: String, _ request: ChatCompletionRequest, options: RequestOptions? = nil
  ) async throws -> CreatePresetFromInferenceResponse {
    try await transport.post(
      path: .preEscaped("presets/\(escapePathSegment(slug))/chat/completions"),
      requestBody: request, responseType: CreatePresetFromInferenceResponse.self, options: options)
  }

  /// Creates a preset or a new version; repeated mutations can create additional versions.
  /// Requires a management bearer key. This does not run inference. Non-config fields are ignored server-side.
  public func createPresetsChatCompletions(
    slug: String, body: [String: JSONValue], options: RequestOptions? = nil
  ) async throws -> CreatePresetFromInferenceResponse {
    try await transport.post(
      path: .preEscaped("presets/\(escapePathSegment(slug))/chat/completions"), requestBody: body,
      responseType: CreatePresetFromInferenceResponse.self, options: options)
  }

  /// Creates a preset or a new version; repeated mutations can create additional versions.
  /// Requires a management bearer key. This does not run inference. Non-config fields are ignored server-side.
  public func createPresetsMessages(
    slug: String, _ request: MessagesRequest, options: RequestOptions? = nil
  ) async throws -> CreatePresetFromInferenceResponse {
    try await transport.post(
      path: .preEscaped("presets/\(escapePathSegment(slug))/messages"), requestBody: request,
      responseType: CreatePresetFromInferenceResponse.self, options: options)
  }

  /// Creates a preset or a new version; repeated mutations can create additional versions.
  /// Requires a management bearer key. This does not run inference. Non-config fields are ignored server-side.
  public func createPresetsMessages(
    slug: String, body: [String: JSONValue], options: RequestOptions? = nil
  ) async throws -> CreatePresetFromInferenceResponse {
    try await transport.post(
      path: .preEscaped("presets/\(escapePathSegment(slug))/messages"), requestBody: body,
      responseType: CreatePresetFromInferenceResponse.self, options: options)
  }

  /// Creates a preset or a new version; repeated mutations can create additional versions.
  /// Requires a management bearer key. This does not run inference. Non-config fields are ignored server-side.
  public func createPresetsResponses(
    slug: String, _ request: ResponsesRequest, options: RequestOptions? = nil
  ) async throws -> CreatePresetFromInferenceResponse {
    try await transport.post(
      path: .preEscaped("presets/\(escapePathSegment(slug))/responses"), requestBody: request,
      responseType: CreatePresetFromInferenceResponse.self, options: options)
  }

  /// Creates a preset or a new version; repeated mutations can create additional versions.
  /// Requires a management bearer key. This does not run inference. Non-config fields are ignored server-side.
  public func createPresetsResponses(
    slug: String, body: [String: JSONValue], options: RequestOptions? = nil
  ) async throws -> CreatePresetFromInferenceResponse {
    try await transport.post(
      path: .preEscaped("presets/\(escapePathSegment(slug))/responses"), requestBody: body,
      responseType: CreatePresetFromInferenceResponse.self, options: options)
  }

  /// Preset management APIs; these require a management bearer key.
  public var presets: PresetsResource { PresetsResource(client: self) }

  public struct PresetsResource: Sendable {
    let client: OpenRouterClient
    public func list(offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil)
      async throws -> ListPresetsResponse
    {
      try await client.listPresets(offset: offset, limit: limit, options: options)
    }
    public func get(slug: String, options: RequestOptions? = nil) async throws -> GetPresetResponse
    {
      try await client.getPreset(slug: slug, options: options)
    }
    public func listVersions(
      slug: String, offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil
    ) async throws -> ListPresetVersionsResponse {
      try await client.listPresetVersions(
        slug: slug, offset: offset, limit: limit, options: options)
    }
    public func getVersion(slug: String, version: String, options: RequestOptions? = nil)
      async throws -> GetPresetVersionResponse
    {
      try await client.getPresetVersion(slug: slug, version: version, options: options)
    }
    /// Creates a preset or a new version; repeated mutations can create additional versions.
    /// Requires a management bearer key. This does not run inference. Non-config fields are ignored server-side.
    public func createFromChatCompletions(
      slug: String, _ request: ChatCompletionRequest, options: RequestOptions? = nil
    ) async throws -> CreatePresetFromInferenceResponse {
      try await client.createPresetsChatCompletions(slug: slug, request, options: options)
    }
    /// Creates a preset or a new version; repeated mutations can create additional versions.
    /// Requires a management bearer key. This does not run inference. Non-config fields are ignored server-side.
    public func createFromChatCompletions(
      slug: String, body: [String: JSONValue], options: RequestOptions? = nil
    ) async throws -> CreatePresetFromInferenceResponse {
      try await client.createPresetsChatCompletions(slug: slug, body: body, options: options)
    }
    /// Creates a preset or a new version; repeated mutations can create additional versions.
    /// Requires a management bearer key. This does not run inference. Non-config fields are ignored server-side.
    public func createFromMessages(
      slug: String, _ request: MessagesRequest, options: RequestOptions? = nil
    ) async throws -> CreatePresetFromInferenceResponse {
      try await client.createPresetsMessages(slug: slug, request, options: options)
    }
    /// Creates a preset or a new version; repeated mutations can create additional versions.
    /// Requires a management bearer key. This does not run inference. Non-config fields are ignored server-side.
    public func createFromMessages(
      slug: String, body: [String: JSONValue], options: RequestOptions? = nil
    ) async throws -> CreatePresetFromInferenceResponse {
      try await client.createPresetsMessages(slug: slug, body: body, options: options)
    }
    /// Creates a preset or a new version; repeated mutations can create additional versions.
    /// Requires a management bearer key. This does not run inference. Non-config fields are ignored server-side.
    public func createFromResponses(
      slug: String, _ request: ResponsesRequest, options: RequestOptions? = nil
    ) async throws -> CreatePresetFromInferenceResponse {
      try await client.createPresetsResponses(slug: slug, request, options: options)
    }
    /// Creates a preset or a new version; repeated mutations can create additional versions.
    /// Requires a management bearer key. This does not run inference. Non-config fields are ignored server-side.
    public func createFromResponses(
      slug: String, body: [String: JSONValue], options: RequestOptions? = nil
    ) async throws -> CreatePresetFromInferenceResponse {
      try await client.createPresetsResponses(slug: slug, body: body, options: options)
    }
  }
}
