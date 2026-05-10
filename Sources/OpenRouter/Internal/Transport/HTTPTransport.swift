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
    responseType: Response.Type
  ) async throws -> Response {
    let request = try buildRequest(path: path, body: requestBody)
    let (data, response) = try await session.data(for: request)
    return try decodeResponse(data: data, response: response, responseType: responseType)
  }

  func buildRequest<Body: Encodable>(path: String, body: Body) throws -> URLRequest {
    guard let apiKey = configuration.apiKey, !apiKey.isEmpty else {
      throw OpenRouterError.missingAPIKey
    }

    let url = configuration.baseURL.appendingPathComponent(path)

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = configuration.timeout
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    if let referer = configuration.httpReferer {
      request.setValue(referer, forHTTPHeaderField: "HTTP-Referer")
    }
    if let title = configuration.xTitle {
      request.setValue(title, forHTTPHeaderField: "X-Title")
    }

    if let body = body as? ResponseCacheConfigProviding,
      let responseCache = body.responseCacheConfig
    {
      applyResponseCacheHeaders(responseCache, to: &request)
    }

    request.httpBody = try JSONEncoder().encode(body)
    return request
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

    let apiError = try? JSONDecoder().decode(OpenRouterAPIErrorEnvelope.self, from: data)
    throw OpenRouterError.apiError(
      statusCode: http.statusCode,
      code: apiError?.error.code,
      message: apiError?.error.message,
      rawBody: String(data: data, encoding: .utf8)
    )
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
