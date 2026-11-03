import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
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
}
