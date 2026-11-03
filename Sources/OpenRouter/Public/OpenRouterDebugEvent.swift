import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct OpenRouterDebugEvent: Sendable, Equatable {
  public var message: String
  public var method: String?
  public var path: String?
  public var statusCode: Int?
  public var retryAttempt: Int?

  public init(
    message: String,
    method: String? = nil,
    path: String? = nil,
    statusCode: Int? = nil,
    retryAttempt: Int? = nil
  ) {
    self.message = message
    self.method = method
    self.path = path
    self.statusCode = statusCode
    self.retryAttempt = retryAttempt
  }
}
