import Foundation
import XCTest

@testable import OpenRouter

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterTransportTests: XCTestCase {
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
}

extension OpenRouterClient.Configuration {
  fileprivate func withAPIKeyForTests(_ value: String) -> Self {
    var copy = self
    copy.apiKey = value
    return copy
  }
}
