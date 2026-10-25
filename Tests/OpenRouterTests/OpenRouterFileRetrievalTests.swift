import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterFileRetrievalTests: XCTestCase {
  private func client(key: String = "file-key") -> OpenRouterClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [FileRetrievalURLProtocol.self]
    return OpenRouterClient(apiKey: key, session: URLSession(configuration: configuration))
  }

  private func options(
    path: String = "/api/v1/files", query: [String: String] = [:], shape: String = "openrouter"
  ) throws -> RequestOptions {
    let data = try JSONSerialization.data(withJSONObject: query)
    return RequestOptions(extraHeaders: [
      "X-Expected-Path": path, "X-Expected-Query": data.base64EncodedString(),
      "X-Test-Shape": shape,
    ])
  }

  func testListNilAndAllFiltersThroughBothAPIs() async throws {
    let workspace = UUID()
    let cursor = "opaque+/#?=雪"
    for alias in [false, true] {
      for filtered in [false, true] {
        let query =
          filtered
          ? [
            "limit": "37", "cursor": cursor, "workspace_id": workspace.uuidString,
            "provider": "future/provider", "after": "after+雪", "after_id": "first?",
            "before_id": "last#", "order": "future-order",
          ] : [:]
        let opt = try options(query: query)
        let page =
          try await alias
          ? client().files.list(
            limit: filtered ? 37 : nil, cursor: filtered ? cursor : nil,
            workspaceID: filtered ? workspace : nil, provider: filtered ? "future/provider" : nil,
            after: filtered ? "after+雪" : nil, afterID: filtered ? "first?" : nil,
            beforeID: filtered ? "last#" : nil, order: filtered ? "future-order" : nil, options: opt
          )
          : client().listFiles(
            limit: filtered ? 37 : nil, cursor: filtered ? cursor : nil,
            workspaceID: filtered ? workspace : nil, provider: filtered ? "future/provider" : nil,
            after: filtered ? "after+雪" : nil, afterID: filtered ? "first?" : nil,
            beforeID: filtered ? "last#" : nil, order: filtered ? "future-order" : nil, options: opt
          )
        XCTAssertEqual(page.data.first?.id, "file_1")
        XCTAssertTrue(page.hasMore)
        XCTAssertEqual(page.firstID, "first")
        XCTAssertEqual(page.lastID, "last")
        XCTAssertEqual(page.cursor, "next+/#?=雪")
        XCTAssertEqual(page.shape, "openrouter")
        XCTAssertEqual(page.object, "list")
      }
    }
  }

  func testMetadataShapesAndPaginationThroughBothAPIs() async throws {
    for shape in ["openrouter", "openai", "anthropic"] {
      for alias in [false, true] {
        let opt = try options(path: "/api/v1/files/file_1", shape: shape)
        let file =
          try await alias
          ? client().files.get(id: "file_1", options: opt)
          : client().getFile(id: "file_1", options: opt)
        XCTAssertEqual(file.id, "file_1")
        XCTAssertEqual(file.filename, "report.pdf")
        switch (shape, file) {
        case ("openrouter", .openRouter), ("openai", .openAI), ("anthropic", .anthropic): break
        default: XCTFail("Wrong metadata shape: \(file)")
        }
        let listOptions = try options(shape: shape)
        let page =
          try await alias
          ? client().files.list(options: listOptions) : client().listFiles(options: listOptions)
        XCTAssertEqual(page.shape, shape)
        XCTAssertEqual(page.data.first?.id, file.id)
        XCTAssertTrue(page.hasMore)
        XCTAssertEqual(page.firstID, "first")
        XCTAssertEqual(page.lastID, "last")
        XCTAssertEqual(page.cursor, "next+/#?=雪")
        XCTAssertEqual(page.object, "list")
      }
    }
  }

  func testEscapingFiltersOptionsAndBinaryContent() async throws {
    let workspace = UUID()
    for method in 0..<4 {
      let content = method >= 2
      var opt = try options(
        path: "/custom/files/a%2Fb%3F%23%25%E9%9B%AA" + (content ? "/content" : ""),
        query: ["workspace_id": workspace.uuidString, "provider": "future+/#?=雪"])
      opt.baseURL = URL(string: "https://files.invalid/custom")!
      opt.timeout = 17
      opt.extraHeaders["X-Check-Options"] = "custom"
      opt.extraHeaders["X-Omit-Content-Type"] = method == 3 ? "yes" : "no"
      switch method {
      case 0:
        _ = try await client().getFile(
          id: "a/b?#%雪", workspaceID: workspace, provider: "future+/#?=雪", options: opt)
      case 1:
        _ = try await client().files.get(
          id: "a/b?#%雪", workspaceID: workspace, provider: "future+/#?=雪", options: opt)
      default:
        let result =
          try await method == 2
          ? client().downloadFileContent(
            id: "a/b?#%雪", workspaceID: workspace, provider: "future+/#?=雪", options: opt)
          : client().files.content(
            id: "a/b?#%雪", workspaceID: workspace, provider: "future+/#?=雪", options: opt)
        XCTAssertEqual(result.data, Data([0, 255, 128, 1]))
        XCTAssertEqual(result.contentType, method == 3 ? nil : "application/octet-stream")
      }
    }
    var opt = try options(path: "/custom/files")
    opt.baseURL = URL(string: "https://files.invalid/custom")!
    opt.timeout = 17
    opt.extraHeaders["X-Check-Options"] = "custom"
    _ = try await client().files.list(options: opt)
  }

  func testErrorsAndMissingKeyForAllMethods() async throws {
    for method in 0..<6 {
      for status in [400, 401, 403, 404, 429, 500] {
        var opt = try options(
          path: "/api/v1/files" + (method % 3 == 0 ? "" : "/missing")
            + (method % 3 == 2 ? "/content" : ""))
        opt.retries = RetryPolicy.none
        opt.extraHeaders["X-Test-Status"] = String(status)
        do {
          try await invoke(client(), method: method, options: opt)
          XCTFail("Expected \(status)")
        } catch let error as OpenRouterError {
          guard case .apiError(let actual, let code, let message, _) = error else {
            return XCTFail("Unexpected error: \(error)")
          }
          XCTAssertEqual(actual, status)
          XCTAssertEqual(code, status)
          XCTAssertEqual(message, "file failure")
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
    case 0: _ = try await client.listFiles(options: options)
    case 1: _ = try await client.getFile(id: "missing", options: options)
    case 2: _ = try await client.downloadFileContent(id: "missing", options: options)
    case 3: _ = try await client.files.list(options: options)
    case 4: _ = try await client.files.get(id: "missing", options: options)
    default: _ = try await client.files.content(id: "missing", options: options)
    }
  }
}

private final class FileRetrievalURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer file-key")
      XCTAssertEqual(
        components.percentEncodedPath, request.value(forHTTPHeaderField: "X-Expected-Path"))
      XCTAssertNil(components.fragment)
      let expectedData = try XCTUnwrap(
        Data(base64Encoded: request.value(forHTTPHeaderField: "X-Expected-Query") ?? ""))
      let expected = try JSONDecoder().decode([String: String].self, from: expectedData)
      let items = components.queryItems ?? []
      XCTAssertEqual(items.count, expected.count)
      for item in items { XCTAssertEqual(item.value, expected[item.name]) }
      if request.value(forHTTPHeaderField: "X-Check-Options") != nil {
        XCTAssertEqual(url.host, "files.invalid")
        XCTAssertEqual(request.timeoutInterval, 17)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Check-Options"), "custom")
      }
      let content = components.path.hasSuffix("/content")
      if content {
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/octet-stream")
      }
      let status = Int(request.value(forHTTPHeaderField: "X-Test-Status") ?? "200") ?? 200
      let shape = request.value(forHTTPHeaderField: "X-Test-Shape") ?? "openrouter"
      let metadata: [String: Any] =
        shape == "openai"
        ? [
          "_shape": shape, "id": "file_1", "filename": "report.pdf", "object": "file",
          "bytes": 12, "created_at": 1_735_689_600, "purpose": "user_data", "status": "processed",
        ]
        : [
          "_shape": shape, "id": "file_1", "filename": "report.pdf", "type": "file",
          "size_bytes": 12, "created_at": "2025-01-01T00:00:00Z",
          "mime_type": "application/pdf", "downloadable": false,
        ]
      let body: Data
      if status != 200 {
        body = try JSONSerialization.data(withJSONObject: [
          "error": ["code": status, "message": "file failure"]
        ])
      } else if content {
        body = Data([0, 255, 128, 1])
      } else if components.path.hasSuffix("/files") {
        body = try JSONSerialization.data(withJSONObject: [
          "_shape": shape, "data": [metadata], "has_more": true, "first_id": "first",
          "last_id": "last", "cursor": "next+/#?=雪", "object": "list",
        ])
      } else {
        body = try JSONSerialization.data(withJSONObject: metadata)
      }
      let headers =
        request.value(forHTTPHeaderField: "X-Omit-Content-Type") == "yes"
        ? [:]
        : [
          "Content-Type": content && status == 200 ? "application/octet-stream" : "application/json"
        ]
      let response = try XCTUnwrap(
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: headers))
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: body)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
