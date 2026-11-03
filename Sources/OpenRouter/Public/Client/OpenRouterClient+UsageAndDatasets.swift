import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  public func getUserActivity(
    date: String? = nil,
    apiKeyHash: String? = nil,
    userID: String? = nil,
    groupBy: String? = nil,
    workspaceID: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> ActivityResponse {
    var queryItems: [URLQueryItem] = []
    if let date { queryItems.append(URLQueryItem(name: "date", value: date)) }
    if let apiKeyHash { queryItems.append(URLQueryItem(name: "api_key_hash", value: apiKeyHash)) }
    if let userID { queryItems.append(URLQueryItem(name: "user_id", value: userID)) }
    if let groupBy { queryItems.append(URLQueryItem(name: "group_by", value: groupBy)) }
    if let workspaceID { queryItems.append(URLQueryItem(name: "workspace_id", value: workspaceID)) }
    return try await transport.get(
      path: "activity",
      queryItems: queryItems,
      responseType: ActivityResponse.self,
      options: options
    )
  }

  public func getRankingsDaily(
    startDate: String? = nil,
    endDate: String? = nil,
    period: String? = nil,
    modality: String? = nil,
    contextBucket: String? = nil,
    category: String? = nil,
    languageType: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> RankingsDailyResponse {
    var queryItems: [URLQueryItem] = []
    if let startDate { queryItems.append(URLQueryItem(name: "start_date", value: startDate)) }
    if let endDate { queryItems.append(URLQueryItem(name: "end_date", value: endDate)) }
    if let period { queryItems.append(URLQueryItem(name: "period", value: period)) }
    if let modality { queryItems.append(URLQueryItem(name: "modality", value: modality)) }
    if let contextBucket {
      queryItems.append(URLQueryItem(name: "context_bucket", value: contextBucket))
    }
    if let category { queryItems.append(URLQueryItem(name: "category", value: category)) }
    if let languageType {
      queryItems.append(URLQueryItem(name: "language_type", value: languageType))
    }
    return try await transport.get(
      path: "datasets/rankings-daily",
      queryItems: queryItems,
      responseType: RankingsDailyResponse.self,
      options: options
    )
  }

  public var activity: ActivityResource { ActivityResource(client: self) }

  public var datasets: DatasetsResource { DatasetsResource(client: self) }

  public struct ActivityResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func get(
      date: String? = nil,
      apiKeyHash: String? = nil,
      userID: String? = nil,
      groupBy: String? = nil,
      workspaceID: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> ActivityResponse {
      try await client.getUserActivity(
        date: date,
        apiKeyHash: apiKeyHash,
        userID: userID,
        groupBy: groupBy,
        workspaceID: workspaceID,
        options: options
      )
    }
  }

  public struct DatasetsResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func rankingsDaily(
      startDate: String? = nil,
      endDate: String? = nil,
      period: String? = nil,
      modality: String? = nil,
      contextBucket: String? = nil,
      category: String? = nil,
      languageType: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> RankingsDailyResponse {
      try await client.getRankingsDaily(
        startDate: startDate, endDate: endDate, period: period, modality: modality,
        contextBucket: contextBucket, category: category, languageType: languageType,
        options: options)
    }
  }
}
