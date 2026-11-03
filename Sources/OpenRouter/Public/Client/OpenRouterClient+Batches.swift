import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
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
}
