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
