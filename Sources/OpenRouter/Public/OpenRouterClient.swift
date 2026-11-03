import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct OpenRouterClient: Sendable {
  public let configuration: Configuration

  let transport: HTTPTransport

  /// Omit `apiKey` only for unauthenticated authorization-code exchange.
  public init(
    apiKey: String = "",
    configuration: Configuration = .init(),
    session: URLSession = .shared
  ) {
    let resolved = configuration.withAPIKey(apiKey)
    self.configuration = resolved
    transport = HTTPTransport(configuration: resolved, session: session)
  }
}
