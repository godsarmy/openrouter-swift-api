import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterOrganizationTests: XCTestCase {
  func testPaginationThroughBothSurfaces() async throws {
    for alias in [false, true] {
      for (offset, limit) in [(nil, nil), (0, nil), (nil, 100), (10, 25)] as [(Int?, Int?)] {
        let query = [offset.map { "offset=\($0)" }, limit.map { "limit=\($0)" }]
          .compactMap { $0 }.joined(separator: "&")
        let options = checkedOptions(query: query)
        let response =
          try await alias
          ? makeClient().organization.listMembers(offset: offset, limit: limit, options: options)
          : makeClient().listOrganizationMembers(offset: offset, limit: limit, options: options)
        XCTAssertEqual(response.totalCount, 42)
        XCTAssertEqual(response.data.first?.firstName, "Ada")
        XCTAssertEqual(response.data.first?.role, "org:admin")
        XCTAssertNil(response.data.last?.firstName)
        XCTAssertNil(response.data.last?.lastName)
        XCTAssertEqual(response.data.last?.role, "org:member")
      }
    }
  }

  func testEmptyPageRetainsCount() async throws {
    let response = try await makeClient().organization.listMembers(
      offset: 100, options: checkedOptions(query: "offset=100"))
    XCTAssertTrue(response.data.isEmpty)
    XCTAssertEqual(response.totalCount, 42)
  }

  func testPerRequestOverridesThroughBothSurfaces() async throws {
    for alias in [false, true] {
      var options = checkedOptions()
      options.baseURL = URL(string: "https://organization.invalid/custom")!
      options.timeout = 17
      options.extraHeaders["X-Expected-Path"] = "/custom/organization/members"
      options.extraHeaders["X-Custom"] = "override"
      _ =
        try await alias
        ? makeClient().organization.listMembers(options: options)
        : makeClient().listOrganizationMembers(options: options)
    }
  }

  func testErrorsAndMissingKeyThroughBothSurfaces() async throws {
    for alias in [false, true] {
      for status in [401, 403, 500] {
        var options = checkedOptions()
        options.retries = RetryPolicy.none
        options.extraHeaders["X-Test-Status"] = String(status)
        do {
          _ =
            try await alias
            ? makeClient().organization.listMembers(options: options)
            : makeClient().listOrganizationMembers(options: options)
          XCTFail("Expected API error")
        } catch let error as OpenRouterError {
          guard case .apiError(let actual, let code, let message, _) = error else {
            return XCTFail("Unexpected error: \(error)")
          }
          XCTAssertEqual(actual, status)
          XCTAssertEqual(code, status)
          XCTAssertEqual(message, "organization failure")
        }
      }
      do {
        _ =
          try await alias
          ? makeClient(apiKey: nil).organization.listMembers()
          : makeClient(apiKey: nil).listOrganizationMembers()
        XCTFail("Expected missing key")
      } catch let error as OpenRouterError {
        guard case .missingAPIKey = error else { return XCTFail("Unexpected error: \(error)") }
      }
    }
  }

  func testModelsCodingKeysOptionalNamesAndOpenRole() throws {
    let member = OrganizationMember(
      id: "user_1", firstName: "Ada", lastName: "Lovelace", email: "ada@example.invalid",
      role: "future:role")
    let response = OrganizationMembersResponse(data: [member], totalCount: 7)
    let data = try JSONEncoder().encode(response)
    XCTAssertEqual(try JSONDecoder().decode(OrganizationMembersResponse.self, from: data), response)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    XCTAssertEqual(object["total_count"] as? Int, 7)
    let members = try XCTUnwrap(object["data"] as? [[String: Any]])
    XCTAssertEqual(members.first?["first_name"] as? String, "Ada")
    XCTAssertEqual(members.first?["last_name"] as? String, "Lovelace")
    // Match existing optional-field decoding: missing and null names both become nil.
    let missingNames = Data(
      #"{"id":"user_2","email":"user@example.invalid","role":"org:member"}"#.utf8)
    let decoded = try JSONDecoder().decode(OrganizationMember.self, from: missingNames)
    XCTAssertNil(decoded.firstName)
    XCTAssertNil(decoded.lastName)
    for invalid in [
      #"{"id":"user","email":"e","role":1}"#,
      #"{"id":"user","email":"e"}"#,
      #"{"id":"user","email":"e","role":"org:member","first_name":1}"#,
    ] {
      XCTAssertThrowsError(
        try JSONDecoder().decode(OrganizationMember.self, from: Data(invalid.utf8)))
    }
  }

  private func checkedOptions(query: String = "") -> RequestOptions {
    RequestOptions(extraHeaders: [
      "X-Expected-Path": "/api/v1/organization/members", "X-Expected-Query": query,
    ])
  }

  private func makeClient(apiKey: String? = "organization-key") -> OpenRouterClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [OrganizationOfflineURLProtocol.self]
    let session = URLSession(configuration: configuration)
    if let apiKey { return OpenRouterClient(apiKey: apiKey, session: session) }
    return OpenRouterClient(session: session)
  }
}

private final class OrganizationOfflineURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertNil(request.httpBody)
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer organization-key")
      XCTAssertEqual(
        components.percentEncodedPath, request.value(forHTTPHeaderField: "X-Expected-Path"))
      let actualQuery = (components.queryItems ?? []).map { "\($0.name)=\($0.value ?? "")" }
        .sorted()
      let expectedQuery = (request.value(forHTTPHeaderField: "X-Expected-Query") ?? "").split(
        separator: "&"
      ).map(String.init).sorted()
      XCTAssertEqual(actualQuery, expectedQuery)
      if request.value(forHTTPHeaderField: "X-Custom") != nil {
        XCTAssertEqual(url.host, "organization.invalid")
        XCTAssertEqual(request.timeoutInterval, 17)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "override")
      }
      let status = Int(request.value(forHTTPHeaderField: "X-Test-Status") ?? "200") ?? 200
      let empty =
        components.queryItems?.contains(URLQueryItem(name: "offset", value: "100")) == true
      let members: [[String: Any]] = [
        [
          "id": "user_1", "first_name": "Ada", "last_name": "Lovelace",
          "email": "ada@example.invalid", "role": "org:admin",
        ],
        [
          "id": "user_2", "first_name": NSNull(), "last_name": NSNull(),
          "email": "user@example.invalid", "role": "org:member",
        ],
      ]
      let object: [String: Any] =
        status == 200
        ? ["data": empty ? [] : members, "total_count": 42]
        : ["error": ["code": status, "message": "organization failure"]]
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
