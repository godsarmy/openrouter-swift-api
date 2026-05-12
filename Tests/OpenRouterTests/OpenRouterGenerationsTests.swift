import Foundation
import XCTest

@testable import OpenRouter

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterGenerationsTests: XCTestCase {
  override class func setUp() {
    super.setUp()
    URLProtocolGenerationsStub.register()
  }

  override class func tearDown() {
    URLProtocolGenerationsStub.unregister()
    super.tearDown()
  }

  func testGetGenerationBuildsGETWithIdQueryAndHeaders() async throws {
    URLProtocolGenerationsStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/v1/generation")
      XCTAssertEqual(
        URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first?.name,
        "id")
      XCTAssertEqual(
        URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first?.value,
        "gen_1")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
      XCTAssertEqual(request.value(forHTTPHeaderField: "HTTP-Referer"), "https://example.com")
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-OpenRouter-Title"), "Test App")
      let body = #"{"data":{"id":"gen_1","status":"ok"}}"#.data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"])!
      return (response, body)
    }

    let value = try await makeClient().getGeneration(id: "gen_1")
    XCTAssertEqual(value.data?.id, "gen_1")
  }

  func testListGenerationContentBuildsGETWithIdQueryAndHeaders() async throws {
    URLProtocolGenerationsStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/v1/generation/content")
      XCTAssertEqual(
        URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first?.name,
        "id")
      XCTAssertEqual(
        URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first?.value,
        "gen_2")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
      XCTAssertEqual(request.value(forHTTPHeaderField: "HTTP-Referer"), "https://example.com")
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-OpenRouter-Title"), "Test App")
      let body =
        #"{"data":{"id":"gen_2","raw_content":{"items":[{"type":"text","text":"hello"}]}}}"#.data(
          using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"])!
      return (response, body)
    }

    let value = try await makeClient().listGenerationContent(id: "gen_2")
    XCTAssertEqual(value.data?.id, "gen_2")
  }

  func testGenerationMethodsDecodeTypedObject() async throws {
    URLProtocolGenerationsStub.handler = { request in
      let body = #"{"data":{"id":"gen_typed","provider_name":"openai","tokens_prompt":7}}"#.data(
        using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"])!
      return (response, body)
    }

    let value = try await makeClient().getGeneration(id: "any")
    XCTAssertEqual(value.data?.id, "gen_typed")
    XCTAssertEqual(value.data?.providerName, "openai")
    XCTAssertEqual(value.data?.tokensPrompt, 7)
  }

  func testListGenerationContentResponseDecodesTypedObject() async throws {
    URLProtocolGenerationsStub.handler = { request in
      let body =
        #"{"data":{"id":"gen_typed_content","raw_content":{"items":[{"type":"text","text":"hello"}]}}}"#
        .data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"])!
      return (response, body)
    }

    let value = try await makeClient().listGenerationContent(id: "any")
    XCTAssertEqual(value.data?.id, "gen_typed_content")
    XCTAssertNotNil(value.data?.rawContent)
  }

  func testGenerationRawMethodsDecodeJSONValueObject() async throws {
    URLProtocolGenerationsStub.handler = { request in
      let body = #"{"nested":{"count":2},"ok":true}"#.data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"])!
      return (response, body)
    }

    let value = try await makeClient().getGenerationRaw(id: "any")
    guard case .object(let obj) = value else { return XCTFail("Expected object") }
    XCTAssertEqual(obj["ok"], .bool(true))
  }

  func testListGenerationContentRawMethodDecodeJSONValueObject() async throws {
    URLProtocolGenerationsStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/v1/generation/content")
      let body = #"{"items":[{"type":"text","text":"hello"}],"ok":true}"#.data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"])!
      return (response, body)
    }

    let value = try await makeClient().listGenerationContentRaw(id: "any")
    guard case .object(let obj) = value else { return XCTFail("Expected object") }
    XCTAssertEqual(obj["ok"], .bool(true))
  }

  func testGenerationMethodsMapAPIErrorEnvelope() async throws {
    URLProtocolGenerationsStub.handler = { request in
      let body = #"{"error":{"code":404,"message":"missing generation"}}"#.data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 404, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"])!
      return (response, body)
    }

    do {
      _ = try await makeClient().getGenerationRaw(id: "missing")
      XCTFail("Expected apiError")
    } catch let error as OpenRouterError {
      guard case .apiError(let status, let code, let message, _) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(status, 404)
      XCTAssertEqual(code, 404)
      XCTAssertEqual(message, "missing generation")
    }
  }

  func testGenerationMethodsMapNonJSONErrorBodyToAPIErrorWithRawBody() async throws {
    URLProtocolGenerationsStub.handler = { request in
      let body = "gateway timeout".data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 504, httpVersion: nil,
        headerFields: ["Content-Type": "text/plain"])!
      return (response, body)
    }

    do {
      _ = try await makeClient().getGenerationRaw(id: "gen_timeout")
      XCTFail("Expected apiError")
    } catch let error as OpenRouterError {
      guard case .apiError(let status, let code, let message, let rawBody) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(status, 504)
      XCTAssertNil(code)
      XCTAssertNil(message)
      XCTAssertEqual(rawBody, "gateway timeout")
    }
  }

  func testGenerationMethodsMap200InvalidJSONToDecodingFailed() async throws {
    URLProtocolGenerationsStub.handler = { request in
      let body = "{not-json}".data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"])!
      return (response, body)
    }

    do {
      _ = try await makeClient().getGenerationRaw(id: "gen_bad_json")
      XCTFail("Expected decodingFailed")
    } catch let error as OpenRouterError {
      guard case .decodingFailed(let statusCode, let underlying) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(statusCode, 200)
      XCTAssertFalse(underlying.isEmpty)
    }
  }

  func testGenerationMethodsBubbleTransportFailure() async throws {
    URLProtocolGenerationsStub.handler = { _ in
      throw URLError(.notConnectedToInternet)
    }

    do {
      _ = try await makeClient().getGenerationRaw(id: "gen_network")
      XCTFail("Expected URLError")
    } catch let error as URLError {
      XCTAssertEqual(error.code, .notConnectedToInternet)
    }
  }

  private func makeClient() -> OpenRouterClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolGenerationsStub.self]
    return OpenRouterClient(
      apiKey: "test-key",
      configuration: .init(
        baseURL: URL(string: "https://openrouter.ai/api/v1")!, httpReferer: "https://example.com",
        appTitle: "Test App"),
      session: URLSession(configuration: config)
    )
  }
}

private final class URLProtocolGenerationsStub: URLProtocol {
  static nonisolated(unsafe) var handler:
    (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?
  static func register() { _ = URLProtocol.registerClass(URLProtocolGenerationsStub.self) }
  static func unregister() {
    URLProtocol.unregisterClass(URLProtocolGenerationsStub.self)
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
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }
  override func stopLoading() {}
}
