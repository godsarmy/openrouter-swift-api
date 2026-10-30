import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterWorkspaceBudgetsTests: XCTestCase {
  func testOperationsAliasesIntervalsEscapingAndOptions() async throws {
    for alias in [false, true] {
      for interval in WorkspaceBudgetInterval.allCases {
        for operation in 0..<4 {
          for byok in [nil, false, true] as [Bool?] {
            let options = options(operation: operation, interval: interval, byok: byok)
            try await call(
              operation, alias: alias, interval: interval, byok: byok, options: options)
          }
        }
      }
    }
  }

  func testEmptyListAndAbsentResponseFlag() async throws {
    var options = options(operation: 0, interval: .daily)
    options.extraHeaders["X-Empty"] = "true"
    let response = try await client().workspaces.listBudgets(workspaceRef: ref, options: options)
    XCTAssertTrue(response.data.isEmpty)
    XCTAssertNil(response.includeBYOKInBudgets)
  }

  func testErrorsAndNoKey() async throws {
    for alias in [false, true] {
      for operation in 0..<4 {
        for status in [401, 403, 404, 500] {
          var options = options(operation: operation, interval: .daily)
          options.extraHeaders["X-Status"] = String(status)
          do {
            try await call(operation, alias: alias, interval: .daily, options: options)
            XCTFail("Expected API error")
          } catch let error as OpenRouterError {
            guard case .apiError(let actual, _, let message, _) = error else {
              return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(actual, status)
            XCTAssertEqual(message, "budget failure")
          }
        }
        do {
          try await call(
            operation, alias: alias, interval: .daily, missingKey: true,
            options: options(operation: operation, interval: .daily))
          XCTFail("Expected missing key")
        } catch let error as OpenRouterError {
          guard case .missingAPIKey = error else { return XCTFail("Unexpected error: \(error)") }
        }
      }
    }
  }

  func testModelRoundTripsAndRequiredTypes() throws {
    for interval in WorkspaceBudgetInterval.allCases {
      let budget = WorkspaceBudget(
        id: "budget", workspaceID: "workspace", limitUSD: 12.5,
        resetInterval: interval == .lifetime ? nil : interval.rawValue, createdAt: "created",
        updatedAt: "updated")
      let response = WorkspaceBudgetResponse(data: budget, includeBYOKInBudgets: false)
      XCTAssertEqual(
        try JSONDecoder().decode(
          WorkspaceBudgetResponse.self, from: JSONEncoder().encode(response)), response)
      let list = WorkspaceBudgetsResponse(data: [budget], includeBYOKInBudgets: true)
      XCTAssertEqual(
        try JSONDecoder().decode(WorkspaceBudgetsResponse.self, from: JSONEncoder().encode(list)),
        list)
    }
    for invalid in [
      #"{"id":"b","workspace_id":"w","limit_usd":"12","reset_interval":null,"created_at":"c","updated_at":"u"}"#,
      #"{"id":"b","workspace_id":"w","limit_usd":12,"reset_interval":null,"created_at":"c"}"#,
    ] {
      XCTAssertThrowsError(try JSONDecoder().decode(WorkspaceBudget.self, from: Data(invalid.utf8)))
    }
    XCTAssertFalse(DeleteWorkspaceBudgetResponse(deleted: false).deleted)
  }

  private let ref = "team/one?#%雪"

  private func call(
    _ operation: Int, alias: Bool, interval: WorkspaceBudgetInterval,
    byok: Bool? = nil, missingKey: Bool = false, options: RequestOptions
  ) async throws {
    let client = client(missingKey: missingKey)
    switch operation {
    case 0:
      let response =
        try await alias
        ? client.workspaces.listBudgets(workspaceRef: ref, options: options)
        : client.listWorkspaceBudgets(workspaceRef: ref, options: options)
      XCTAssertEqual(response.data.first?.limitUSD, 12.5)
      XCTAssertEqual(response.includeBYOKInBudgets, byok)
    case 1, 2:
      let response: WorkspaceBudgetResponse
      if operation == 1 {
        response =
          try await alias
          ? client.workspaces.getBudget(workspaceRef: ref, interval: interval, options: options)
          : client.getWorkspaceBudget(workspaceRef: ref, interval: interval, options: options)
      } else {
        let request = UpsertWorkspaceBudgetRequest(limitUSD: 12.5, includeBYOKInBudgets: byok)
        response =
          try await alias
          ? client.workspaces.upsertBudget(
            workspaceRef: ref, interval: interval, request, options: options)
          : client.upsertWorkspaceBudget(
            workspaceRef: ref, interval: interval, request, options: options)
      }
      XCTAssertEqual(response.data.limitUSD, 12.5)
      XCTAssertEqual(response.data.resetInterval, interval == .lifetime ? nil : interval.rawValue)
      XCTAssertEqual(response.includeBYOKInBudgets, byok)
    default:
      let response =
        try await alias
        ? client.workspaces.deleteBudget(workspaceRef: ref, interval: interval, options: options)
        : client.deleteWorkspaceBudget(workspaceRef: ref, interval: interval, options: options)
      XCTAssertTrue(response.deleted)
    }
  }

  private func options(operation: Int, interval: WorkspaceBudgetInterval, byok: Bool? = nil)
    -> RequestOptions
  {
    var headers = [
      "X-Expected-Path": "/custom/workspaces/team%2Fone%3F%23%25%E9%9B%AA/budgets"
        + (operation == 0 ? "" : "/" + interval.rawValue),
      "X-Expected-Method": operation == 2 ? "PUT" : operation == 3 ? "DELETE" : "GET",
      "X-Custom": "override",
    ]
    if let byok { headers["X-BYOK"] = String(byok) }
    return RequestOptions(
      timeout: 17, retries: RetryPolicy.none,
      baseURL: URL(string: "https://budgets.invalid/custom")!,
      extraHeaders: headers)
  }

  private func client(missingKey: Bool = false) -> OpenRouterClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [WorkspaceBudgetOfflineURLProtocol.self]
    let session = URLSession(configuration: configuration)
    return missingKey
      ? OpenRouterClient(session: session)
      : OpenRouterClient(apiKey: "budget-key", session: session)
  }
}

private final class WorkspaceBudgetOfflineURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(request.httpMethod, request.value(forHTTPHeaderField: "X-Expected-Method"))
      XCTAssertEqual(
        components.percentEncodedPath, request.value(forHTTPHeaderField: "X-Expected-Path"))
      XCTAssertNil(components.query)
      XCTAssertNil(components.fragment)
      XCTAssertEqual(url.host, "budgets.invalid")
      XCTAssertEqual(request.timeoutInterval, 17)
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "override")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer budget-key")
      let byok = request.value(forHTTPHeaderField: "X-BYOK").map { $0 == "true" }
      if request.httpMethod == "PUT" {
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        var data = request.httpBody
        if data == nil, let stream = request.httpBodyStream {
          stream.open()
          defer { stream.close() }
          var result = Data()
          var buffer = [UInt8](repeating: 0, count: 1024)
          while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            result.append(contentsOf: buffer.prefix(count))
          }
          data = result
        }
        let actual = try JSONSerialization.jsonObject(with: XCTUnwrap(data)) as? NSDictionary
        var expected: [String: Any] = ["limit_usd": 12.5]
        if let byok { expected["include_byok_in_budgets"] = byok }
        XCTAssertEqual(actual, expected as NSDictionary)
      }
      let interval = url.lastPathComponent
      let budget: [String: Any] = [
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "workspace_id": "550e8400-e29b-41d4-a716-446655440001", "limit_usd": 12.5,
        "reset_interval": interval == "lifetime"
          ? NSNull() : (interval == "budgets" ? "daily" : interval) as Any,
        "created_at": "2026-10-29T00:00:00Z", "updated_at": "2026-10-29T00:00:00Z",
      ]
      let status = Int(request.value(forHTTPHeaderField: "X-Status") ?? "200") ?? 200
      var object: [String: Any]
      if status != 200 {
        object = ["error": ["code": status, "message": "budget failure"]]
      } else if request.httpMethod == "DELETE" {
        object = ["deleted": true]
      } else if interval == "budgets" {
        object = ["data": request.value(forHTTPHeaderField: "X-Empty") == nil ? [budget] : []]
      } else {
        object = ["data": budget]
      }
      if let byok { object["include_byok_in_budgets"] = byok }
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: url, statusCode: status, httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]))
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: try JSONSerialization.data(withJSONObject: object))
      client?.urlProtocolDidFinishLoading(self)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }
  override func stopLoading() {}
}
