import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  public struct Configuration: Sendable {
    public var baseURL: URL
    public var timeout: TimeInterval
    public var httpReferer: String?
    public var appTitle: String?
    public var appCategories: [String]?
    public var experimentalMetadata: String?
    public var xTitle: String?
    public var debugLogger: (@Sendable (OpenRouterDebugEvent) -> Void)?

    // Stored privately until transport layer is implemented.
    var apiKey: String?

    public init(
      baseURL: URL = URL(string: "https://openrouter.ai/api/v1/")!,
      timeout: TimeInterval = 60,
      httpReferer: String? = nil,
      appTitle: String? = nil,
      appCategories: [String]? = nil,
      experimentalMetadata: String? = nil,
      xTitle: String? = nil,
      debugLogger: (@Sendable (OpenRouterDebugEvent) -> Void)? = nil
    ) {
      self.baseURL = baseURL
      self.timeout = timeout
      self.httpReferer = httpReferer
      self.appTitle = appTitle
      self.appCategories = appCategories
      self.experimentalMetadata = experimentalMetadata
      self.xTitle = xTitle
      self.debugLogger = debugLogger
      self.apiKey = nil
    }

    public func withHTTPReferer(_ value: String?) -> Self {
      var copy = self
      copy.httpReferer = value
      return copy
    }

    public func withXTitle(_ value: String?) -> Self {
      var copy = self
      copy.xTitle = value
      return copy
    }

    func withAPIKey(_ value: String) -> Self {
      var copy = self
      copy.apiKey = value
      return copy
    }
  }
}
