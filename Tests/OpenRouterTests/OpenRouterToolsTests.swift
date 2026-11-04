import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterToolsTests: XCTestCase {
  private func makeClient(key: String? = "tools-key") -> OpenRouterClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [ToolsURLProtocol.self]
    let session = URLSession(configuration: config)
    if let key { return OpenRouterClient(apiKey: key, session: session) }
    return OpenRouterClient(session: session)
  }

  func testMethodsAliasesFiltersAndOptions() async throws {
    for alias in [false, true] {
      let client = makeClient()
      let all = try await alias ? client.tools.list() : client.listTools()
      XCTAssertEqual(all.totalCount, 1)
      XCTAssertNil(all.links.next)
      XCTAssertEqual(all.data[0].engines[0].pricing[0].price, "0.000000123456789")
      let options = RequestOptions(
        timeout: 17, baseURL: URL(string: "https://tools.invalid/custom")!,
        extraHeaders: ["X-Test-Filter": "true"])
      let page =
        try await alias
        ? client.tools.list(offset: 0, limit: 2, apiFormat: "future format", options: options)
        : client.listTools(offset: 0, limit: 2, apiFormat: "future format", options: options)
      XCTAssertEqual(page, all)
      for name in ["openrouter:web_search", "web_search", "a/b ?#%é"] {
        let details =
          try await alias
          ? client.tools.get(name: name) : client.getTool(name: name)
        XCTAssertEqual(details.data.nativeSupport.models[0].slug, "provider/model")
      }
    }
  }

  func testErrorsAndAuthentication() async throws {
    for alias in [false, true] {
      for get in [false, true] {
        for status in [401, 403, 404, 500] {
          var options = RequestOptions(extraHeaders: ["X-Test-Status": String(status)])
          options.retries = RetryPolicy.none
          do {
            let client = makeClient()
            if get {
              _ =
                try await alias
                ? client.tools.get(name: "missing", options: options)
                : client.getTool(name: "missing", options: options)
            } else {
              _ =
                try await alias
                ? client.tools.list(options: options) : client.listTools(options: options)
            }
            XCTFail("Expected API error")
          } catch let error as OpenRouterError {
            guard case .apiError(let actual, let code, let message, _) = error else {
              return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(actual, status)
            XCTAssertEqual(code, status)
            XCTAssertEqual(message, "catalog failure")
          }
        }
        do {
          let client = makeClient(key: nil)
          if get {
            _ = try await client.tools.get(name: "openrouter:web_search")
          } else {
            _ = try await client.tools.list()
          }
          XCTFail("Expected missing key")
        } catch let error as OpenRouterError {
          XCTAssertEqual(error, .missingAPIKey)
        }
      }
    }
    for name in ["", ".", ".."] {
      do {
        _ = try await makeClient().getTool(name: name)
        XCTFail("Expected invalid URL")
      } catch let error as OpenRouterError {
        guard case .invalidURL = error else { return XCTFail("Unexpected error: \(error)") }
      }
    }
  }

  func testMalformedResponsesMapToDecodingFailure() async throws {
    for detail in [false, true] {
      do {
        let options = RequestOptions(extraHeaders: ["X-Malformed": "true"])
        if detail {
          _ = try await makeClient().tools.get(name: "openrouter:web_search", options: options)
        } else {
          _ = try await makeClient().tools.list(options: options)
        }
        XCTFail("Expected decoding failure")
      } catch let error as OpenRouterError {
        guard case .decodingFailed = error else { return XCTFail("Unexpected error: \(error)") }
      }
    }
  }

  func testRequiredFieldsNullabilityAndRoundTrip() throws {
    for (fixture, detail) in [("server-tools-list", false), ("server-tools-get", true)] {
      let data = try Data(
        contentsOf: XCTUnwrap(Bundle.module.url(forResource: fixture, withExtension: "json")))
      if detail {
        let value = try JSONDecoder().decode(GetToolResponse.self, from: data)
        XCTAssertEqual(
          try JSONDecoder().decode(GetToolResponse.self, from: JSONEncoder().encode(value)), value)
      } else {
        let value = try JSONDecoder().decode(ListToolsResponse.self, from: data)
        XCTAssertEqual(
          try JSONDecoder().decode(ListToolsResponse.self, from: JSONEncoder().encode(value)), value
        )
      }
      let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
      let tool = try XCTUnwrap(
        detail ? envelope["data"] as? [String: Any] : (envelope["data"] as? [[String: Any]])?.first)
      for key in tool.keys {
        var invalid = tool
        invalid.removeValue(forKey: key)
        let bytes = try JSONSerialization.data(withJSONObject: invalid)
        if detail {
          XCTAssertThrowsError(try JSONDecoder().decode(ServerToolDetails.self, from: bytes), key)
        } else {
          XCTAssertThrowsError(try JSONDecoder().decode(ServerTool.self, from: bytes), key)
        }
      }
    }
    XCTAssertThrowsError(
      try JSONDecoder().decode(ServerToolPaginationLinks.self, from: Data("{}".utf8)))
    XCTAssertThrowsError(
      try JSONDecoder().decode(
        ListToolsResponse.self,
        from: Data(#"{"data":[],"total_count":1.5,"links":{"next":null}}"#.utf8)))
  }
}

private final class ToolsURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tools-key")
      XCTAssertNil(request.httpBody)
      let filtered = request.value(forHTTPHeaderField: "X-Test-Filter") != nil
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      let detail = url.path.contains("/tools/")
      if filtered {
        XCTAssertEqual(url.host, "tools.invalid")
        XCTAssertEqual(url.path, "/custom/tools")
        XCTAssertEqual(request.timeoutInterval, 17)
        XCTAssertEqual(
          components.queryItems,
          [
            URLQueryItem(name: "offset", value: "0"), URLQueryItem(name: "limit", value: "2"),
            URLQueryItem(name: "api_format", value: "future format"),
          ])
      } else {
        XCTAssertNil(url.query)
        XCTAssertTrue(components.percentEncodedPath.hasPrefix("/api/v1/tools"))
        if detail {
          let segment = String(components.percentEncodedPath.dropFirst("/api/v1/tools/".count))
          XCTAssertFalse(segment.contains("/"))
          XCTAssertTrue(
            ["openrouter:web_search", "web_search", "a/b ?#%é", "missing"].contains(
              segment.removingPercentEncoding ?? ""))
        } else {
          XCTAssertEqual(url.path, "/api/v1/tools")
        }
      }
      let status = Int(request.value(forHTTPHeaderField: "X-Test-Status") ?? "200")!
      let data: Data
      if request.value(forHTTPHeaderField: "X-Malformed") != nil {
        data = Data("{}".utf8)
      } else if status == 200 {
        data = try Data(
          contentsOf: XCTUnwrap(
            Bundle.module.url(
              forResource: detail ? "server-tools-get" : "server-tools-list", withExtension: "json")
          ))
      } else {
        data = try JSONSerialization.data(withJSONObject: [
          "error": ["code": status, "message": "catalog failure"]
        ])
      }
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: url, statusCode: status, httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]))
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }
  override func stopLoading() {}
}
