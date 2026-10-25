import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterFileDeletionTests: XCTestCase {
  private func client(key: String = "delete-key") -> OpenRouterClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [FileDeletionURLProtocol.self]
    return OpenRouterClient(apiKey: key, session: URLSession(configuration: configuration))
  }

  private func options(
    shape: String = "openrouter", query: [String: String] = [:],
    path: String = "/api/v1/files/file_1"
  ) throws -> RequestOptions {
    RequestOptions(extraHeaders: [
      "X-Shape": shape, "X-Path": path,
      "X-Query": try JSONSerialization.data(withJSONObject: query).base64EncodedString(),
    ])
  }

  private func invoke(
    _ client: OpenRouterClient, alias: Bool, id: String = "file_1",
    workspace: UUID? = nil, provider: String? = nil, options: RequestOptions? = nil
  ) async throws -> FileDeleteResponse {
    if alias {
      return try await client.files.delete(
        id: id, workspaceID: workspace, provider: provider, options: options)
    }
    return try await client.deleteFile(
      id: id, workspaceID: workspace, provider: provider, options: options)
  }

  func testShapesThroughFlatAndAliasAPIs() async throws {
    for alias in [false, true] {
      for shape in ["openrouter", "anthropic", "openai", "legacy", "future"] {
        let result = try await invoke(client(), alias: alias, options: options(shape: shape))
        XCTAssertEqual(result.isConfirmed, shape != "future")
        if shape != "future" { XCTAssertEqual(result.id, "file_1") }
        switch (shape, result) {
        case ("openrouter", .openRouter), ("legacy", .openRouter),
          ("anthropic", .anthropic), ("openai", .openAI), ("future", .unknown):
          break
        default: XCTFail("Unexpected response: \(result)")
        }
      }
    }
  }

  func testScopeEscapingAndRequestOptions() async throws {
    let workspace = UUID()
    let provider = "future+/#?=&雪"
    for alias in [false, true] {
      for scope in 0..<4 {
        let query = (scope & 1 != 0 ? ["workspace_id": workspace.uuidString] : [:])
          .merging(scope & 2 != 0 ? ["provider": provider] : [:]) { _, new in new }
        var opt = try options(
          query: query, path: "/custom/files/a%2Fb%3F%23%25%E9%9B%AA")
        opt.baseURL = URL(string: "https://delete.invalid/custom")!
        opt.timeout = 17
        opt.extraHeaders["X-Options"] = "override"
        opt.extraHeaders["Accept"] = "application/custom+json"
        _ = try await invoke(
          client(), alias: alias, id: "a/b?#%雪",
          workspace: scope & 1 != 0 ? workspace : nil,
          provider: scope & 2 != 0 ? provider : nil, options: opt)
      }
    }
  }

  func testInvalidKnownResponsesFailDecoding() async throws {
    for alias in [false, true] {
      for shape in ["invalid-native", "invalid-openai"] {
        do {
          _ = try await invoke(client(), alias: alias, options: options(shape: shape))
          XCTFail("Expected decoding failure")
        } catch let error as OpenRouterError {
          guard case .decodingFailed = error else { return XCTFail("Unexpected: \(error)") }
        }
      }
    }
  }

  func testAPIErrorsAndMissingKeyBeforeDispatch() async throws {
    for alias in [false, true] {
      for status in [400, 401, 403, 404, 429, 500] {
        var opt = try options()
        opt.retries = RetryPolicy.none
        opt.extraHeaders["X-Status"] = String(status)
        do {
          _ = try await invoke(client(), alias: alias, options: opt)
          XCTFail("Expected API failure")
        } catch let error as OpenRouterError {
          guard case .apiError(let actual, let code, let message, _) = error else {
            return XCTFail("Unexpected: \(error)")
          }
          XCTAssertEqual(actual, status)
          XCTAssertEqual(code, status)
          XCTAssertEqual(message, "deletion failure")
        }
      }
      do {
        _ = try await invoke(client(key: ""), alias: alias)
        XCTFail("Expected missing key")
      } catch let error as OpenRouterError {
        guard case .missingAPIKey = error else { return XCTFail("Unexpected: \(error)") }
      }
    }
  }
}

private final class FileDeletionURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(request.httpMethod, "DELETE")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer delete-key")
      XCTAssertNil(request.httpBody)
      XCTAssertNil(request.httpBodyStream)
      XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
      XCTAssertEqual(components.percentEncodedPath, request.value(forHTTPHeaderField: "X-Path"))
      XCTAssertNil(components.fragment)
      let expected = try JSONDecoder().decode(
        [String: String].self,
        from: XCTUnwrap(Data(base64Encoded: request.value(forHTTPHeaderField: "X-Query") ?? "")))
      XCTAssertEqual(components.queryItems?.count ?? 0, expected.count)
      for item in components.queryItems ?? [] { XCTAssertEqual(item.value, expected[item.name]) }
      if request.value(forHTTPHeaderField: "X-Options") != nil {
        XCTAssertEqual(url.host, "delete.invalid")
        XCTAssertEqual(request.timeoutInterval, 17)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Options"), "override")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/custom+json")
      }
      let status = Int(request.value(forHTTPHeaderField: "X-Status") ?? "200") ?? 200
      let shape = request.value(forHTTPHeaderField: "X-Shape") ?? "openrouter"
      let fixture: String
      switch shape {
      case "legacy": fixture = #"{"id":"file_1","type":"file_deleted"}"#
      case "openai":
        fixture = #"{"_shape":"openai","id":"file_1","object":"file","deleted":true}"#
      case "invalid-native": fixture = #"{"_shape":"openrouter","id":"file_1","type":"file"}"#
      case "invalid-openai":
        fixture = #"{"_shape":"openai","id":"file_1","object":"file","deleted":false}"#
      case "future": fixture = #"{"_shape":"future","result":"unconfirmed"}"#
      default: fixture = "{\"_shape\":\"\(shape)\",\"id\":\"file_1\",\"type\":\"file_deleted\"}"
      }
      let body =
        status == 200
        ? Data(fixture.utf8)
        : try JSONSerialization.data(withJSONObject: [
          "error": ["code": status, "message": "deletion failure"]
        ])
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: url, statusCode: status, httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]))
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: body)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
