import Foundation

/// An inline batch submission. Request bodies must be JSON objects.
public struct CreateBatchRequest: Codable, Sendable, Equatable {
  public var endpoint: String
  public var model: String
  public var requests: [BatchRequestItem]
  public var completionWindow: String?
  public var provider: BatchProviderPreferences?
  public var callbackURL: String?

  private enum CodingKeys: String, CodingKey {
    case endpoint, model, requests, provider
    case completionWindow = "completion_window"
    case callbackURL = "callback_url"
  }

  public init(
    endpoint: String, model: String, requests: [BatchRequestItem], completionWindow: String? = nil,
    provider: BatchProviderPreferences? = nil, callbackURL: String? = nil
  ) {
    self.endpoint = endpoint
    self.model = model
    self.requests = requests
    self.completionWindow = completionWindow
    self.provider = provider
    self.callbackURL = callbackURL
  }
}

public struct BatchRequestItem: Codable, Sendable, Equatable {
  public var customID: String
  public var body: [String: JSONValue]

  private enum CodingKeys: String, CodingKey {
    case customID = "custom_id"
    case body
  }

  public init(customID: String, body: [String: JSONValue]) {
    self.customID = customID
    self.body = body
  }
}

/// The provider preferences supported by batch submissions.
public struct BatchProviderPreferences: Codable, Sendable, Equatable {
  public var only: [String]?
  public var allowFallbacks: Bool?

  private enum CodingKeys: String, CodingKey {
    case only
    case allowFallbacks = "allow_fallbacks"
  }

  public init(only: [String]? = nil, allowFallbacks: Bool? = nil) {
    self.only = only
    self.allowFallbacks = allowFallbacks
  }
}

public struct BatchRequestCounts: Codable, Sendable, Equatable {
  public var total: Int
  public var completed: Int
  public var failed: Int

  public init(total: Int, completed: Int, failed: Int) {
    self.total = total
    self.completed = completed
    self.failed = failed
  }

  fileprivate var payload: JSONValue {
    .object([
      "total": .number(Double(total)), "completed": .number(Double(completed)),
      "failed": .number(Double(failed)),
    ])
  }
}

public struct BatchError: Codable, Sendable, Equatable {
  public var message: String
  public var code: Int?

  public init(message: String, code: Int? = nil) {
    self.message = message
    self.code = code
  }

  fileprivate var payload: JSONValue {
    var fields: [String: JSONValue] = ["message": .string(message)]
    if let code { fields["code"] = .number(Double(code)) }
    return .object(fields)
  }
}

public struct BatchResultError: Codable, Sendable, Equatable {
  public var type: String
  public var message: String
  public var param: String?
  public var errorType: String?

  private enum CodingKeys: String, CodingKey {
    case type, message, param
    case errorType = "error_type"
  }

  public init(type: String, message: String, param: String? = nil, errorType: String? = nil) {
    self.type = type
    self.message = message
    self.param = param
    self.errorType = errorType
  }

  fileprivate var payload: JSONValue {
    var fields: [String: JSONValue] = [
      "type": .string(type), "message": .string(message),
      "param": param.map(JSONValue.string) ?? .null,
    ]
    if let errorType { fields["error_type"] = .string(errorType) }
    return .object(fields)
  }
}

public struct BatchResultResponse: Codable, Sendable, Equatable {
  public var statusCode: Int
  public var requestID: String?
  /// The complete endpoint-specific response body as raw JSON.
  public var body: JSONValue

  private enum CodingKeys: String, CodingKey {
    case statusCode = "status_code"
    case requestID = "request_id"
    case body
  }

  public init(statusCode: Int, requestID: String? = nil, body: JSONValue) {
    self.statusCode = statusCode
    self.requestID = requestID
    self.body = body
  }

  fileprivate var payload: JSONValue {
    .object([
      "status_code": .number(Double(statusCode)),
      "request_id": requestID.map(JSONValue.string) ?? .null, "body": body,
    ])
  }
}

public struct BatchResult: Codable, Sendable, Equatable {
  public var id: String
  public var customID: String
  public var response: BatchResultResponse?
  public var error: BatchResultError?

  private enum CodingKeys: String, CodingKey {
    case id, response, error
    case customID = "custom_id"
  }

  public init(
    id: String, customID: String, response: BatchResultResponse? = nil,
    error: BatchResultError? = nil
  ) {
    self.id = id
    self.customID = customID
    self.response = response
    self.error = error
  }

  fileprivate var payload: JSONValue {
    .object([
      "id": .string(id), "custom_id": .string(customID), "response": response?.payload ?? .null,
      "error": error?.payload ?? .null,
    ])
  }
}

