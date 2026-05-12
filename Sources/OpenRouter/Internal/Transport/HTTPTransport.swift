import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct HTTPTransport: @unchecked Sendable {
  let configuration: OpenRouterClient.Configuration
  let session: URLSession

  init(configuration: OpenRouterClient.Configuration, session: URLSession = .shared) {
    self.configuration = configuration
    self.session = session
  }

  func post<Request: Encodable, Response: Decodable>(
    path: String,
    requestBody: Request,
    responseType: Response.Type,
    options: RequestOptions? = nil
  ) async throws -> Response {
    let request = try buildRequest(path: path, body: requestBody, options: options)
    let (data, response) = try await execute(request: request, options: options)
    return try decodeResponse(data: data, response: response, responseType: responseType)
  }

  func get<Response: Decodable>(
    path: String,
    queryItems: [URLQueryItem] = [],
    responseType: Response.Type,
    options: RequestOptions? = nil
  ) async throws -> Response {
    let request = try buildGetRequest(path: path, queryItems: queryItems, options: options)
    let (data, response) = try await execute(request: request, options: options)
    return try decodeResponse(data: data, response: response, responseType: responseType)
  }

  func buildRequest<Body: Encodable>(
    path: String,
    body: Body,
    options: RequestOptions? = nil
  ) throws -> URLRequest {
    guard let apiKey = configuration.apiKey, !apiKey.isEmpty else {
      throw OpenRouterError.missingAPIKey
    }

    let url = (options?.baseURL ?? configuration.baseURL).appendingPathComponent(path)

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = options?.timeout ?? configuration.timeout
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    applyCommonHeaders(to: &request)
    applyExtraHeaders(options?.extraHeaders ?? [:], to: &request)

    if let body = body as? ResponseCacheConfigProviding,
      let responseCache = body.responseCacheConfig
    {
      applyResponseCacheHeaders(responseCache, to: &request)
    }

    request.httpBody = try JSONEncoder().encode(body)
    return request
  }

  func buildGetRequest(
    path: String,
    queryItems: [URLQueryItem] = [],
    options: RequestOptions? = nil
  ) throws -> URLRequest {
    guard let apiKey = configuration.apiKey, !apiKey.isEmpty else {
      throw OpenRouterError.missingAPIKey
    }

    var components = URLComponents(
      url: (options?.baseURL ?? configuration.baseURL).appendingPathComponent(path),
      resolvingAgainstBaseURL: false)
    if !queryItems.isEmpty {
      components?.queryItems = queryItems
    }
    guard let url = components?.url else {
      throw OpenRouterError.invalidURL(path)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = options?.timeout ?? configuration.timeout
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    applyCommonHeaders(to: &request)
    applyExtraHeaders(options?.extraHeaders ?? [:], to: &request)

    return request
  }

  func mapAPIError(statusCode: Int, data: Data) -> OpenRouterError {
    let apiError = try? JSONDecoder().decode(OpenRouterAPIErrorEnvelope.self, from: data)
    return OpenRouterError.apiError(
      statusCode: statusCode,
      code: apiError?.error.code,
      message: apiError?.error.message,
      rawBody: String(data: data, encoding: .utf8)
    )
  }

  func decodeResponse<Response: Decodable>(
    data: Data,
    response: URLResponse,
    responseType: Response.Type
  ) throws -> Response {
    guard let http = response as? HTTPURLResponse else {
      throw OpenRouterError.invalidResponse
    }

    if (200..<300).contains(http.statusCode) {
      do {
        var decoded = try JSONDecoder().decode(responseType, from: data)
        if var attachable = decoded as? ResponseCacheMetadataAttachable {
          attachable.attachResponseCacheMetadata(parseResponseCacheMetadata(from: http))
          if let value = attachable as? Response {
            decoded = value
          }
        }
        return decoded
      } catch {
        throw OpenRouterError.decodingFailed(statusCode: http.statusCode, underlying: error)
      }
    }

    throw mapAPIError(statusCode: http.statusCode, data: data)
  }

  private func applyResponseCacheHeaders(
    _ config: ResponseCacheConfig, to request: inout URLRequest
  ) {
    if let enabled = config.enabled {
      request.setValue(enabled ? "true" : "false", forHTTPHeaderField: "X-OpenRouter-Cache")
    }
    if let ttlSeconds = config.ttlSeconds {
      request.setValue(String(ttlSeconds), forHTTPHeaderField: "X-OpenRouter-Cache-TTL")
    }
    if let clear = config.clear {
      request.setValue(clear ? "true" : "false", forHTTPHeaderField: "X-OpenRouter-Cache-Clear")
    }
  }

  private func applyCommonHeaders(to request: inout URLRequest) {
    if let referer = configuration.httpReferer {
      request.setValue(referer, forHTTPHeaderField: "HTTP-Referer")
    }

    if let appTitle = configuration.appTitle {
      request.setValue(appTitle, forHTTPHeaderField: "X-OpenRouter-Title")
    } else if let title = configuration.xTitle {
      request.setValue(title, forHTTPHeaderField: "X-OpenRouter-Title")
    }

    if let categories = configuration.appCategories, !categories.isEmpty {
      request.setValue(
        categories.joined(separator: ","), forHTTPHeaderField: "X-OpenRouter-Categories")
    }

    if let experimentalMetadata = configuration.experimentalMetadata {
      request.setValue(
        experimentalMetadata,
        forHTTPHeaderField: "X-OpenRouter-Experimental-Metadata"
      )
    }
  }

  private func applyExtraHeaders(_ headers: [String: String], to request: inout URLRequest) {
    for (key, value) in headers {
      request.setValue(value, forHTTPHeaderField: key)
    }
  }

  private func execute(request: URLRequest, options: RequestOptions?) async throws -> (
    Data, URLResponse
  ) {
    let policy = options?.retries ?? .none
    switch policy {
    case .none:
      return try await session.data(for: request)
    case .backoff(
      let maxAttempts,
      let initialDelay,
      let maxDelay,
      let exponent,
      let retryStatusCodes,
      let retryConnectionErrors
    ):
      var attempt = 1
      var lastError: Error?

      while attempt <= maxAttempts {
        do {
          let result = try await session.data(for: request)
          if shouldRetry(response: result.1, retryStatusCodes: retryStatusCodes),
            attempt < maxAttempts
          {
            let delay = nextDelay(
              response: result.1,
              attempt: attempt,
              initialDelay: initialDelay,
              maxDelay: maxDelay,
              exponent: exponent
            )
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            attempt += 1
            continue
          }
          return result
        } catch {
          lastError = error
          let canRetryConnectionError =
            retryConnectionErrors && error is URLError && attempt < maxAttempts
          guard canRetryConnectionError else { throw error }
          let delay = min(maxDelay, initialDelay * pow(exponent, Double(attempt - 1)))
          try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
          attempt += 1
        }
      }

      throw lastError ?? URLError(.unknown)
    }
  }

  private func shouldRetry(response: URLResponse, retryStatusCodes: Set<Int>) -> Bool {
    guard let http = response as? HTTPURLResponse else { return false }
    if retryStatusCodes.contains(http.statusCode) { return true }
    if retryStatusCodes.contains(500) && (500...599).contains(http.statusCode) { return true }
    return false
  }

  private func nextDelay(
    response: URLResponse,
    attempt: Int,
    initialDelay: TimeInterval,
    maxDelay: TimeInterval,
    exponent: Double
  ) -> TimeInterval {
    if let http = response as? HTTPURLResponse,
      let retryAfter = http.value(forHTTPHeaderField: "Retry-After"),
      let retryAfterSeconds = TimeInterval(retryAfter)
    {
      return min(maxDelay, retryAfterSeconds)
    }
    return min(maxDelay, initialDelay * pow(exponent, Double(attempt - 1)))
  }

  func parseResponseCacheMetadata(from response: HTTPURLResponse) -> ResponseCacheMetadata? {
    let status = response.value(forHTTPHeaderField: "X-OpenRouter-Cache-Status")
    let age = response.value(forHTTPHeaderField: "X-OpenRouter-Cache-Age").flatMap(Int.init)
    let ttl = response.value(forHTTPHeaderField: "X-OpenRouter-Cache-TTL").flatMap(Int.init)
    let generationID = response.value(forHTTPHeaderField: "X-Generation-Id")

    if status == nil, age == nil, ttl == nil, generationID == nil {
      return nil
    }

    return ResponseCacheMetadata(
      status: status,
      ageSeconds: age,
      ttlSeconds: ttl,
      generationID: generationID
    )
  }
}

protocol ResponseCacheConfigProviding {
  var responseCacheConfig: ResponseCacheConfig? { get }
}

protocol ResponseCacheMetadataAttachable {
  mutating func attachResponseCacheMetadata(_ metadata: ResponseCacheMetadata?)
}

struct OpenRouterAPIErrorEnvelope: Codable, Equatable, Sendable {
  let error: OpenRouterAPIErrorBody
}

struct OpenRouterAPIErrorBody: Codable, Equatable, Sendable {
  let code: Int?
  let message: String?
}

extension ChatCompletionRequest: ResponseCacheConfigProviding {
  var responseCacheConfig: ResponseCacheConfig? { responseCache }
}

extension EmbeddingRequest: ResponseCacheConfigProviding {
  var responseCacheConfig: ResponseCacheConfig? { responseCache }
}

extension CompletionRequest: ResponseCacheConfigProviding {
  var responseCacheConfig: ResponseCacheConfig? { responseCache }
}

extension ChatCompletionResponse: ResponseCacheMetadataAttachable {
  mutating func attachResponseCacheMetadata(_ metadata: ResponseCacheMetadata?) {
    responseCache = metadata
  }
}

extension EmbeddingResponse: ResponseCacheMetadataAttachable {
  mutating func attachResponseCacheMetadata(_ metadata: ResponseCacheMetadata?) {
    responseCache = metadata
  }
}

extension CompletionResponse: ResponseCacheMetadataAttachable {
  mutating func attachResponseCacheMetadata(_ metadata: ResponseCacheMetadata?) {
    responseCache = metadata
  }
}
