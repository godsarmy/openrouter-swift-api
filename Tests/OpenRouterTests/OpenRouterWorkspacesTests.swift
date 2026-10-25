import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterWorkspacesTests: XCTestCase {
  func testListPaginationAndAliases() async throws {
    let client = makeClient()
    for alias in [false, true] {
      for (offset, limit) in [(nil, nil), (0, nil), (nil, 25), (10, 25)] as [(Int?, Int?)] {
        let query = [offset.map { "offset=\($0)" }, limit.map { "limit=\($0)" }]
          .compactMap { $0 }.joined(separator: "&")
        let options = checkedOptions(path: "/api/v1/workspaces", query: query)
        let response =
          try await alias
          ? client.workspaces.list(offset: offset, limit: limit, options: options)
          : client.listWorkspaces(offset: offset, limit: limit, options: options)
        XCTAssertEqual(response.totalCount, 42)
        XCTAssertEqual(response.data.first?.slug, "production")
      }
    }
  }

  func testEmptyPageRetainsTotalCount() async throws {
    let response = try await makeClient().workspaces.list(
      offset: 100, options: checkedOptions(path: "/api/v1/workspaces", query: "offset=100"))
    XCTAssertTrue(response.data.isEmpty)
    XCTAssertEqual(response.totalCount, 42)
  }

  func testGetUUIDSlugAndEscapedSingleSegmentThroughBothAPIs() async throws {
    let client = makeClient()
    for alias in [false, true] {
      for (id, encoded) in [
        ("550e8400-e29b-41d4-a716-446655440000", "550e8400-e29b-41d4-a716-446655440000"),
        ("production", "production"),
        ("team/one?#%雪", "team%2Fone%3F%23%25%E9%9B%AA"),
      ] {
        let options = checkedOptions(path: "/api/v1/workspaces/" + encoded)
        let response =
          try await alias
          ? client.workspaces.get(id: id, options: options)
          : client.getWorkspace(id: id, options: options)
        XCTAssertEqual(response.data.name, "Production")
      }
    }
  }

  func testRequestOptionsOverrideBaseURLTimeoutAndHeaders() async throws {
    var options = checkedOptions(path: "/custom/workspaces")
    options.baseURL = URL(string: "https://workspaces.invalid/custom")!
    options.timeout = 17
    options.extraHeaders["X-Workspace-Option"] = "custom"
    _ = try await makeClient().listWorkspaces(options: options)
    options.extraHeaders["X-Expected-Path"] = "/custom/workspaces/production"
    _ = try await makeClient().workspaces.get(id: "production", options: options)
  }

  func testAPIErrorsForListAndGet() async throws {
    for status in [401, 403, 404, 500] {
      for alias in [false, true] {
        var options = checkedOptions(
          path: alias ? "/api/v1/workspaces/missing" : "/api/v1/workspaces")
        options.extraHeaders["X-Test-Status"] = String(status)
        options.retries = RetryPolicy.none
        do {
          if alias {
            _ = try await makeClient().workspaces.get(id: "missing", options: options)
          } else {
            _ = try await makeClient().listWorkspaces(options: options)
          }
          XCTFail("Expected API error \(status)")
        } catch let error as OpenRouterError {
          guard case .apiError(let actual, let code, let message, _) = error else {
            return XCTFail("Unexpected error: \(error)")
          }
          XCTAssertEqual(actual, status)
          XCTAssertEqual(code, status)
          XCTAssertEqual(message, "workspace failure")
        }
      }
    }
  }

  func testMissingAPIKeyFailsBeforeDispatch() async throws {
    let client = makeClient(apiKey: nil)
    for method in 0..<4 {
      do {
        switch method {
        case 0: _ = try await client.listWorkspaces()
        case 1: _ = try await client.workspaces.list()
        case 2: _ = try await client.getWorkspace(id: "production")
        default: _ = try await client.workspaces.get(id: "production")
        }
        XCTFail("Expected missingAPIKey")
      } catch let error as OpenRouterError {
        guard case .missingAPIKey = error else {
          return XCTFail("Unexpected error: \(error)")
        }
      }
    }
  }

  func testFullModelRoundTripsSnakeCaseAndUnknownProviderSort() throws {
    let source = workspaceTestObject
    let workspace = try decode(source)
    XCTAssertEqual(workspace.defaultProviderSort, "future-sort")
    XCTAssertEqual(workspace.ioLoggingAPIKeyIDs, [12, 34])
    XCTAssertEqual(workspace.ioLoggingSamplingRate, 0.25)
    XCTAssertEqual(workspace.disabledServerTools, ["openrouter:web_search"])
    XCTAssertEqual(workspace.includeBYOKInBudgets, true)
    let encoded =
      try JSONSerialization.jsonObject(with: JSONEncoder().encode(workspace)) as? NSDictionary
    XCTAssertEqual(encoded, source as NSDictionary)
  }

  func testNullableFieldsAndAbsentOptionalFields() throws {
    var source = workspaceTestObject
    for key in [
      "description", "default_text_model", "default_image_model", "default_provider_sort",
      "io_logging_api_key_ids", "updated_at", "created_by",
    ] {
      source[key] = NSNull()
    }
    source.removeValue(forKey: "disabled_server_tools")
    source.removeValue(forKey: "include_byok_in_budgets")
    let workspace = try decode(source)
    XCTAssertNil(workspace.description)
    XCTAssertNil(workspace.defaultTextModel)
    XCTAssertNil(workspace.defaultImageModel)
    XCTAssertNil(workspace.defaultProviderSort)
    XCTAssertNil(workspace.ioLoggingAPIKeyIDs)
    XCTAssertNil(workspace.updatedAt)
    XCTAssertNil(workspace.createdBy)
    XCTAssertNil(workspace.disabledServerTools)
    XCTAssertNil(workspace.includeBYOKInBudgets)
  }

  func testRequiredBooleansAndInvalidTypesAreNotSilentlyDefaulted() throws {
    for key in [
      "is_observability_io_logging_enabled", "is_observability_broadcast_enabled",
      "is_data_discount_logging_enabled",
    ] {
      var source = workspaceTestObject
      source.removeValue(forKey: key)
      XCTAssertThrowsError(try decode(source), key)
      source[key] = NSNull()
      XCTAssertThrowsError(try decode(source), key)
      source[key] = "false"
      XCTAssertThrowsError(try decode(source), key)
    }
    for (key, value) in [
      ("io_logging_sampling_rate", "quarter" as Any),
      ("io_logging_api_key_ids", ["12"] as Any), ("id", 12 as Any),
    ] {
      var source = workspaceTestObject
      source[key] = value
      XCTAssertThrowsError(try decode(source), key)
    }
  }

  private func decode(_ object: [String: Any]) throws -> Workspace {
    try JSONDecoder().decode(Workspace.self, from: JSONSerialization.data(withJSONObject: object))
  }

  private func makeClient(apiKey: String? = "workspace-key") -> OpenRouterClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [WorkspaceOfflineURLProtocol.self]
    let session = URLSession(configuration: configuration)
    if let apiKey { return OpenRouterClient(apiKey: apiKey, session: session) }
    return OpenRouterClient(session: session)
  }

  private func checkedOptions(path: String, query: String = "") -> RequestOptions {
    RequestOptions(extraHeaders: ["X-Expected-Path": path, "X-Expected-Query": query])
  }
}

