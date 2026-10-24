import Foundation
import XCTest

@testable import OpenRouter

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterAuthLoggingTests: XCTestCase {
  override func tearDown() {
    URLProtocolAuthLoggingStub.handler = nil
    super.tearDown()
  }

  func testSuccessfulExchangeLogsMetadataWithoutCredentials() async throws {
    let events = AuthLoggingEventBox()
    let exchange = ExchangeAuthCodeForAPIKeyRequest(
      code: "fake-auth-code", codeVerifier: "fake-pkce-verifier", codeChallengeMethod: "S256")
    let expected = ExchangeAuthCodeForAPIKeyResponse(
      key: "fake-exchanged-key", userID: "fake-user")
    URLProtocolAuthLoggingStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/v1/auth/keys")
      XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
      let decoded = try JSONDecoder().decode(
        ExchangeAuthCodeForAPIKeyRequest.self, from: try authLoggingRequestBody(request))
      XCTAssertEqual(decoded, exchange)
      XCTAssertEqual(decoded.code, "fake-auth-code")
      XCTAssertEqual(decoded.codeVerifier, "fake-pkce-verifier")
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil,
          headerFields: nil)
      )
      return (response, try JSONEncoder().encode(expected))
    }
    let session = makeSession()
    defer { session.invalidateAndCancel() }
    let client = OpenRouterClient(
      apiKey: "fake-configured-bearer-key",
      configuration: .init(debugLogger: { events.append($0) }), session: session)

    let result = try await client.exchangeAuthCodeForAPIKey(exchange)

    XCTAssertEqual(result, expected)
    XCTAssertEqual(result.key, "fake-exchanged-key")
    XCTAssertEqual(result.userID, "fake-user")
    XCTAssertEqual(
      try JSONDecoder().decode(
        ExchangeAuthCodeForAPIKeyResponse.self, from: JSONEncoder().encode(result)), expected)
    let logged = events.all()
    XCTAssertEqual(
      logged,
      [
        .init(message: "request", method: "POST", path: "/api/v1/auth/keys"),
        .init(message: "response", statusCode: 200),
      ])
    assertNoCredentials(in: logged)
  }

  func testFailedExchangeLogsStatusWithoutCredentialBearingErrorBody() async throws {
    let events = AuthLoggingEventBox()
    // Deliberately echo fake credentials in the envelope to guard against logging error bodies.
    let errorMessage = "Rejected fake-auth-code fake-pkce-verifier fake-exchanged-key"
    URLProtocolAuthLoggingStub.handler = { request in
      XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: try XCTUnwrap(request.url), statusCode: 403, httpVersion: nil,
          headerFields: nil)
      )
      let data = try JSONSerialization.data(withJSONObject: [
        "error": ["code": 403, "message": errorMessage]
      ])
      return (response, data)
    }
    let session = makeSession()
    defer { session.invalidateAndCancel() }
    let client = OpenRouterClient(
      apiKey: "fake-configured-bearer-key",
      configuration: .init(debugLogger: { events.append($0) }), session: session)

    do {
      _ = try await client.exchangeAuthCodeForAPIKey(
        .init(code: "fake-auth-code", codeVerifier: "fake-pkce-verifier"))
      XCTFail("Expected exchange to fail")
    } catch let OpenRouterError.apiError(statusCode, code, message, _) {
      XCTAssertEqual(statusCode, 403)
      XCTAssertEqual(code, 403)
      XCTAssertEqual(message, errorMessage)
    }

    let logged = events.all()
    XCTAssertEqual(
      logged,
      [
        .init(message: "request", method: "POST", path: "/api/v1/auth/keys"),
        .init(message: "api_error", statusCode: 403),
      ])
    assertNoCredentials(in: logged)
  }

  func testExchangeRejectsSessionAuthorizationBeforeLoggingOrSending() async throws {
    for header in ["Authorization", "authorization", "AuThOrIzAtIoN"] {
      let events = AuthLoggingEventBox()
      URLProtocolAuthLoggingStub.handler = { request in
        // Only the subsequent authenticated control request may reach the session.
        XCTAssertEqual(request.url?.path, "/api/v1/chat/completions")
        XCTAssertEqual(
          request.value(forHTTPHeaderField: "Authorization"), "Bearer fake-configured-bearer-key")
        let response = try XCTUnwrap(
          HTTPURLResponse(
            url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil))
        let body =
          #"{"id":"fake-id","model":"fake-model","choices":[{"index":0,"message":{"role":"assistant","content":"ok"}}]}"#
        return (response, Data(body.utf8))
      }
      let session = makeSession(additionalHeaders: [header: "Bearer fake-session-key"])
      defer { session.invalidateAndCancel() }
      let client = OpenRouterClient(
        apiKey: "fake-configured-bearer-key",
        configuration: .init(debugLogger: { events.append($0) }), session: session)

      do {
        _ = try await client.exchangeAuthCodeForAPIKey(.init(code: "fake-auth-code"))
        XCTFail("Expected session Authorization rejection for \(header)")
      } catch {
        XCTAssertEqual(error as? OpenRouterError, .unauthenticatedSessionRequired)
      }
      XCTAssertTrue(events.all().isEmpty)

      _ = try await client.createChatCompletion(
        .init(model: "fake-model", messages: [.user("hello")]))
      XCTAssertEqual(
        events.all(),
        [
          .init(message: "request", method: "POST", path: "/api/v1/chat/completions"),
          .init(message: "response", statusCode: 200),
        ])
    }
  }

  func testExchangeAllowsSessionWithNonAuthorizationHeaders() async throws {
    let events = AuthLoggingEventBox()
    URLProtocolAuthLoggingStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/v1/auth/keys")
      XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil))
      return (response, Data(#"{"key":"fake-exchanged-key"}"#.utf8))
    }
    let session = makeSession(additionalHeaders: ["X-Test-Session": "allowed"])
    defer { session.invalidateAndCancel() }
    let client = OpenRouterClient(
      configuration: .init(debugLogger: { events.append($0) }), session: session)

    let response = try await client.exchangeAuthCodeForAPIKey(.init(code: "fake-auth-code"))

    XCTAssertEqual(response.key, "fake-exchanged-key")
    XCTAssertEqual(
      session.configuration.httpAdditionalHeaders?["X-Test-Session"] as? String, "allowed")
    XCTAssertEqual(
      events.all(),
      [
        .init(message: "request", method: "POST", path: "/api/v1/auth/keys"),
        .init(message: "response", statusCode: 200),
      ])
    assertNoCredentials(in: events.all())
  }

  private func makeSession(additionalHeaders: [String: String] = [:]) -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolAuthLoggingStub.self]
    configuration.httpAdditionalHeaders = additionalHeaders
    return URLSession(configuration: configuration)
  }

  private func assertNoCredentials(
    in events: [OpenRouterDebugEvent], file: StaticString = #filePath, line: UInt = #line
  ) {
    XCTAssertFalse(events.isEmpty, file: file, line: line)
    for event in events {
      let fields = [
        event.message, event.method ?? "", event.path ?? "",
        event.statusCode.map(String.init) ?? "", event.retryAttempt.map(String.init) ?? "",
        String(describing: event), String(reflecting: event),
      ]
      for credential in [
        "fake-auth-code", "fake-pkce-verifier", "fake-exchanged-key", "fake-configured-bearer-key",
      ] {
        for field in fields {
          XCTAssertFalse(field.contains(credential), file: file, line: line)
        }
      }
    }
  }
}

private final class AuthLoggingEventBox: @unchecked Sendable {
  private let lock = NSLock()
  private var values: [OpenRouterDebugEvent] = []

  func append(_ event: OpenRouterDebugEvent) {
    lock.lock()
    defer { lock.unlock() }
    values.append(event)
  }

  func all() -> [OpenRouterDebugEvent] {
    lock.lock()
    defer { lock.unlock() }
    return values
  }
}

private func authLoggingRequestBody(_ request: URLRequest) throws -> Data {
  if let body = request.httpBody { return body }
  let stream = try XCTUnwrap(request.httpBodyStream)
  stream.open()
  defer { stream.close() }
  var data = Data()
  var buffer = [UInt8](repeating: 0, count: 1024)
  while true {
    let count = stream.read(&buffer, maxLength: buffer.count)
    if count < 0 { throw stream.streamError ?? URLError(.cannotDecodeRawData) }
    if count == 0 { return data }
    data.append(contentsOf: buffer.prefix(count))
  }
}

private final class URLProtocolAuthLoggingStub: URLProtocol {
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
