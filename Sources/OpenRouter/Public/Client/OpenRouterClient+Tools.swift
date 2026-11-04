import Foundation

extension OpenRouterClient {
  /// Lists server tools using bearer authentication. Omitting offset and limit returns the full catalog.
  /// The server validates offset >= 0 and limit in 1...100. API format strings allow future formats.
  public func listTools(
    offset: Int? = nil, limit: Int? = nil, apiFormat: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> ListToolsResponse {
    var queryItems: [URLQueryItem] = []
    if let offset { queryItems.append(.init(name: "offset", value: String(offset))) }
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    if let apiFormat { queryItems.append(.init(name: "api_format", value: apiFormat)) }
    return try await transport.get(
      path: "tools", queryItems: queryItems, responseType: ListToolsResponse.self, options: options)
  }

  /// Gets a server tool by canonical name or alias, including native model support.
  /// Alias redirects follow the supplied URLSession's redirect policy; prefer canonical IDs.
  public func getTool(name: String, options: RequestOptions? = nil) async throws -> GetToolResponse
  {
    guard !name.isEmpty, name != ".", name != ".." else {
      throw OpenRouterError.invalidURL(
        "A tool name must be a nonempty path segment other than dot segments.")
    }
    return try await transport.get(
      path: .preEscaped("tools/\(escapePathSegment(name))"),
      responseType: GetToolResponse.self, options: options)
  }

  public var tools: ToolsResource { ToolsResource(client: self) }

  /// Server-tool discovery; this does not execute tools or register application functions.
  public struct ToolsResource: Sendable {
    let client: OpenRouterClient

    public func list(
      offset: Int? = nil, limit: Int? = nil, apiFormat: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> ListToolsResponse {
      try await client.listTools(
        offset: offset, limit: limit, apiFormat: apiFormat, options: options)
    }

    public func get(name: String, options: RequestOptions? = nil) async throws -> GetToolResponse {
      try await client.getTool(name: name, options: options)
    }
  }
}
