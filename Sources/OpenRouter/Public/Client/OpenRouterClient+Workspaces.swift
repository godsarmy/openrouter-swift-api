import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
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

  public var workspaces: WorkspacesResource { WorkspacesResource(client: self) }

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
}
