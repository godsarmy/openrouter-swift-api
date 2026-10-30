import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterWorkspaceMembersTests: XCTestCase {
  func testPaginationThroughBothSurfaces() async throws {
    for alias in [false, true] {
      for (offset, limit) in [(nil, nil), (0, nil), (nil, 100), (10, 25)] as [(Int?, Int?)] {
        let query = [offset.map { "offset=\($0)" }, limit.map { "limit=\($0)" }]
          .compactMap { $0 }.joined(separator: "&")
        let options = checkedOptions(query: query)
        let response =
          try await alias
          ? makeClient().workspaces.listMembers(
            id: "production", offset: offset, limit: limit, options: options)
          : makeClient().listWorkspaceMembers(
            id: "production", offset: offset, limit: limit, options: options)
        XCTAssertEqual(response.totalCount, 42)
        XCTAssertEqual(response.data.first?.userID, "user_1")
        XCTAssertEqual(response.data.first?.workspaceID, "workspace_1")
        XCTAssertEqual(response.data.first?.role, "admin")
        XCTAssertEqual(response.data.last?.role, "future:role")
      }
    }
  }

  func testEmptyPageRetainsCount() async throws {
    let response = try await makeClient().workspaces.listMembers(
      id: "production",
      offset: 100, options: checkedOptions(query: "offset=100"))
    XCTAssertTrue(response.data.isEmpty)
    XCTAssertEqual(response.totalCount, 42)
  }

  func testPerRequestOverridesThroughBothSurfaces() async throws {
    for alias in [false, true] {
      var options = checkedOptions()
      options.baseURL = URL(string: "https://workspace.invalid/custom")!
      options.timeout = 17
      options.extraHeaders["X-Expected-Path"] = "/custom/workspaces/production/members"
      options.extraHeaders["X-Custom"] = "override"
      _ =
        try await alias
        ? makeClient().workspaces.listMembers(id: "production", options: options)
        : makeClient().listWorkspaceMembers(id: "production", options: options)
    }
  }

  func testErrorsAndMissingKeyThroughBothSurfaces() async throws {
    for alias in [false, true] {
      for status in [401, 403, 404, 500] {
        var options = checkedOptions()
        options.retries = RetryPolicy.none
        options.extraHeaders["X-Test-Status"] = String(status)
        do {
          _ =
            try await alias
            ? makeClient().workspaces.listMembers(id: "production", options: options)
            : makeClient().listWorkspaceMembers(id: "production", options: options)
          XCTFail("Expected API error")
        } catch let error as OpenRouterError {
          guard case .apiError(let actual, let code, let message, _) = error else {
            return XCTFail("Unexpected error: \(error)")
          }
          XCTAssertEqual(actual, status)
          XCTAssertEqual(code, status)
          XCTAssertEqual(message, "workspace failure")
        }
      }
      do {
        _ =
          try await alias
          ? makeClient(apiKey: nil).workspaces.listMembers(id: "production")
          : makeClient(apiKey: nil).listWorkspaceMembers(id: "production")
        XCTFail("Expected missing key")
      } catch let error as OpenRouterError {
        guard case .missingAPIKey = error else { return XCTFail("Unexpected error: \(error)") }
      }
    }
  }

  func testEncodedWorkspaceIDThroughBothSurfaces() async throws {
    for alias in [false, true] {
      var options = checkedOptions()
      options.extraHeaders["X-Expected-Path"] =
        "/api/v1/workspaces/team%2Fblue%20%3F%23%25/members"
      if alias {
        _ = try await makeClient().workspaces.listMembers(id: "team/blue ?#%", options: options)
      } else {
        _ = try await makeClient().listWorkspaceMembers(id: "team/blue ?#%", options: options)
      }
    }
  }

  func testModelsCodingKeysAndOpenRole() throws {
    let member = WorkspaceMembership(
      id: "membership_1", workspaceID: "workspace_1", userID: "user_1",
      role: "future:role", createdAt: "2026-10-29T10:00:00Z")
    let response = WorkspaceMembersResponse(data: [member], totalCount: 7)
    let data = try JSONEncoder().encode(response)
    XCTAssertEqual(try JSONDecoder().decode(WorkspaceMembersResponse.self, from: data), response)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    XCTAssertEqual(object["total_count"] as? Int, 7)
    let members = try XCTUnwrap(object["data"] as? [[String: Any]])
    XCTAssertEqual(members.first?["workspace_id"] as? String, "workspace_1")
    XCTAssertEqual(members.first?["user_id"] as? String, "user_1")
    XCTAssertEqual(members.first?["created_at"] as? String, member.createdAt)
    for invalid in [
      #"{"data":[]}"#, #"{"data":[],"total_count":"7"}"#,
      #"{"data":[{"id":"member"}],"total_count":1}"#,
    ] {
      XCTAssertThrowsError(
        try JSONDecoder().decode(WorkspaceMembersResponse.self, from: Data(invalid.utf8)))
    }
  }

  private func checkedOptions(query: String = "") -> RequestOptions {
    RequestOptions(extraHeaders: [
      "X-Expected-Path": "/api/v1/workspaces/production/members", "X-Expected-Query": query,
    ])
  }

  private func makeClient(apiKey: String? = "workspace-key") -> OpenRouterClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [WorkspaceMembersOfflineURLProtocol.self]
    let session = URLSession(configuration: configuration)
    if let apiKey { return OpenRouterClient(apiKey: apiKey, session: session) }
    return OpenRouterClient(session: session)
  }
}

private final class WorkspaceMembersOfflineURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertNil(request.httpBody)
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer workspace-key")
      XCTAssertEqual(
        components.percentEncodedPath, request.value(forHTTPHeaderField: "X-Expected-Path"))
      let actualQuery = (components.queryItems ?? []).map { "\($0.name)=\($0.value ?? "")" }
        .sorted()
      let expectedQuery = (request.value(forHTTPHeaderField: "X-Expected-Query") ?? "").split(
        separator: "&"
      ).map(String.init).sorted()
      XCTAssertEqual(actualQuery, expectedQuery)
      if request.value(forHTTPHeaderField: "X-Custom") != nil {
        XCTAssertEqual(url.host, "workspace.invalid")
        XCTAssertEqual(request.timeoutInterval, 17)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "override")
      }
      let status = Int(request.value(forHTTPHeaderField: "X-Test-Status") ?? "200") ?? 200
      let empty =
        components.queryItems?.contains(URLQueryItem(name: "offset", value: "100")) == true
      let members: [[String: Any]] = [
        [
          "id": "membership_1", "workspace_id": "workspace_1", "user_id": "user_1",
          "role": "admin", "created_at": "2026-10-29T10:00:00Z",
        ],
        [
          "id": "membership_2", "workspace_id": "workspace_1", "user_id": "user_2",
          "role": "future:role", "created_at": "2026-10-29T10:00:00Z",
        ],
      ]
      let object: [String: Any] =
        status == 200
        ? ["data": empty ? [] : members, "total_count": 42]
        : ["error": ["code": status, "message": "workspace failure"]]
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
