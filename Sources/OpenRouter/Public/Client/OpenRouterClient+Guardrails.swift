import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  /// Requires a management bearer key. Nil pagination uses server defaults.
  public func listGuardrails(
    offset: Int? = nil, limit: Int? = nil, workspaceID: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> ListGuardrailsResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    if let workspaceID { queryItems.append(.init(name: "workspace_id", value: workspaceID)) }
    return try await transport.get(
      path: .preEscaped("guardrails"), queryItems: queryItems,
      responseType: ListGuardrailsResponse.self, options: options)
  }

  /// Requires a management bearer key. Mutates guardrail policy or assignments; retries are opt-in.
  public func createGuardrail(_ request: CreateGuardrailRequest, options: RequestOptions? = nil)
    async throws -> CreateGuardrailResponse
  {
    return try await transport.post(
      path: .preEscaped("guardrails"), requestBody: request,
      responseType: CreateGuardrailResponse.self, options: options)
  }

  /// Requires a management bearer key. Mutates guardrail policy or assignments; retries are opt-in.
  public func deleteGuardrail(id: String, options: RequestOptions? = nil) async throws
    -> DeleteGuardrailResponse
  {
    return try await transport.delete(
      path: .preEscaped("guardrails/\(escapePathSegment(id))"),
      responseType: DeleteGuardrailResponse.self, options: options)
  }

  /// Gets a guardrail using a management bearer key.
  public func getGuardrail(id: String, options: RequestOptions? = nil) async throws
    -> GetGuardrailResponse
  {
    return try await transport.get(
      path: .preEscaped("guardrails/\(escapePathSegment(id))"),
      responseType: GetGuardrailResponse.self, options: options)
  }

  /// Requires a management bearer key. Mutates guardrail policy or assignments; retries are opt-in.
  public func updateGuardrail(
    id: String, _ request: UpdateGuardrailRequest, options: RequestOptions? = nil
  ) async throws -> UpdateGuardrailResponse {
    return try await transport.patch(
      path: .preEscaped("guardrails/\(escapePathSegment(id))"), requestBody: request,
      responseType: UpdateGuardrailResponse.self, options: options)
  }

  /// Requires a management bearer key. Nil pagination uses server defaults.
  public func listGuardrailKeyAssignments(
    id: String, offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil
  ) async throws -> ListKeyAssignmentsResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: .preEscaped("guardrails/\(escapePathSegment(id))/assignments/keys"),
      queryItems: queryItems, responseType: ListKeyAssignmentsResponse.self, options: options)
  }

  /// Requires a management bearer key. Mutates guardrail policy or assignments; retries are opt-in.
  public func bulkAssignKeysToGuardrail(
    id: String, _ request: BulkAssignKeysRequest, options: RequestOptions? = nil
  ) async throws -> BulkAssignKeysResponse {
    return try await transport.post(
      path: .preEscaped("guardrails/\(escapePathSegment(id))/assignments/keys"),
      requestBody: request, responseType: BulkAssignKeysResponse.self, options: options)
  }

  /// Requires a management bearer key. Mutates guardrail policy or assignments; retries are opt-in.
  public func bulkUnassignKeysFromGuardrail(
    id: String, _ request: BulkUnassignKeysRequest, options: RequestOptions? = nil
  ) async throws -> BulkUnassignKeysResponse {
    return try await transport.post(
      path: .preEscaped("guardrails/\(escapePathSegment(id))/assignments/keys/remove"),
      requestBody: request, responseType: BulkUnassignKeysResponse.self, options: options)
  }

  /// Requires a management bearer key. Nil pagination uses server defaults.
  public func listGuardrailMemberAssignments(
    id: String, offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil
  ) async throws -> ListMemberAssignmentsResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: .preEscaped("guardrails/\(escapePathSegment(id))/assignments/members"),
      queryItems: queryItems, responseType: ListMemberAssignmentsResponse.self, options: options)
  }

  /// Requires a management bearer key. Mutates guardrail policy or assignments; retries are opt-in.
  public func bulkAssignMembersToGuardrail(
    id: String, _ request: BulkAssignMembersRequest, options: RequestOptions? = nil
  ) async throws -> BulkAssignMembersResponse {
    return try await transport.post(
      path: .preEscaped("guardrails/\(escapePathSegment(id))/assignments/members"),
      requestBody: request, responseType: BulkAssignMembersResponse.self, options: options)
  }

  /// Requires a management bearer key. Mutates guardrail policy or assignments; retries are opt-in.
  public func bulkUnassignMembersFromGuardrail(
    id: String, _ request: BulkUnassignMembersRequest, options: RequestOptions? = nil
  ) async throws -> BulkUnassignMembersResponse {
    return try await transport.post(
      path: .preEscaped("guardrails/\(escapePathSegment(id))/assignments/members/remove"),
      requestBody: request, responseType: BulkUnassignMembersResponse.self, options: options)
  }

  /// Requires a management bearer key. Nil pagination uses server defaults.
  public func listKeyAssignments(
    offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil
  ) async throws -> ListKeyAssignmentsResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: .preEscaped("guardrails/assignments/keys"), queryItems: queryItems,
      responseType: ListKeyAssignmentsResponse.self, options: options)
  }

  /// Requires a management bearer key. Nil pagination uses server defaults.
  public func listMemberAssignments(
    offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil
  ) async throws -> ListMemberAssignmentsResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: .preEscaped("guardrails/assignments/members"), queryItems: queryItems,
      responseType: ListMemberAssignmentsResponse.self, options: options)
  }

  public var guardrails: GuardrailsResource { GuardrailsResource(client: self) }

  public struct GuardrailsResource: Sendable {
    let client: OpenRouterClient
    /// Requires a management key.
    public func list(
      offset: Int? = nil, limit: Int? = nil, workspaceID: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> ListGuardrailsResponse {
      try await client.listGuardrails(
        offset: offset, limit: limit, workspaceID: workspaceID, options: options)
    }
    /// Requires a management key. Mutates policy or assignments; retries are opt-in.
    public func create(_ request: CreateGuardrailRequest, options: RequestOptions? = nil)
      async throws -> CreateGuardrailResponse
    { try await client.createGuardrail(request, options: options) }
    /// Requires a management key. Mutates policy or assignments; retries are opt-in.
    public func delete(id: String, options: RequestOptions? = nil) async throws
      -> DeleteGuardrailResponse
    { try await client.deleteGuardrail(id: id, options: options) }
    /// Requires a management key.
    public func get(id: String, options: RequestOptions? = nil) async throws -> GetGuardrailResponse
    { try await client.getGuardrail(id: id, options: options) }
    /// Requires a management key. Mutates policy or assignments; retries are opt-in.
    public func update(
      id: String, _ request: UpdateGuardrailRequest, options: RequestOptions? = nil
    ) async throws -> UpdateGuardrailResponse {
      try await client.updateGuardrail(id: id, request, options: options)
    }
    /// Requires a management key.
    public func listKeyAssignments(
      id: String, offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil
    ) async throws -> ListKeyAssignmentsResponse {
      try await client.listGuardrailKeyAssignments(
        id: id, offset: offset, limit: limit, options: options)
    }
    /// Requires a management key. Mutates policy or assignments; retries are opt-in.
    public func bulkAssignKeysToGuardrail(
      id: String, _ request: BulkAssignKeysRequest, options: RequestOptions? = nil
    ) async throws -> BulkAssignKeysResponse {
      try await client.bulkAssignKeysToGuardrail(id: id, request, options: options)
    }
    /// Requires a management key. Mutates policy or assignments; retries are opt-in.
    public func bulkUnassignKeysFromGuardrail(
      id: String, _ request: BulkUnassignKeysRequest, options: RequestOptions? = nil
    ) async throws -> BulkUnassignKeysResponse {
      try await client.bulkUnassignKeysFromGuardrail(id: id, request, options: options)
    }
    /// Requires a management key.
    public func listMemberAssignments(
      id: String, offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil
    ) async throws -> ListMemberAssignmentsResponse {
      try await client.listGuardrailMemberAssignments(
        id: id, offset: offset, limit: limit, options: options)
    }
    /// Requires a management key. Mutates policy or assignments; retries are opt-in.
    public func bulkAssignMembersToGuardrail(
      id: String, _ request: BulkAssignMembersRequest, options: RequestOptions? = nil
    ) async throws -> BulkAssignMembersResponse {
      try await client.bulkAssignMembersToGuardrail(id: id, request, options: options)
    }
    /// Requires a management key. Mutates policy or assignments; retries are opt-in.
    public func bulkUnassignMembersFromGuardrail(
      id: String, _ request: BulkUnassignMembersRequest, options: RequestOptions? = nil
    ) async throws -> BulkUnassignMembersResponse {
      try await client.bulkUnassignMembersFromGuardrail(id: id, request, options: options)
    }
    /// Requires a management key.
    public func listKeyAssignments(
      offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil
    ) async throws -> ListKeyAssignmentsResponse {
      try await client.listKeyAssignments(offset: offset, limit: limit, options: options)
    }
    /// Requires a management key.
    public func listMemberAssignments(
      offset: Int? = nil, limit: Int? = nil, options: RequestOptions? = nil
    ) async throws -> ListMemberAssignmentsResponse {
      try await client.listMemberAssignments(offset: offset, limit: limit, options: options)
    }
  }
}
