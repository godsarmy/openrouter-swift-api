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
    XCTAssertEqual(req.value(forHTTPHeaderField: "X-Title"), "Example App")
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

extension OpenRouterClient.Configuration {
  fileprivate func withAPIKeyForTests(_ value: String) -> Self {
    var copy = self
    copy.apiKey = value
    return copy
  }
}
