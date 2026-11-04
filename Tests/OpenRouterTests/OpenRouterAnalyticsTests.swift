import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterAnalyticsTests: XCTestCase {
  private func client(key: String? = "analytics-key") -> OpenRouterClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [AnalyticsURLProtocol.self]
    let session = URLSession(configuration: configuration)
    if let key { return OpenRouterClient(apiKey: key, session: session) }
    return OpenRouterClient(session: session)
  }

  private func fixture(_ name: String) throws -> Data {
    try Data(contentsOf: XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json")))
  }

  private func call(
    alias: Bool, query: Bool, key: String? = "analytics-key", options: RequestOptions? = nil
  ) async throws {
    let client = client(key: key)
    if query {
      let request = AnalyticsQueryRequest(metrics: ["request_count"])
      let response =
        try await alias
        ? client.analytics.query(request, options: options)
        : client.queryAnalytics(request, options: options)
      XCTAssertEqual(response.data.data.first?["request_count"], .number(1500))
    } else {
      let response =
        try await alias
        ? client.analytics.getMeta(options: options)
        : client.getAnalyticsMeta(options: options)
      XCTAssertEqual(response.data.metrics.first?.name, "request_count")
    }
  }

  func testRoutesAliasesAndRequestOptions() async throws {
    for alias in [false, true] {
      for query in [false, true] {
        try await call(alias: alias, query: query)
        var options = RequestOptions(extraHeaders: ["X-Override": "true"])
        options.baseURL = URL(string: "https://analytics.invalid/custom")!
        options.timeout = 17
        try await call(alias: alias, query: query, options: options)
      }
    }
  }

  func testErrorsMissingKeyAndMalformedResponses() async throws {
    for alias in [false, true] {
      for query in [false, true] {
        for status in query ? [400, 401, 403, 408, 500] : [401, 403, 500] {
          var options = RequestOptions(extraHeaders: ["X-Status": String(status)])
          options.retries = RetryPolicy.none
          do {
            try await call(alias: alias, query: query, options: options)
            XCTFail("Expected API error")
          } catch let error as OpenRouterError {
            guard case .apiError(let actual, let code, let message, _) = error else {
              return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(actual, status)
            XCTAssertEqual(code, status)
            XCTAssertEqual(message, "analytics failure")
          }
        }
        do {
          try await call(alias: alias, query: query, key: nil)
          XCTFail("Expected missing key")
        } catch let error as OpenRouterError {
          guard case .missingAPIKey = error else { return XCTFail("Unexpected error: \(error)") }
        }
        do {
          try await call(
            alias: alias, query: query,
            options: RequestOptions(extraHeaders: ["X-Malformed": "true"]))
          XCTFail("Expected decoding error")
        } catch let error as OpenRouterError {
          guard case .decodingFailed = error else { return XCTFail("Unexpected error: \(error)") }
        }
      }
    }
  }

  func testRequestWireShapeAndOmission() async throws {
    let minimal = AnalyticsQueryRequest(metrics: ["request_count"])
    let encoder = JSONEncoder()
    XCTAssertEqual(
      try JSONDecoder().decode(JSONValue.self, from: encoder.encode(minimal)),
      .object(["metrics": .array([.string("request_count")])]))
    let request = AnalyticsQueryRequest(
      metrics: ["request_count"], dimensions: ["model"],
      filters: [
        .init(field: "model", operator: "eq", value: .string("openai/gpt-4o")),
        .init(
          field: "app", operator: "in", value: .array([.number(42), .string("43")]),
          includeUnset: false),
      ], granularity: "day", groupLimit: 0, limit: 100,
      orderBy: .init(field: "request_count", direction: "desc"),
      timeRange: .init(start: "2026-11-01T00:00:00.123Z", end: "2026-11-02T00:00:00Z"),
      classifierDimensions: .init(
        classifierID: "classifier-1", dimensionNames: ["department"], includeNulls: false),
      classifierFilters: .init(
        classifierID: "classifier-1",
        filters: [
          .init(field: "department", operator: "in", value: .array([.string("Engineering")]))
        ]))
    let bytes = try encoder.encode(request)
    XCTAssertEqual(try JSONDecoder().decode(AnalyticsQueryRequest.self, from: bytes), request)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
    XCTAssertEqual(
      Set(object.keys),
      Set([
        "metrics", "dimensions", "filters", "granularity", "group_limit", "limit", "order_by",
        "time_range", "classifier_dimensions", "classifier_filters",
      ]))
    XCTAssertEqual(object["group_limit"] as? Int, 0)
    let filters = try XCTUnwrap(object["filters"] as? [[String: Any]])
    XCTAssertEqual(filters[1]["include_unset"] as? Bool, false)
    XCTAssertEqual(filters[0]["operator"] as? String, "eq")
    let dimensions = try XCTUnwrap(object["classifier_dimensions"] as? [String: Any])
    XCTAssertEqual(dimensions["include_nulls"] as? Bool, false)
    XCTAssertEqual(dimensions["classifier_id"] as? String, "classifier-1")
    // Exercise transport with the same full payload, not just standalone encoding.
    _ = try await client().analytics.query(
      request,
      options: RequestOptions(extraHeaders: [
        "X-Expected-Body": bytes.base64EncodedString()
      ]))
  }

  func testFixturesDynamicRowsAndRequiredFields() throws {
    let decoder = JSONDecoder()
    let meta = try decoder.decode(AnalyticsMetaResponse.self, from: fixture("analytics-meta"))
    XCTAssertFalse(try XCTUnwrap(meta.data.metrics.first).isRate)
    XCTAssertEqual(meta.data.operators.first?.valueType, "scalar")
    let query = try decoder.decode(AnalyticsQueryResponse.self, from: fixture("analytics-query"))
    XCTAssertEqual(query.data.metadata, .init(queryTimeMS: 42, rowCount: 1, truncated: false))
    XCTAssertEqual(query.data.cachedAt, 1735689600.5)
    XCTAssertEqual(query.data.warnings, ["One filter value could not be resolved"])
    XCTAssertEqual(query.data.data.first?["optional_value"], .null)
    XCTAssertEqual(
      query.data.data.first?["future_column"],
      .object([
        "nested": .array([.bool(true), .number(3), .string("value")])
      ]))
    XCTAssertEqual(
      try decoder.decode(AnalyticsQueryResponse.self, from: JSONEncoder().encode(query)), query)
    let minimal = Data(
      #"{"data":{"data":[],"metadata":{"query_time_ms":0.5,"row_count":0,"truncated":true}}}"#.utf8)
    let result = try decoder.decode(AnalyticsQueryResponse.self, from: minimal)
    XCTAssertTrue(result.data.metadata.truncated)
    XCTAssertNil(result.data.cachedAt)
    XCTAssertNil(result.data.warnings)
    for json in [
      "{}", #"{"data":null}"#, #"{"data":{"data":[]}}"#,
      #"{"data":{"data":[3],"metadata":{"query_time_ms":0,"row_count":1,"truncated":false}}}"#,
      #"{"data":{"data":[],"metadata":{"query_time_ms":0,"row_count":1.5,"truncated":false}}}"#,
      #"{"data":{"data":[],"metadata":{"query_time_ms":0,"row_count":0,"truncated":null}}}"#,
    ] {
      XCTAssertThrowsError(try decoder.decode(AnalyticsQueryResponse.self, from: Data(json.utf8)))
    }
    for json in ["{}", #"{"data":{}}"#, #"{"data":{"metrics":[],"dimensions":[],"operators":[]}}"#]
    {
      XCTAssertThrowsError(try decoder.decode(AnalyticsMetaResponse.self, from: Data(json.utf8)))
    }
    XCTAssertThrowsError(try decoder.decode(AnalyticsQueryRequest.self, from: Data("{}".utf8)))
    let future = Data(
      #"{"name":"future","display_label":"Future","display_format":"future","is_rate":true}"#.utf8)
    XCTAssertEqual(try decoder.decode(AnalyticsMetric.self, from: future).displayFormat, "future")
  }
}

private final class AnalyticsURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      let query = url.path.hasSuffix("/query")
      let override = request.value(forHTTPHeaderField: "X-Override") != nil
      XCTAssertEqual(
        url.path, (override ? "/custom/" : "/api/v1/") + "analytics/" + (query ? "query" : "meta"))
      XCTAssertEqual(request.httpMethod, query ? "POST" : "GET")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer analytics-key")
      XCTAssertNil(url.query)
      if override {
        XCTAssertEqual(url.host, "analytics.invalid")
        XCTAssertEqual(request.timeoutInterval, 17)
      }
      if query {
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        var bytes = request.httpBody ?? Data()
        if let stream = request.httpBodyStream {
          stream.open()
          defer { stream.close() }
          var buffer = [UInt8](repeating: 0, count: 4096)
          while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            bytes.append(contentsOf: buffer.prefix(count))
          }
        }
        let expected =
          request.value(forHTTPHeaderField: "X-Expected-Body")
          .flatMap { Data(base64Encoded: $0) } ?? Data(#"{"metrics":["request_count"]}"#.utf8)
        XCTAssertEqual(
          try JSONDecoder().decode(JSONValue.self, from: bytes),
          try JSONDecoder().decode(JSONValue.self, from: expected))
      } else {
        XCTAssertNil(request.httpBody)
      }
      let status = Int(request.value(forHTTPHeaderField: "X-Status") ?? "200")!
      let bytes: Data
      if request.value(forHTTPHeaderField: "X-Malformed") != nil {
        bytes = Data("{}".utf8)
      } else if status == 200 {
        bytes = try Data(
          contentsOf: XCTUnwrap(
            Bundle.module.url(
              forResource: query ? "analytics-query" : "analytics-meta", withExtension: "json")))
      } else {
        bytes = try JSONSerialization.data(withJSONObject: [
          "error": ["code": status, "message": "analytics failure"]
        ])
      }
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: url, statusCode: status, httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]))
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: bytes)
      client?.urlProtocolDidFinishLoading(self)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }

  override func stopLoading() {}
}