private var workspaceTestObject: [String: Any] {
  [
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "default_guardrail_id": "595d5849-7e86-51fd-a7c0-705c34e4afff",
    "name": "Production", "slug": "production", "description": "Production workspace",
    "default_text_model": "openai/gpt-4o", "default_image_model": "openai/dall-e-3",
    "default_provider_sort": "future-sort", "is_observability_io_logging_enabled": true,
    "is_observability_broadcast_enabled": false, "is_data_discount_logging_enabled": true,
    "io_logging_sampling_rate": 0.25, "io_logging_api_key_ids": [12, 34],
    "created_at": "2025-08-24T10:30:00Z", "updated_at": "2025-08-24T15:45:00Z",
    "created_by": "user_abc123", "disabled_server_tools": ["openrouter:web_search"],
    "include_byok_in_budgets": true,
  ]
}

private final class WorkspaceOfflineURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer workspace-key")
      XCTAssertEqual(
        components.percentEncodedPath, request.value(forHTTPHeaderField: "X-Expected-Path"))
      let actualQuery = (components.queryItems ?? []).map { "\($0.name)=\($0.value ?? "")" }
        .sorted()
      let expectedQuery = (request.value(forHTTPHeaderField: "X-Expected-Query") ?? "")
        .split(separator: "&").map(String.init).sorted()
      XCTAssertEqual(actualQuery, expectedQuery)
      XCTAssertNil(components.fragment)
      if request.value(forHTTPHeaderField: "X-Workspace-Option") != nil {
        XCTAssertEqual(url.host, "workspaces.invalid")
        XCTAssertEqual(request.timeoutInterval, 17)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Workspace-Option"), "custom")
      }
      let status = Int(request.value(forHTTPHeaderField: "X-Test-Status") ?? "200") ?? 200
      let object: [String: Any]
      if status != 200 {
        object = ["error": ["code": status, "message": "workspace failure"]]
      } else if components.path.hasSuffix("/workspaces") {
        let empty =
          components.queryItems?.contains(URLQueryItem(name: "offset", value: "100")) == true
        object = ["data": empty ? [] : [workspaceTestObject], "total_count": 42]
      } else {
        object = ["data": workspaceTestObject]
      }
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: url, statusCode: status, httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]))
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: try JSONSerialization.data(withJSONObject: object))
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
