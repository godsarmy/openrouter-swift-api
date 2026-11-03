import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  /// Gets settings for the authenticated key's organization using a management API key.
  public func getOrganizationSettings(options: RequestOptions? = nil) async throws
    -> OrganizationSettingsResponse
  {
    try await transport.get(
      path: "organization/settings", responseType: OrganizationSettingsResponse.self,
      options: options)
  }

  /// Updates dashboard catalog visibility only, using a management API key.
  public func updateOrganizationSettings(
    _ request: UpdateOrganizationSettingsRequest, options: RequestOptions? = nil
  ) async throws -> OrganizationSettingsResponse {
    try await transport.patch(
      path: .preEscaped("organization/settings"), requestBody: request,
      responseType: OrganizationSettingsResponse.self, options: options)
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

  public var organization: OrganizationResource { OrganizationResource(client: self) }

  /// Organization endpoints requiring a management API key.
  public struct OrganizationResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func getSettings(options: RequestOptions? = nil) async throws
      -> OrganizationSettingsResponse
    {
      try await client.getOrganizationSettings(options: options)
    }

    public func updateSettings(
      _ request: UpdateOrganizationSettingsRequest, options: RequestOptions? = nil
    ) async throws -> OrganizationSettingsResponse {
      try await client.updateOrganizationSettings(request, options: options)
    }

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
}
