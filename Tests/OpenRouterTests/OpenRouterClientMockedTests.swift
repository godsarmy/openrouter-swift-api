import Foundation
import XCTest

@testable import OpenRouter

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterClientMockedTests: XCTestCase {
  override class func setUp() {
    super.setUp()
    URLProtocolStub.register()
  }

  override class func tearDown() {
    URLProtocolStub.unregister()
    super.tearDown()
  }

  func testCreateChatCompletionUsesMockedTransport() async throws {
    let fixture = try fixtureData(named: "chat_completion_success.json")
    URLProtocolStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/chat/completions")
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!
      return (response, fixture)
    }

    let client = makeClient()
    let response = try await client.createChatCompletion(
      ChatCompletionRequest(model: "openai/gpt-4o-mini", messages: [.user("hi")]))

    XCTAssertEqual(response.id, "chatcmpl-test-1")
    XCTAssertEqual(response.choices.first?.message.content, .text("Hello from fixture"))
  }

  func testCreateChatCompletionMapsAPIError() async throws {
    let fixture = try fixtureData(named: "api_error_429.json")
    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 429,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!
      return (response, fixture)
    }

    let client = makeClient()

    do {
      _ = try await client.createChatCompletion(
        ChatCompletionRequest(model: "openai/gpt-4o-mini", messages: [.user("hi")]))
      XCTFail("Expected error")
    } catch let error as OpenRouterError {
      guard case .apiError(let status, let code, let message, _) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(status, 429)
      XCTAssertEqual(code, 429)
      XCTAssertEqual(message, "rate limited")
    }
  }

  func testCreateChatCompletionStreamSessionIncludesCacheMetadata() async throws {
    let streamBody = """
      data: {"id":"chunk-1","model":"openai/gpt-4o-mini","choices":[{"index":0,"delta":{"content":"hello"},"finish_reason":null}]}
      data: [DONE]
      """.data(using: .utf8)!

    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: [
          "Content-Type": "text/event-stream",
          "X-OpenRouter-Cache-Status": "HIT",
          "X-OpenRouter-Cache-Age": "3",
          "X-OpenRouter-Cache-TTL": "297",
          "X-Generation-Id": "gen_stream_1",
        ]
      )!
      return (response, streamBody)
    }

    let client = makeClient()
    let session = try await client.createChatCompletionStreamSession(
      ChatCompletionRequest(model: "openai/gpt-4o-mini", messages: [.user("hi")], stream: true)
    )

    XCTAssertEqual(session.responseCacheMetadata?.status, "HIT")
    XCTAssertEqual(session.responseCacheMetadata?.ageSeconds, 3)
    XCTAssertEqual(session.responseCacheMetadata?.ttlSeconds, 297)
    XCTAssertEqual(session.responseCacheMetadata?.generationID, "gen_stream_1")

    var got = ""
    for try await chunk in session.stream {
      got += chunk.choices.first?.delta?.content ?? ""
    }
    XCTAssertEqual(got, "hello")
  }

  func testStreamFallbackUsesNextModelOnFallbackableError() async throws {
    let streamBody = """
      data: {"id":"chunk-1","model":"fallback-model","choices":[{"index":0,"delta":{"content":"ok"},"finish_reason":null}]}
      data: [DONE]
      """.data(using: .utf8)!

    URLProtocolStub.handler = { request in
      let payload = try XCTUnwrap(request.httpBody)
      let json = try XCTUnwrap(JSONSerialization.jsonObject(with: payload) as? [String: Any])
      let model = try XCTUnwrap(json["model"] as? String)

      if model == "primary-model" {
        let errorData = #"{"error":{"code":429,"message":"rate limited"}}"#.data(using: .utf8)!
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 429,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )!
        return (response, errorData)
      }

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (response, streamBody)
    }

    let client = makeClient()
    let stream = client.createChatCompletionStreamWithFallback(
      ChatCompletionRequest(model: "primary-model", messages: [.user("hi")]),
      fallbackModels: ["fallback-model"]
    )

    var output = ""
    for try await chunk in stream {
      output += chunk.choices.first?.delta?.content ?? ""
    }
    XCTAssertEqual(output, "ok")
  }

  private func makeClient() -> OpenRouterClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolStub.self]
    let session = URLSession(configuration: config)
    return OpenRouterClient(
      apiKey: "test-key",
      configuration: .init(baseURL: URL(string: "https://openrouter.ai/api/v1")!),
      session: session
    )
  }

  private func fixtureData(named name: String) throws -> Data {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("Fixtures")
      .appendingPathComponent(name)
    return try Data(contentsOf: url)
  }
}

private final class URLProtocolStub: URLProtocol {
  static nonisolated(unsafe) var handler:
    (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

  static func register() {
    _ = URLProtocol.registerClass(URLProtocolStub.self)
  }

  static func unregister() {
    URLProtocol.unregisterClass(URLProtocolStub.self)
    handler = nil
  }

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