/// A batch snapshot. Status and endpoint values remain open strings.
/// Encoding uses `rawPayload` verbatim, preserving extensions at every nesting level;
/// later mutations of typed fields do not rebuild the authoritative payload.
public struct BatchObject: Codable, Sendable, Equatable {
  public var id: String
  public var object: String
  public var endpoint: String
  public var model: String
  public var completionWindow: String
  public var status: String
  /// Integer Unix timestamp in seconds.
  public var createdAt: Int
  /// Integer Unix timestamp in seconds, when available.
  public var finalizedAt: Int?
  public var provider: String?
  /// Integer Unix timestamp in seconds, when available.
  public var expiresAt: Int?
  public var requestCounts: BatchRequestCounts
  public var usage: JSONValue?
  public var results: [BatchResult]?
  public var error: BatchError?
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey {
    case id, object, endpoint, model, status, provider, usage, results, error
    case completionWindow = "completion_window"
    case createdAt = "created_at"
    case finalizedAt = "finalized_at"
    case expiresAt = "expires_at"
    case requestCounts = "request_counts"
  }

  /// Builds a wire payload from typed fields unless an authoritative payload is supplied.
  public init(
    id: String, object: String, endpoint: String, model: String, completionWindow: String,
    status: String, createdAt: Int, finalizedAt: Int? = nil, provider: String? = nil,
    expiresAt: Int? = nil, requestCounts: BatchRequestCounts, usage: JSONValue? = nil,
    results: [BatchResult]? = nil, error: BatchError? = nil, rawPayload: JSONValue? = nil
  ) {
    self.id = id
    self.object = object
    self.endpoint = endpoint
    self.model = model
    self.completionWindow = completionWindow
    self.status = status
    self.createdAt = createdAt
    self.finalizedAt = finalizedAt
    self.provider = provider
    self.expiresAt = expiresAt
    self.requestCounts = requestCounts
    self.usage = usage
    self.results = results
    self.error = error
    var fields: [String: JSONValue] = [
      "id": .string(id), "object": .string(object), "endpoint": .string(endpoint),
      "model": .string(model),
      "completion_window": .string(completionWindow), "status": .string(status),
      "created_at": .number(Double(createdAt)),
      "request_counts": requestCounts.payload, "usage": usage ?? .null,
      "error": error?.payload ?? .null,
    ]
    fields["finalized_at"] = finalizedAt.map { JSONValue.number(Double($0)) } ?? .null
    fields["provider"] = provider.map(JSONValue.string) ?? .null
    fields["expires_at"] = expiresAt.map { JSONValue.number(Double($0)) } ?? .null
    fields["results"] = results.map { JSONValue.array($0.map(\.payload)) } ?? .null
    self.rawPayload = rawPayload ?? .object(fields)
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    object = try container.decode(String.self, forKey: .object)
    endpoint = try container.decode(String.self, forKey: .endpoint)
    model = try container.decode(String.self, forKey: .model)
    completionWindow = try container.decode(String.self, forKey: .completionWindow)
    status = try container.decode(String.self, forKey: .status)
    createdAt = try container.decode(Int.self, forKey: .createdAt)
    finalizedAt = try container.decodeIfPresent(Int.self, forKey: .finalizedAt)
    provider = try container.decodeIfPresent(String.self, forKey: .provider)
    expiresAt = try container.decodeIfPresent(Int.self, forKey: .expiresAt)
    requestCounts = try container.decode(BatchRequestCounts.self, forKey: .requestCounts)
    usage = try container.decodeIfPresent(JSONValue.self, forKey: .usage)
    results = try container.decodeIfPresent([BatchResult].self, forKey: .results)
    error = try container.decodeIfPresent(BatchError.self, forKey: .error)
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}

/// A batch page. Encoding uses the authoritative `rawPayload`, not later field mutations.
public struct BatchListResponse: Codable, Sendable, Equatable {
  public var object: String
  public var data: [BatchObject]
  public var firstID: String?
  public var lastID: String?
  public var hasMore: Bool
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey {
    case object, data
    case firstID = "first_id"
    case lastID = "last_id"
    case hasMore = "has_more"
  }

  public init(
    object: String, data: [BatchObject], firstID: String? = nil, lastID: String? = nil,
    hasMore: Bool, rawPayload: JSONValue? = nil
  ) {
    self.object = object
    self.data = data
    self.firstID = firstID
    self.lastID = lastID
    self.hasMore = hasMore
    self.rawPayload =
      rawPayload
      ?? .object([
        "object": .string(object), "data": .array(data.map(\.rawPayload)),
        "first_id": firstID.map(JSONValue.string) ?? .null,
        "last_id": lastID.map(JSONValue.string) ?? .null, "has_more": .bool(hasMore),
      ])
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    object = try container.decode(String.self, forKey: .object)
    data = try container.decode([BatchObject].self, forKey: .data)
    firstID = try container.decodeIfPresent(String.self, forKey: .firstID)
    lastID = try container.decodeIfPresent(String.self, forKey: .lastID)
    hasMore = try container.decode(Bool.self, forKey: .hasMore)
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}
