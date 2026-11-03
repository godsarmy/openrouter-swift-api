import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  public func listModels(options: RequestOptions? = nil) async throws -> ModelsResponse {
    try await transport.get(path: "models", responseType: ModelsResponse.self, options: options)
  }

  public func listModelsUser(
    offset: Int? = nil,
    limit: Int? = nil,
    options: RequestOptions? = nil
  ) async throws -> UserModelsResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(URLQueryItem(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(URLQueryItem(name: "limit", value: String(limit))) }
    return try await transport.get(
      path: "models/user",
      queryItems: queryItems,
      responseType: UserModelsResponse.self,
      options: options
    )
  }

  public func listModelsCount(
    outputModalities: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> ModelsCountResponse {
    let queryItems =
      outputModalities.map { [URLQueryItem(name: "output_modalities", value: $0)] } ?? []
    return try await transport.get(
      path: "models/count",
      queryItems: queryItems,
      responseType: ModelsCountResponse.self,
      options: options
    )
  }

  public func getModel(
    author: String,
    slug: String,
    options: RequestOptions? = nil
  ) async throws -> ModelResponse {
    try await transport.get(
      path: .preEscaped("model/\(escapePathSegment(author))/\(escapePathSegment(slug))"),
      responseType: ModelResponse.self,
      options: options
    )
  }

  public func listProviders(options: RequestOptions? = nil) async throws -> ProvidersResponse {
    try await transport.get(
      path: "providers", responseType: ProvidersResponse.self, options: options)
  }

  public func listModelEndpoints(
    author: String,
    slug: String,
    options: RequestOptions? = nil
  ) async throws -> ModelEndpointsResponse {
    try await transport.get(
      path: .preEscaped(
        "models/\(escapePathSegment(author))/\(escapePathSegment(slug))/endpoints"),
      responseType: ModelEndpointsResponse.self,
      options: options
    )
  }

  public func listZDREndpoints(options: RequestOptions? = nil) async throws -> ZDREndpointsResponse
  {
    try await transport.get(
      path: "endpoints/zdr", responseType: ZDREndpointsResponse.self, options: options)
  }

  public var models: ModelsResource { ModelsResource(client: self) }

  public var providers: ProvidersResource { ProvidersResource(client: self) }

  public var endpoints: EndpointsResource { EndpointsResource(client: self) }

  public struct ModelsResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func list(options: RequestOptions? = nil) async throws -> ModelsResponse {
      try await client.listModels(options: options)
    }

    public func listUser(
      offset: Int? = nil,
      limit: Int? = nil,
      options: RequestOptions? = nil
    ) async throws -> UserModelsResponse {
      try await client.listModelsUser(offset: offset, limit: limit, options: options)
    }

    public func count(
      outputModalities: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> ModelsCountResponse {
      try await client.listModelsCount(outputModalities: outputModalities, options: options)
    }

    public func get(author: String, slug: String, options: RequestOptions? = nil) async throws
      -> ModelResponse
    {
      try await client.getModel(author: author, slug: slug, options: options)
    }
  }

  public struct ProvidersResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func list(options: RequestOptions? = nil) async throws -> ProvidersResponse {
      try await client.listProviders(options: options)
    }
  }

  public struct EndpointsResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func list(
      author: String,
      slug: String,
      options: RequestOptions? = nil
    ) async throws -> ModelEndpointsResponse {
      try await client.listModelEndpoints(author: author, slug: slug, options: options)
    }

    public func listZDR(options: RequestOptions? = nil) async throws -> ZDREndpointsResponse {
      try await client.listZDREndpoints(options: options)
    }
  }
}
