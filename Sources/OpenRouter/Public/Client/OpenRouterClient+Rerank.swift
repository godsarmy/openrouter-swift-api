import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  public func createRerank(_ request: RerankRequest, options: RequestOptions? = nil) async throws
    -> RerankResponse
  {
    try await transport.post(
      path: "rerank", requestBody: request, responseType: RerankResponse.self, options: options)
  }

  public var rerank: RerankResource { RerankResource(client: self) }

  public struct RerankResource: Sendable {
    fileprivate let client: OpenRouterClient
    public func create(_ request: RerankRequest, options: RequestOptions? = nil) async throws
      -> RerankResponse
    { try await client.createRerank(request, options: options) }
  }
}
