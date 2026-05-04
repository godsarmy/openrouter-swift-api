import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct HTTPTransport {
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

    guard let url = URL(string: path, relativeTo: configuration.baseURL) else {
      throw OpenRouterError.invalidURL(path)
    }

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
        return try JSONDecoder().decode(responseType, from: data)
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
}

struct OpenRouterAPIErrorEnvelope: Codable, Equatable, Sendable {
  let error: OpenRouterAPIErrorBody
}

struct OpenRouterAPIErrorBody: Codable, Equatable, Sendable {
  let code: Int?
  let message: String?
}
