import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  /// Requires a management bearer key. Nil pagination uses server defaults.
  public func listObservabilityDestinations(
    offset: Int? = nil, limit: Int? = nil, workspaceID: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> ListObservabilityDestinationsResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    if let workspaceID { queryItems.append(.init(name: "workspace_id", value: workspaceID)) }
    return try await transport.get(
      path: .preEscaped("observability/destinations"), queryItems: queryItems,
      responseType: ListObservabilityDestinationsResponse.self, options: options)
  }

  /// Creates a destination using a management key. Provider configs are server-validated.
  public func createObservabilityDestination(
    _ request: CreateObservabilityDestinationRequest, options: RequestOptions? = nil
  )
    async throws -> CreateObservabilityDestinationResponse
  {
    return try await transport.post(
      path: .preEscaped("observability/destinations"), requestBody: request,
      responseType: CreateObservabilityDestinationResponse.self, options: options)
  }

  /// Soft-deletes a destination using a management key.
  public func deleteObservabilityDestination(id: String, options: RequestOptions? = nil)
    async throws
    -> DeleteObservabilityDestinationResponse
  {
    return try await transport.delete(
      path: .preEscaped("observability/destinations/\(escapePathSegment(id))"),
      responseType: DeleteObservabilityDestinationResponse.self, options: options)
  }

  /// Gets a destination using a management key. Treat response configuration as sensitive.
  public func getObservabilityDestination(id: String, options: RequestOptions? = nil) async throws
    -> GetObservabilityDestinationResponse
  {
    return try await transport.get(
      path: .preEscaped("observability/destinations/\(escapePathSegment(id))"),
      responseType: GetObservabilityDestinationResponse.self, options: options)
  }

  /// Patches explicit fields using a management key. Does not automatically echo response configs.
  public func updateObservabilityDestination(
    id: String, _ request: UpdateObservabilityDestinationRequest, options: RequestOptions? = nil
  ) async throws -> UpdateObservabilityDestinationResponse {
    return try await transport.patch(
      path: .preEscaped("observability/destinations/\(escapePathSegment(id))"),
      requestBody: request,
      responseType: UpdateObservabilityDestinationResponse.self, options: options)
  }

  public var observability: ObservabilityResource { ObservabilityResource(client: self) }

  public struct ObservabilityResource: Sendable {
    let client: OpenRouterClient
    public var destinations: ObservabilityDestinationsResource {
      ObservabilityDestinationsResource(client: client)
    }
  }

  public struct ObservabilityDestinationsResource: Sendable {
    let client: OpenRouterClient
    /// Requires a management key.
    public func list(
      offset: Int? = nil, limit: Int? = nil, workspaceID: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> ListObservabilityDestinationsResponse {
      try await client.listObservabilityDestinations(
        offset: offset, limit: limit, workspaceID: workspaceID, options: options)
    }
    /// Requires a management key. Provider configs are server-validated.
    public func create(
      _ request: CreateObservabilityDestinationRequest, options: RequestOptions? = nil
    )
      async throws -> CreateObservabilityDestinationResponse
    { try await client.createObservabilityDestination(request, options: options) }
    /// Soft-deletes a destination using a management key.
    public func delete(id: String, options: RequestOptions? = nil) async throws
      -> DeleteObservabilityDestinationResponse
    { try await client.deleteObservabilityDestination(id: id, options: options) }
    /// Requires a management key.
    public func get(id: String, options: RequestOptions? = nil) async throws
      -> GetObservabilityDestinationResponse
    { try await client.getObservabilityDestination(id: id, options: options) }
    /// Requires a management key. Only explicit fields are patched.
    public func update(
      id: String, _ request: UpdateObservabilityDestinationRequest, options: RequestOptions? = nil
    ) async throws -> UpdateObservabilityDestinationResponse {
      try await client.updateObservabilityDestination(id: id, request, options: options)
    }
  }
}
