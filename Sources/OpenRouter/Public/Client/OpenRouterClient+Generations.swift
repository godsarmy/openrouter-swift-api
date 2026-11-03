import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  public func getGeneration(id: String, options: RequestOptions? = nil) async throws
    -> GenerationResponse
  {
    try await transport.get(
      path: "generation",
      queryItems: [URLQueryItem(name: "id", value: id)],
      responseType: GenerationResponse.self,
      options: options
    )
  }

  public func getGenerationRaw(id: String, options: RequestOptions? = nil) async throws -> JSONValue
  {
    try await transport.get(
      path: "generation",
      queryItems: [URLQueryItem(name: "id", value: id)],
      responseType: JSONValue.self,
      options: options
    )
  }

  public func listGenerationContent(id: String, options: RequestOptions? = nil) async throws
    -> GenerationContentResponse
  {
    try await transport.get(
      path: "generation/content",
      queryItems: [URLQueryItem(name: "id", value: id)],
      responseType: GenerationContentResponse.self,
      options: options
    )
  }

  public func listGenerationContentRaw(id: String, options: RequestOptions? = nil) async throws
    -> JSONValue
  {
    try await transport.get(
      path: "generation/content",
      queryItems: [URLQueryItem(name: "id", value: id)],
      responseType: JSONValue.self,
      options: options
    )
  }

  public var generations: GenerationsResource { GenerationsResource(client: self) }

  public struct GenerationsResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func get(
      id: String,
      options: RequestOptions? = nil
    ) async throws -> GenerationResponse {
      try await client.getGeneration(id: id, options: options)
    }

    public func content(
      id: String,
      options: RequestOptions? = nil
    ) async throws -> GenerationContentResponse {
      try await client.listGenerationContent(id: id, options: options)
    }
  }
}
