import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterBatchesTests: XCTestCase {
  private func client(key: String = "batch-key") -> OpenRouterClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [BatchURLProtocol.self]
    return OpenRouterClient(apiKey: key, session: URLSession(configuration: configuration))
  }

  private var submission: CreateBatchRequest {
    CreateBatchRequest(
      endpoint: "/v1/chat/completions", model: "provider/model",
      requests: [.init(customID: "one", body: ["messages": .array([])])],
      completionWindow: "24h", provider: .init(only: ["provider"], allowFallbacks: false),
      callbackURL: "https://callback.invalid/hook")
  }

  func testCreate202ThroughBothAPIsWithDefaultOptions() async throws {
    for alias in [false, true] {
      let batch =
        try await alias
        ? client().batches.create(submission) : client().createBatch(submission)
      XCTAssertEqual(batch.id, "batch_1")
      XCTAssertEqual(batch.status, "validating")
      XCTAssertEqual(batch.requestCounts.total, 1)
      XCTAssertEqual(batch.requestCounts.completed, 0)
      XCTAssertNil(batch.results)
    }
  }

  func testListFiltersAreRepeatedAndPreserveExactStrings() async throws {
    for alias in [false, true] {
      for filtered in [false, true] {
        let options = RequestOptions(extraHeaders: ["X-Filtered": filtered ? "yes" : "no"])
        let page =
          try await alias
          ? client().batches.list(
            limit: filtered ? 17 : nil, after: filtered ? "a+/#?=雪" : nil,
            statuses: filtered ? ["completed", "future,+雪", "completed"] : [],
            createdAfter: filtered ? "2026-01-01T00:00:00+01:00" : nil,
            createdBefore: filtered ? "opaque /?#雪" : nil, options: options)
          : client().listBatches(
            limit: filtered ? 17 : nil, after: filtered ? "a+/#?=雪" : nil,
            statuses: filtered ? ["completed", "future,+雪", "completed"] : nil,
            createdAfter: filtered ? "2026-01-01T00:00:00+01:00" : nil,
            createdBefore: filtered ? "opaque /?#雪" : nil, options: options)
        XCTAssertEqual(page.data.first?.id, "batch_1")
        XCTAssertNil(page.data.first?.results)
        XCTAssertTrue(page.hasMore)
        XCTAssertEqual(page.firstID, "batch_1")
      }
    }
  }

  func testEscapedGetAndRequestOptionsThroughBothAPIs() async throws {
    for alias in [false, true] {
      let options = RequestOptions(
        timeout: 17, baseURL: URL(string: "https://batches.invalid/custom")!,
        extraHeaders: ["X-Custom": "yes"])
      let batch =
        try await alias
        ? client().batches.get(id: "a/b?#%雪", options: options)
        : client().getBatch(id: "a/b?#%雪", options: options)
      XCTAssertEqual(batch.status, "completed")
      XCTAssertEqual(batch.results?.count, 1)
      XCTAssertEqual(batch.results?.first?.response?.statusCode, 200)
      XCTAssertEqual(
        batch.results?.first?.response?.body,
        .object([
          "arbitrary": .array([.number(1), .bool(true), .object(["nested": .string("value")])])
        ]))
    }
  }

  func testFailedBatchIsSuccessfulHTTPResponse() async throws {
    let batch = try await client().getBatch(
      id: "failed", options: .init(extraHeaders: ["X-Failed": "yes"]))
    XCTAssertEqual(batch.status, "failed")
    XCTAssertNotNil(batch.error)
  }

  func testPaymentRequiredRetainsBatchMetadataAsAPIError() async throws {
    do {
      _ = try await client().getBatch(
        id: "batch_1", options: .init(extraHeaders: ["X-Status": "402"]))
      XCTFail("Expected payment-required API error, not a successful batch")
    } catch let error as OpenRouterError {
      guard case .apiError(let status, let code, let message, let rawBody) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(status, 402)
      XCTAssertEqual(code, 402)
      XCTAssertEqual(message, "batch failure")
      let batch = try JSONDecoder().decode(
        BatchObject.self, from: Data(try XCTUnwrap(rawBody).utf8))
      XCTAssertEqual(batch.id, "batch_1")
      XCTAssertEqual(batch.error?.code, 402)
      XCTAssertNil(batch.results)
    }
  }

  func testErrorsAndMissingKeyBeforeDispatch() async throws {
    for method in 0..<6 {
      for status in [400, 401, 402, 403, 404, 410, 413, 429, 500] {
        // The default retry policy is deliberately retained, including for POST.
        let options = RequestOptions(extraHeaders: ["X-Status": String(status)])
        do {
          try await invoke(client(), method: method, options: options)
          XCTFail("Expected HTTP error")
        } catch let error as OpenRouterError {
          guard case .apiError(let actual, let code, let message, let rawBody) = error else {
            return XCTFail("Unexpected error: \(error)")
          }
          XCTAssertEqual(actual, status)
          XCTAssertEqual(code, status)
          XCTAssertEqual(message, "batch failure")
          XCTAssertTrue(rawBody?.contains("results") == true)
          if status == 402 {
            XCTAssertTrue(rawBody?.contains("request_counts") == true)
          } else {
            XCTAssertTrue(rawBody?.contains("metadata") == true)
          }
        }
      }
      do {
        try await invoke(client(key: ""), method: method, options: nil)
        XCTFail("Expected missing API key")
      } catch let error as OpenRouterError {
        guard case .missingAPIKey = error else { return XCTFail("Unexpected error: \(error)") }
      }
    }
  }

  private func invoke(_ client: OpenRouterClient, method: Int, options: RequestOptions?)
    async throws
  {
    switch method {
    case 0: _ = try await client.createBatch(submission, options: options)
    case 1: _ = try await client.batches.create(submission, options: options)
    case 2: _ = try await client.listBatches(options: options)
    case 3: _ = try await client.batches.list(options: options)
    case 4: _ = try await client.getBatch(id: "batch_1", options: options)
    default: _ = try await client.batches.get(id: "batch_1", options: options)
    }
  }
}

