import Foundation
import XCTest

@testable import OpenRouter

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterErrorMappingTests: XCTestCase {
  func testDecodeResponseMaps401403404422429500Series() throws {
    var config = OpenRouterClient.Configuration()
    config.apiKey = "k"
    let transport = HTTPTransport(configuration: config)
    let statuses = [401, 403, 404, 422, 429, 500, 502, 503]

    for status in statuses {
      let body = "{\"error\":{\"code\":\(status),\"message\":\"mapped\"}}".data(using: .utf8)!
      let response = HTTPURLResponse(
        url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!, statusCode: status,
        httpVersion: nil, headerFields: nil)!

      XCTAssertThrowsError(
        try transport.decodeResponse(
          data: body, response: response, responseType: ChatCompletionResponse.self)
      ) { error in
        guard case OpenRouterError.apiError(let mappedStatus, let code, let message, _) = error
        else {
          return XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(mappedStatus, status)
        XCTAssertEqual(code, status)
        XCTAssertEqual(message, "mapped")
      }
    }
  }

  func testDecodeResponseHandlesNonJSONErrorBody() throws {
    var config = OpenRouterClient.Configuration()
    config.apiKey = "k"
    let transport = HTTPTransport(configuration: config)
    let body = "gateway timeout".data(using: .utf8)!
    let response = HTTPURLResponse(
      url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!, statusCode: 504,
      httpVersion: nil, headerFields: nil)!

    XCTAssertThrowsError(
      try transport.decodeResponse(
        data: body, response: response, responseType: ChatCompletionResponse.self)
    ) { error in
      guard case OpenRouterError.apiError(let status, let code, let message, let rawBody) = error
      else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(status, 504)
      XCTAssertNil(code)
      XCTAssertNil(message)
      XCTAssertEqual(rawBody, "gateway timeout")
    }
  }

  func testDecodeResponseHandlesMalformedEnvelopeGracefully() throws {
    var config = OpenRouterClient.Configuration()
    config.apiKey = "k"
    let transport = HTTPTransport(configuration: config)
    let body = #"{"error":{"message_only":"bad"}}"#.data(using: .utf8)!
    let response = HTTPURLResponse(
      url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!, statusCode: 400,
      httpVersion: nil, headerFields: nil)!

    XCTAssertThrowsError(
      try transport.decodeResponse(
        data: body, response: response, responseType: ChatCompletionResponse.self)
    ) { error in
      guard case OpenRouterError.apiError(let status, let code, let message, let rawBody) = error
      else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(status, 400)
      XCTAssertNil(code)
      XCTAssertNil(message)
      XCTAssertEqual(rawBody, #"{"error":{"message_only":"bad"}}"#)
    }
  }
}
