import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct RequestOptions: Sendable, Equatable {
  public var timeout: TimeInterval?
  public var retries: RetryPolicy?
  public var baseURL: URL?
  public var extraHeaders: [String: String]

  public init(
    timeout: TimeInterval? = nil,
    retries: RetryPolicy? = nil,
    baseURL: URL? = nil,
    extraHeaders: [String: String] = [:]
  ) {
    self.timeout = timeout
    self.retries = retries
    self.baseURL = baseURL
    self.extraHeaders = extraHeaders
  }
}

public enum RetryPolicy: Sendable, Equatable {
  case none
  case backoff(
    maxAttempts: Int,
    initialDelay: TimeInterval,
    maxDelay: TimeInterval,
    exponent: Double,
    retryStatusCodes: Set<Int>,
    retryConnectionErrors: Bool
  )
}