private final class BatchURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer batch-key")
      XCTAssertNil(components.fragment)
      let isPost = request.httpMethod == "POST"
      let isList = !isPost && components.path.hasSuffix("/batches")
      if isPost {
        XCTAssertEqual(components.percentEncodedPath, "/api/v1/batches")
        XCTAssertNil(components.query)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        var body = request.httpBody
        if body == nil, let stream = request.httpBodyStream {
          stream.open()
          defer { stream.close() }
          var data = Data()
          var buffer = [UInt8](repeating: 0, count: 4096)
          while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(contentsOf: buffer.prefix(count))
          }
          body = data
        }
        let data = try XCTUnwrap(body)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(
          Set(json.keys),
          ["endpoint", "model", "requests", "completion_window", "provider", "callback_url"])
        XCTAssertEqual(json["endpoint"] as? String, "/v1/chat/completions")
        XCTAssertEqual(json["model"] as? String, "provider/model")
        XCTAssertEqual(json["completion_window"] as? String, "24h")
        XCTAssertEqual(json["callback_url"] as? String, "https://callback.invalid/hook")
        let provider = try XCTUnwrap(json["provider"] as? [String: Any])
        XCTAssertEqual(Set(provider.keys), ["only", "allow_fallbacks"])
        XCTAssertEqual(provider["only"] as? [String], ["provider"])
        XCTAssertEqual(provider["allow_fallbacks"] as? Bool, false)
        let items = try XCTUnwrap(json["requests"] as? [[String: Any]])
        XCTAssertEqual(items.first?["custom_id"] as? String, "one")
        let text = try XCTUnwrap(String(data: data, encoding: .utf8))
        let requestsPosition = try XCTUnwrap(text.range(of: "\"requests\"")?.lowerBound)
        for key in ["endpoint", "model", "provider", "completion_window", "callback_url"] {
          XCTAssertLessThan(
            try XCTUnwrap(text.range(of: "\"\(key)\"")?.lowerBound), requestsPosition,
            "\(key) must precede requests in the wire body")
        }
      } else if isList {
        let query = components.queryItems ?? []
        if request.value(forHTTPHeaderField: "X-Filtered") == "yes" {
          XCTAssertEqual(
            query,
            [
              .init(name: "limit", value: "17"), .init(name: "after", value: "a+/#?=雪"),
              .init(name: "status", value: "completed"), .init(name: "status", value: "future,+雪"),
              .init(name: "status", value: "completed"),
              .init(name: "created_after", value: "2026-01-01T00:00:00+01:00"),
              .init(name: "created_before", value: "opaque /?#雪"),
            ])
        } else {
          XCTAssertTrue(query.isEmpty)
        }
      } else {
        XCTAssertNil(components.query)
        if request.value(forHTTPHeaderField: "X-Custom") == "yes" {
          XCTAssertEqual(components.percentEncodedPath, "/custom/batches/a%2Fb%3F%23%25%E9%9B%AA")
          XCTAssertEqual(url.host, "batches.invalid")
          XCTAssertEqual(request.timeoutInterval, 17)
        }
      }
      let status =
        request.value(forHTTPHeaderField: "X-Status").flatMap(Int.init) ?? (isPost ? 202 : 200)
      let failed = request.value(forHTTPHeaderField: "X-Failed") == "yes"
      let results =
        isList || isPost
        ? "null"
        : #"[{"id":"result_1","custom_id":"one","response":{"status_code":200,"body":{"arbitrary":[1,true,{"nested":"value"}]}}}]"#
      let batch = """
        {"id":"batch_1","object":"batch","endpoint":"/v1/chat/completions","model":"provider/model",
        "completion_window":"24h","status":"\(isPost ? "validating" : (failed ? "failed" : "completed"))","created_at":1,
        "request_counts":{"total":1,"completed":\(isPost ? 0 : 1),"failed":0},"results":\(results),
        "error":\(failed ? #"{"code":500,"message":"failed"}"# : "null")}
        """
      let payload: String
      if status == 402 {
        payload = """
          {"id":"batch_1","object":"batch","endpoint":"/v1/chat/completions",
          "model":"provider/model","completion_window":"24h","status":"failed",
          "created_at":1,"finalized_at":2,"expires_at":86401,"provider":"provider",
          "request_counts":{"total":1,"completed":0,"failed":1},"usage":null,
          "results":null,"error":{"code":402,"message":"batch failure"}}
          """
      } else if status >= 400 {
        payload = """
          {"error":{"code":\(status),"message":"batch failure","metadata":{"provider":"test"}},"results":null}
          """
      } else if isList {
        payload = """
          {"object":"list","data":[\(batch)],"has_more":true,"first_id":"batch_1","last_id":"batch_1"}
          """
      } else {
        payload = batch
      }
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: url, statusCode: status, httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]))
      self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      self.client?.urlProtocol(self, didLoad: Data(payload.utf8))
      self.client?.urlProtocolDidFinishLoading(self)
    } catch { self.client?.urlProtocol(self, didFailWithError: error) }
  }

  override func stopLoading() {}
}
