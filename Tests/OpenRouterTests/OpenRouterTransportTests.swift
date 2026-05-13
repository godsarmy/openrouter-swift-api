import Foundation
import XCTest

@testable import OpenRouter

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterTransportTests: XCTestCase {
  func testDecodeResponseThrowsInvalidResponseForNonHTTPURLResponse() throws {
    let config = OpenRouterClient.Configuration().withAPIKeyForTests("abc123")
    let transport = HTTPTransport(configuration: config)
    let nonHTTPResponse = URLResponse(
      url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!,
      mimeType: "application/json",
      expectedContentLength: 0,
      textEncodingName: nil
    )

    XCTAssertThrowsError(
      try transport.decodeResponse(
        data: Data("{}".utf8),
        response: nonHTTPResponse,
        responseType: ChatCompletionResponse.self
      )
    ) { error in
      XCTAssertEqual(error as? OpenRouterError, .invalidResponse)
    }
  }

  func testBuildRequestIncludesAuthAndOptionalHeaders() throws {
    let config = OpenRouterClient.Configuration(
      baseURL: URL(string: "https://openrouter.ai/api/v1")!,
      timeout: 10,
      httpReferer: "https://example.com",
      appTitle: "Official App",
      appCategories: ["devtools", "sdk"],
      experimentalMetadata: "exp-v1",
      xTitle: "Example App"
    )
    .withAPIKeyForTests("abc123")

    let transport = HTTPTransport(configuration: config)
    let req = try transport.buildRequest(
      path: "chat/completions",
      body: ChatCompletionRequest(model: "m", messages: [.user("hi")])
    )

    XCTAssertEqual(req.value(forHTTPHeaderField: "Authorization"), "Bearer abc123")
    XCTAssertEqual(req.value(forHTTPHeaderField: "HTTP-Referer"), "https://example.com")
    XCTAssertEqual(req.value(forHTTPHeaderField: "X-OpenRouter-Title"), "Official App")
    XCTAssertNil(req.value(forHTTPHeaderField: "X-Title"))
    XCTAssertEqual(req.value(forHTTPHeaderField: "X-OpenRouter-Categories"), "devtools,sdk")
    XCTAssertEqual(req.value(forHTTPHeaderField: "X-OpenRouter-Experimental-Metadata"), "exp-v1")
    XCTAssertEqual(req.httpMethod, "POST")
  }

  func testBuildRequestIncludesResponseCacheHeadersWhenConfigured() throws {
    let config = OpenRouterClient.Configuration().withAPIKeyForTests("abc123")
    let transport = HTTPTransport(configuration: config)
    let req = try transport.buildRequest(
      path: "chat/completions",
      body: ChatCompletionRequest(
        model: "m",
        messages: [.user("hi")],
        responseCache: .init(enabled: true, ttlSeconds: 600, clear: true)
      )
    )

    XCTAssertEqual(req.value(forHTTPHeaderField: "X-OpenRouter-Cache"), "true")
    XCTAssertEqual(req.value(forHTTPHeaderField: "X-OpenRouter-Cache-TTL"), "600")
    XCTAssertEqual(req.value(forHTTPHeaderField: "X-OpenRouter-Cache-Clear"), "true")
  }

  func testBuildRequestUsesXTitleAsAliasForOpenRouterTitle() throws {
    let config = OpenRouterClient.Configuration(
      baseURL: URL(string: "https://openrouter.ai/api/v1")!,
      xTitle: "Alias App"
    )
    .withAPIKeyForTests("abc123")

    let transport = HTTPTransport(configuration: config)
    let req = try transport.buildRequest(
      path: "chat/completions",
      body: ChatCompletionRequest(model: "m", messages: [.user("hi")])
    )

    XCTAssertEqual(req.value(forHTTPHeaderField: "X-OpenRouter-Title"), "Alias App")
    XCTAssertNil(req.value(forHTTPHeaderField: "X-Title"))
  }

  func testDecodeResponseMapsAPIErrorEnvelope() throws {
    let config = OpenRouterClient.Configuration().withAPIKeyForTests("abc123")
    let transport = HTTPTransport(configuration: config)

    let body = #"{"error":{"code":429,"message":"rate limited"}}"#.data(using: .utf8)!
    let response = HTTPURLResponse(
      url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!,
      statusCode: 429,
      httpVersion: nil,
      headerFields: nil
    )!

    XCTAssertThrowsError(
      try transport.decodeResponse(
        data: body,
        response: response,
        responseType: ChatCompletionResponse.self
      )
    ) { error in
      guard case OpenRouterError.apiError(let status, let code, let message, _) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(status, 429)
      XCTAssertEqual(code, 429)
      XCTAssertEqual(message, "rate limited")
    }
  }

  func testDebugLoggerReceivesRedactedRequestAndResponseEvents() async throws {
    final class EventBox: @unchecked Sendable {
      private let lock = NSLock()
      private var values: [OpenRouterDebugEvent] = []

      func append(_ value: OpenRouterDebugEvent) {
        lock.lock()
        defer { lock.unlock() }
        values.append(value)
      }

      func all() -> [OpenRouterDebugEvent] {
        lock.lock()
        defer { lock.unlock() }
        return values
      }
    }

    let events = EventBox()
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolTransportDebugStub.self]
    URLProtocolTransportDebugStub.handler = { request in
      let body =
        #"{"id":"x","model":"m","choices":[{"index":0,"message":{"role":"assistant","content":"ok"}}]}"#
        .data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, body)
    }

    let client = OpenRouterClient(
      apiKey: "abc123",
      configuration: .init(debugLogger: { events.append($0) }),
      session: URLSession(configuration: config)
    )

    _ = try await client.createChatCompletion(.init(model: "m", messages: [.user("hi")]))

    XCTAssertTrue(
      events.all().contains { $0.message == "request" && $0.path == "/api/v1/chat/completions" })
    XCTAssertTrue(events.all().contains { $0.message == "response" && $0.statusCode == 200 })
  }

  func testDecodeResponseAttachesResponseCacheMetadataFromHeaders() throws {
    let config = OpenRouterClient.Configuration().withAPIKeyForTests("abc123")
    let transport = HTTPTransport(configuration: config)

    let body =
      #"{"id":"x","model":"m","choices":[{"index":0,"message":{"role":"assistant","content":"ok"},"finish_reason":"stop"}]}"#
      .data(using: .utf8)!
    let response = HTTPURLResponse(
      url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: [
        "X-OpenRouter-Cache-Status": "HIT",
        "X-OpenRouter-Cache-Age": "12",
        "X-OpenRouter-Cache-TTL": "288",
        "X-Generation-Id": "gen_123",
      ]
    )!

    let decoded = try transport.decodeResponse(
      data: body,
      response: response,
      responseType: ChatCompletionResponse.self
    )

    XCTAssertEqual(decoded.responseCache?.status, "HIT")
    XCTAssertEqual(decoded.responseCache?.ageSeconds, 12)
    XCTAssertEqual(decoded.responseCache?.ttlSeconds, 288)
    XCTAssertEqual(decoded.responseCache?.generationID, "gen_123")
  }
}

private final class URLProtocolTransportDebugStub: URLProtocol {
  static nonisolated(unsafe) var handler:
    (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    guard let handler = Self.handler else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }
    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}

extension OpenRouterClient.Configuration {
  fileprivate func withAPIKeyForTests(_ value: String) -> Self {
    var copy = self
    copy.apiKey = value
    return copy
  }
}
