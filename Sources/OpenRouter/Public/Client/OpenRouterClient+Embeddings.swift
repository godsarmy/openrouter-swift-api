import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  public func createEmbeddings(
    _ request: EmbeddingRequest,
    options: RequestOptions? = nil
  ) async throws -> EmbeddingResponse {
    try await transport.post(
      path: "embeddings",
      requestBody: request,
      responseType: EmbeddingResponse.self,
      options: options
    )
  }

  public func listEmbeddingsModels(
    offset: Int? = nil,
    limit: Int? = nil,
    options: RequestOptions? = nil
  ) async throws -> EmbeddingsModelsResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(URLQueryItem(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(URLQueryItem(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: "embeddings/models",
      queryItems: queryItems,
      responseType: EmbeddingsModelsResponse.self,
      options: options
    )
  }

  public var embeddings: EmbeddingsResource { EmbeddingsResource(client: self) }

  public struct EmbeddingsResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func create(
      _ request: EmbeddingRequest,
      options: RequestOptions? = nil
    ) async throws -> EmbeddingResponse {
      try await client.createEmbeddings(request, options: options)
    }

    public func listModels(
      offset: Int? = nil,
      limit: Int? = nil,
      options: RequestOptions? = nil
    ) async throws -> EmbeddingsModelsResponse {
      try await client.listEmbeddingsModels(offset: offset, limit: limit, options: options)
    }
  }
}
