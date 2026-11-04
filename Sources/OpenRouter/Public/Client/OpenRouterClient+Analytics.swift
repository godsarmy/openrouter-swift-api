extension OpenRouterClient {
  /// Gets available metrics, dimensions, operators, and granularities using a management key.
  public func getAnalyticsMeta(options: RequestOptions? = nil) async throws -> AnalyticsMetaResponse
  {
    try await transport.get(
      path: "analytics/meta", responseType: AnalyticsMetaResponse.self, options: options)
  }

  /// Runs an analytics query using a management key. Query constraints are validated by the server.
  public func queryAnalytics(
    _ request: AnalyticsQueryRequest, options: RequestOptions? = nil
  ) async throws -> AnalyticsQueryResponse {
    try await transport.post(
      path: "analytics/query", requestBody: request,
      responseType: AnalyticsQueryResponse.self, options: options)
  }

  public var analytics: AnalyticsResource { AnalyticsResource(client: self) }

  public struct AnalyticsResource: Sendable {
    let client: OpenRouterClient

    public func getMeta(options: RequestOptions? = nil) async throws -> AnalyticsMetaResponse {
      try await client.getAnalyticsMeta(options: options)
    }

    public func query(
      _ request: AnalyticsQueryRequest, options: RequestOptions? = nil
    ) async throws -> AnalyticsQueryResponse {
      try await client.queryAnalytics(request, options: options)
    }
  }
}
