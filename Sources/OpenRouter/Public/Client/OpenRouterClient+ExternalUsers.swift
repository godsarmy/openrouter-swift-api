import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  /// Requires a management key. Inactive registrations are excluded by default.
  public func listExternalUsers(
    offset: Int? = nil, limit: Int? = nil, user: String? = nil,
    includeInactive: Bool? = nil, options: RequestOptions? = nil
  ) async throws -> ListExternalUsersResponse {
    var query: [URLQueryItem] = []
    if let offset { query.append(.init(name: "offset", value: String(offset))) }
    if let limit { query.append(.init(name: "limit", value: String(limit))) }
    if let user { query.append(.init(name: "user", value: user)) }
    if let includeInactive {
      query.append(.init(name: "include_inactive", value: String(includeInactive)))
    }
    return try await transport.get(
      path: .preEscaped("external-users"), queryItems: query,
      responseType: ListExternalUsersResponse.self, options: options)
  }

  /// Registers a tracking ID using a management key; creates no login or credentials.
  public func createExternalUser(
    _ request: CreateExternalUserRequest, options: RequestOptions? = nil
  ) async throws -> ExternalUserResponse {
    try await transport.post(
      path: .preEscaped("external-users"), requestBody: request,
      responseType: ExternalUserResponse.self, options: options)
  }

  /// Retrieves an active or inactive registration using a management key.
  public func getExternalUser(user: String, options: RequestOptions? = nil) async throws
    -> ExternalUserResponse
  {
    try await transport.get(
      path: externalUserPath(user), responseType: ExternalUserResponse.self, options: options)
  }

  /// Requires a management key. State changes do not enforce inference access.
  public func updateExternalUser(
    user: String, _ request: UpdateExternalUserRequest, options: RequestOptions? = nil
  ) async throws -> ExternalUserResponse {
    try await transport.patch(
      path: externalUserPath(user), requestBody: request,
      responseType: ExternalUserResponse.self, options: options)
  }

  /// Soft-deactivates using a management key. Repeat deactivation succeeds; inference is not
  /// blocked. Reactivate through update. Retries are opt-in.
  public func deleteExternalUser(user: String, options: RequestOptions? = nil) async throws {
    try await transport.deleteNoContent(path: externalUserPath(user), options: options)
  }

  private func externalUserPath(_ user: String) throws -> HTTPPath {
    guard user != ".", user != ".." else {
      throw OpenRouterError.invalidURL(
        "External user dot IDs cannot be addressed by path; use the list user filter instead.")
    }
    return .preEscaped("external-users/\(escapePathSegment(user))")
  }

  public var externalUsers: ExternalUsersResource { ExternalUsersResource(client: self) }

  public struct ExternalUsersResource: Sendable {
    let client: OpenRouterClient
    public func list(
      offset: Int? = nil, limit: Int? = nil, user: String? = nil,
      includeInactive: Bool? = nil, options: RequestOptions? = nil
    ) async throws -> ListExternalUsersResponse {
      try await client.listExternalUsers(
        offset: offset, limit: limit, user: user, includeInactive: includeInactive, options: options
      )
    }
    public func create(_ request: CreateExternalUserRequest, options: RequestOptions? = nil)
      async throws -> ExternalUserResponse
    {
      try await client.createExternalUser(request, options: options)
    }
    public func get(user: String, options: RequestOptions? = nil) async throws
      -> ExternalUserResponse
    {
      try await client.getExternalUser(user: user, options: options)
    }
    public func update(
      user: String, _ request: UpdateExternalUserRequest, options: RequestOptions? = nil
    ) async throws -> ExternalUserResponse {
      try await client.updateExternalUser(user: user, request, options: options)
    }
    public func delete(user: String, options: RequestOptions? = nil) async throws {
      try await client.deleteExternalUser(user: user, options: options)
    }
  }
}
