import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
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

  public var credits: CreditsResource { CreditsResource(client: self) }

  public var keys: KeysResource { KeysResource(client: self) }

  public var auth: AuthResource { AuthResource(client: self) }

  public struct CreditsResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func get(options: RequestOptions? = nil) async throws -> CreditsResponse {
      try await client.getCredits(options: options)
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
}
