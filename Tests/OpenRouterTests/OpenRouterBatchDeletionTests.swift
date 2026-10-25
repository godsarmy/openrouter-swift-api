import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterBatchDeletionTests: XCTestCase {
  private func client(key: String = "batch-delete-key") -> OpenRouterClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [BatchDeletionURLProtocol.self]
    return OpenRouterClient(apiKey: key, session: URLSession(configuration: configuration))
  }

  private func invoke(
    _ client: OpenRouterClient, alias: Bool, id: String = "batch_1",
    options: RequestOptions? = nil
  ) async throws -> BatchDeleteResponse {
    if alias { return try await client.batches.delete(id: id, options: options) }
    return try await client.deleteBatch(id: id, options: options)
  }

  func testProviderOutcomesThroughFlatAndAliasAPIs() async throws {
    for alias in [false, true] {
      for status in ["deleted", "unsupported", "not_applicable", "future_status", "omitted"] {
        let result = try await invoke(
          client(), alias: alias, options: RequestOptions(extraHeaders: ["X-Outcome": status]))
        XCTAssertEqual(result.id, "batch_1")
        XCTAssertEqual(result.object, "batch")
        XCTAssertEqual(result.deletion.openRouter, "deleted")
        if status == "omitted" {
          XCTAssertNil(result.deletion.upstream)
        } else {
          XCTAssertEqual(result.deletion.upstream?.provider, "OpenAI")
          // Unsupported and future statuses must not be flattened into overall success.
          XCTAssertEqual(result.deletion.upstream?.status, status)
        }
        let expected = try JSONDecoder().decode(
          JSONValue.self, from: BatchDeletionURLProtocol.body(outcome: status))
        XCTAssertEqual(result.rawPayload, expected)
      }
    }
  }

  func testReservedIDAndRequestOptions() async throws {
    for alias in [false, true] {
      var options = RequestOptions(extraHeaders: [
        "X-Custom": "preserved", "Accept": "application/custom+json",
        "X-Path": "/custom/batches/a%2Fb%3F%23%25%E9%9B%AA",
      ])
      options.baseURL = URL(string: "https://batch-delete.invalid/custom")!
      options.timeout = 17
      _ = try await invoke(client(), alias: alias, id: "a/b?#%雪", options: options)
    }
  }

  func testInvalidKnownBodiesFailDecoding() async throws {
    for alias in [false, true] {
      for invalid in ["type", "object", "openrouter"] {
        do {
          _ = try await invoke(
            client(), alias: alias,
            options: RequestOptions(extraHeaders: ["X-Invalid": invalid]))
          XCTFail("Expected decoding failure for \(invalid)")
        } catch let error as OpenRouterError {
          guard case .decodingFailed = error else { return XCTFail("Unexpected: \(error)") }
        }
      }
    }
  }

  func testAPIErrorsWithoutDefaultRetries() async throws {
    for alias in [false, true] {
      for status in [401, 404, 409, 429, 500, 502] {
        let token = UUID().uuidString
        let dispatch = expectation(description: "Single DELETE for \(status)")
        dispatch.assertForOverFulfill = true
        let observer = NotificationCenter.default.addObserver(
          forName: BatchDeletionURLProtocol.dispatched, object: nil, queue: nil
        ) { notification in
          if notification.userInfo?["token"] as? String == token { dispatch.fulfill() }
        }
        defer { NotificationCenter.default.removeObserver(observer) }
        do {
          _ = try await invoke(
            client(), alias: alias,
            options: RequestOptions(extraHeaders: ["X-Status": String(status), "X-Token": token]))
          XCTFail("Expected API error")
        } catch let error as OpenRouterError {
          guard case .apiError(let actual, let code, let message, let rawBody) = error else {
            return XCTFail("Unexpected: \(error)")
          }
          XCTAssertEqual(actual, status)
          XCTAssertEqual(code, status)
          XCTAssertEqual(message, "batch deletion failure")
          XCTAssertEqual(rawBody, BatchDeletionURLProtocol.errorBody(status: status))
        }
        await fulfillment(of: [dispatch], timeout: 1)
      }
    }
  }

  func testMissingKeyFailsBeforeDispatch() async throws {
    let dispatch = expectation(description: "No dispatch without API key")
    dispatch.isInverted = true
    let token = UUID().uuidString
    let observer = NotificationCenter.default.addObserver(
      forName: BatchDeletionURLProtocol.dispatched, object: nil, queue: nil
    ) { notification in
      if notification.userInfo?["token"] as? String == token { dispatch.fulfill() }
    }
    defer { NotificationCenter.default.removeObserver(observer) }
    for alias in [false, true] {
      do {
        _ = try await invoke(
          client(key: ""), alias: alias,
          options: RequestOptions(extraHeaders: ["X-Token": token]))
        XCTFail("Expected missing key")
      } catch let error as OpenRouterError {
        guard case .missingAPIKey = error else { return XCTFail("Unexpected: \(error)") }
      }
    }
    await fulfillment(of: [dispatch], timeout: 0.05)
  }
}

private final class BatchDeletionURLProtocol: URLProtocol {
  static let dispatched = Notification.Name("OpenRouterBatchDeletionTests.dispatched")

  static func body(outcome: String) throws -> Data {
    var deletion: [String: Any] = ["openrouter": "deleted", "extra_target": "retained"]
    if outcome != "omitted" {
      deletion["upstream"] = ["provider": "OpenAI", "status": outcome, "extra": 42]
    }
    return try JSONSerialization.data(withJSONObject: [
      "id": "batch_1", "object": "batch", "deletion": deletion, "extra_root": true,
    ])
  }

  static func errorBody(status: Int) -> String {
    "{\"error\":{\"code\":\(status),\"message\":\"batch deletion failure\"}}"
  }

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    NotificationCenter.default.post(
      name: Self.dispatched, object: nil,
      userInfo: ["token": request.value(forHTTPHeaderField: "X-Token") ?? ""])
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(request.httpMethod, "DELETE")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer batch-delete-key")
      XCTAssertNil(request.httpBody)
      XCTAssertNil(request.httpBodyStream)
      XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
      XCTAssertNil(components.query)
      XCTAssertNil(components.fragment)
      XCTAssertEqual(
        components.percentEncodedPath,
        request.value(forHTTPHeaderField: "X-Path") ?? "/api/v1/batches/batch_1")
      if request.value(forHTTPHeaderField: "X-Custom") != nil {
        XCTAssertEqual(url.host, "batch-delete.invalid")
        XCTAssertEqual(request.timeoutInterval, 17)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "preserved")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/custom+json")
      } else {
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
      }
      let status = Int(request.value(forHTTPHeaderField: "X-Status") ?? "200") ?? 200
      var data = try Self.body(outcome: request.value(forHTTPHeaderField: "X-Outcome") ?? "deleted")
      switch request.value(forHTTPHeaderField: "X-Invalid") {
      case "type":
        data = Data(#"{"id":1,"object":"batch","deletion":{"openrouter":"deleted"}}"#.utf8)
      case "object":
        data = Data(#"{"id":"batch_1","object":"file","deletion":{"openrouter":"deleted"}}"#.utf8)
      case "openrouter":
        data = Data(#"{"id":"batch_1","object":"batch","deletion":{"openrouter":"pending"}}"#.utf8)
      default: break
      }
      if status != 200 { data = Data(Self.errorBody(status: status).utf8) }
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: url, statusCode: status, httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]))
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
