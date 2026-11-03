import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public enum OpenRouterError: Error, Equatable {
  case notImplemented(String)
  case missingAPIKey
  /// Remove session-level Authorization from `URLSessionConfiguration.httpAdditionalHeaders`
  /// before creating the session used for authorization code exchange.
  case unauthenticatedSessionRequired
  case invalidURL(String)
  case invalidResponse
  case decodingFailed(statusCode: Int, underlying: String)
  case apiError(statusCode: Int, code: Int?, message: String?, rawBody: String?)
  case streamCancelled

  public static func == (lhs: OpenRouterError, rhs: OpenRouterError) -> Bool {
    switch (lhs, rhs) {
    case (.notImplemented(let a), .notImplemented(let b)):
      a == b
    case (.missingAPIKey, .missingAPIKey):
      true
    case (.unauthenticatedSessionRequired, .unauthenticatedSessionRequired):
      true
    case (.invalidURL(let a), .invalidURL(let b)):
      a == b
    case (.invalidResponse, .invalidResponse):
      true
    case (
      .decodingFailed(let aStatus, let aUnderlying), .decodingFailed(let bStatus, let bUnderlying)
    ):
      aStatus == bStatus && aUnderlying == bUnderlying
    case (
      .apiError(let aStatus, let aCode, let aMessage, let aRaw),
      .apiError(let bStatus, let bCode, let bMessage, let bRaw)
    ):
      aStatus == bStatus && aCode == bCode && aMessage == bMessage && aRaw == bRaw
    case (.streamCancelled, .streamCancelled):
      true
    default:
      false
    }
  }
}

extension OpenRouterError {
  static func messageStreamError(from event: MessagesStreamEvent) -> Self {
    let payload = event.error ?? event.rawPayload
    var code: Int?
    var message: String?
    if case .object(let object) = payload {
      if case .number(let value)? = object["code"] { code = Int(value) }
      if case .string(let value)? = object["message"] { message = value }
    }
    return .apiError(
      statusCode: code ?? 0, code: code, message: message ?? "Messages stream error",
      rawBody: try? String(data: JSONEncoder().encode(payload), encoding: .utf8))
  }

  static func streamEventError(from event: ResponsesStreamEvent) -> Self {
    let payload = event.rawPayload
    let errorPayload: JSONValue
    if case .object(let object) = payload, let error = object["error"] {
      errorPayload = error
    } else if case .object(let object) = payload,
      case .object(let response)? = object["response"],
      let error = response["error"]
    {
      errorPayload = error
    } else {
      errorPayload = payload
    }

    var code: Int?
    var message: String?
    if case .object(let object) = errorPayload {
      if case .number(let value)? = object["code"] { code = Int(value) }
      if case .string(let value)? = object["message"] { message = value }
    }
    if message == nil { message = "Responses stream event: \(event.type)" }
    let rawBody = try? String(data: JSONEncoder().encode(payload), encoding: .utf8)
    return .apiError(statusCode: code ?? 0, code: code, message: message, rawBody: rawBody)
  }

  public var statusCode: Int? {
    guard case .apiError(let statusCode, _, _, _) = self else { return nil }
    return statusCode
  }

  public var isUnauthorized: Bool { statusCode == 401 }
  public var isPaymentRequired: Bool { statusCode == 402 }
  public var isRateLimited: Bool { statusCode == 429 }
  public var isBadRequest: Bool { statusCode == 400 }
  public var isForbidden: Bool { statusCode == 403 }
  public var isNotFound: Bool { statusCode == 404 }
  public var isServerError: Bool {
    guard let statusCode else { return false }
    return (500...599).contains(statusCode)
  }

  public var apiCode: Int? {
    guard case .apiError(_, let code, _, _) = self else { return nil }
    return code
  }

  public var isRetryable: Bool {
    guard let statusCode else { return false }
    return ChatCompletionFallbackPolicy.defaultErrorCodes.contains(statusCode)
  }

  public var retryAfter: TimeInterval? {
    guard case .apiError(_, _, _, let rawBody) = self,
      let rawBody,
      let value = OpenRouterError.extractRetryAfter(from: rawBody)
    else { return nil }
    return value
  }

  private static func extractRetryAfter(from rawBody: String) -> TimeInterval? {
    let pattern = #"retry[_\s-]?after"\s*:\s*(\d+(?:\.\d+)?)"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
      return nil
    }
    let ns = rawBody as NSString
    let range = NSRange(location: 0, length: ns.length)
    guard let match = regex.firstMatch(in: rawBody, options: [], range: range),
      match.numberOfRanges > 1
    else { return nil }
    let value = ns.substring(with: match.range(at: 1))
    return TimeInterval(value)
  }
}

extension OpenRouterError {
  static func decodingFailed(statusCode: Int, underlying: Error) -> Self {
    .decodingFailed(statusCode: statusCode, underlying: String(describing: underlying))
  }
}
