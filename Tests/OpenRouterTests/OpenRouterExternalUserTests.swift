import Foundation
import XCTest

@testable import OpenRouter

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterExternalUserTests: XCTestCase {
  private let record = ExternalUser(
    user: "employee", isActive: false, createdAt: "created", updatedAt: "updated")
  private func client(apiKey: String = "management") -> OpenRouterClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [ExternalUserOfflineProtocol.self]
    return OpenRouterClient(
      apiKey: apiKey,
      configuration: .init(httpReferer: "https://app.example", appTitle: "App"),
      session: URLSession(configuration: config))
  }
  private func options(
    _ method: String, status: Int = 200, query: String = "{}", body: String = "{}",
    resource: Bool = false
  ) -> RequestOptions {
    RequestOptions(extraHeaders: [
      "X-Method": method, "X-Status": String(status), "X-Query": query, "X-Body": body,
      "X-Path": resource
        ? "/api/v1/external-users/a%2Fb%25%3F%23%20%E9%9B%AA" : "/api/v1/external-users",
    ])
  }
  func testRoutesAndAliases() async throws {
    for alias in [false, true] {
      let c = client()
      for inactive in [nil, false, true] as [Bool?] {
        let q =
          inactive.map {
            "{\"offset\":\"0\",\"limit\":\"0\",\"user\":\"..\",\"include_inactive\":\"\($0)\"}"
          } ?? "{}"
        let o = options("GET", query: q)
        let result =
          try await alias
          ? c.externalUsers.list(
            offset: inactive == nil ? nil : 0, limit: inactive == nil ? nil : 0,
            user: inactive == nil ? nil : "..", includeInactive: inactive, options: o)
          : c.listExternalUsers(
            offset: inactive == nil ? nil : 0, limit: inactive == nil ? nil : 0,
            user: inactive == nil ? nil : "..", includeInactive: inactive, options: o)
        XCTAssertEqual(result, .init(data: [], totalCount: 0))
      }
      let create = options("POST", status: 201, body: #"{"user":"."}"#)
      let created =
        try await alias
        ? c.externalUsers.create(.init(user: "."), options: create)
        : c.createExternalUser(.init(user: "."), options: create)
      XCTAssertEqual(created.data, record)
      let user = "a/b%?# 雪"
      let get = options("GET", resource: true)
      let got =
        try await alias
        ? c.externalUsers.get(user: user, options: get)
        : c.getExternalUser(user: user, options: get)
      XCTAssertEqual(got.data, record)
      let patch = options("PATCH", body: #"{"is_active":false}"#, resource: true)
      let updated =
        try await alias
        ? c.externalUsers.update(user: user, .init(isActive: false), options: patch)
        : c.updateExternalUser(user: user, .init(isActive: false), options: patch)
      XCTAssertEqual(updated.data, record)
      let delete = options("DELETE", status: 204, resource: true)
      if alias {
        try await c.externalUsers.delete(user: user, options: delete)
      } else {
        try await c.deleteExternalUser(user: user, options: delete)
      }
    }
  }
  func testErrorsAllOperationsAndUnexpectedDeleteSuccess() async throws {
    for status in [400, 401, 403, 404, 409, 500, 200, 201, 202] {
      for operation in 0..<5 where status >= 400 || operation == 4 {
        let o = options("", status: status)
        do {
          let c = client()
          switch operation {
          case 0: _ = try await c.listExternalUsers(options: o)
          case 1: _ = try await c.createExternalUser(.init(user: "u"), options: o)
          case 2: _ = try await c.getExternalUser(user: "u", options: o)
          case 3: _ = try await c.updateExternalUser(user: "u", .init(isActive: false), options: o)
          default: try await c.deleteExternalUser(user: "u", options: o)
          }
          XCTFail("Expected error")
        } catch let error as OpenRouterError {
          if status < 400 {
            guard case .invalidResponse = error else { return XCTFail("Unexpected \(error)") }
          } else {
            guard case .apiError(let actual, let code, let message, _) = error else {
              return XCTFail("Unexpected \(error)")
            }
            XCTAssertEqual(actual, status)
            XCTAssertEqual(code, status)
            XCTAssertEqual(message, "failure")
          }
        }
      }
    }
  }
  func testDotPathsNeverReachTransport() async throws {
    for user in [".", ".."] {
      for operation in 0..<3 {
        do {
          // No key: invalidURL must precede even request construction/authentication.
          let c = OpenRouterClient()
          switch operation {
          case 0: _ = try await c.getExternalUser(user: user)
          case 1: _ = try await c.updateExternalUser(user: user, .init(isActive: true))
          default: try await c.deleteExternalUser(user: user)
          }
          XCTFail("Expected invalid URL")
        } catch let error as OpenRouterError {
          guard case .invalidURL(let explanation) = error else {
            return XCTFail("Unexpected error")
          }
          XCTAssertTrue(explanation.contains("list user filter"))
        }
      }
    }
  }
  func testDeleteRetryIsOptIn() async throws {
    for retry in [false, true] {
      let token = UUID().uuidString
      let o = RequestOptions(
        retries: retry
          ? .backoff(
            maxAttempts: 2, initialDelay: 0, maxDelay: 0, exponent: 1, retryStatusCodes: [503],
            retryConnectionErrors: false) : nil, extraHeaders: ["X-Retry-Token": token])
      do {
        try await client().deleteExternalUser(user: "u", options: o)
        XCTAssertTrue(retry)
      } catch let error as OpenRouterError {
        XCTAssertFalse(retry)
        guard case .apiError(let status, _, _, _) = error else {
          return XCTFail("Unexpected error")
        }
        XCTAssertEqual(status, 503)
      }
      XCTAssertEqual(ExternalUserOfflineProtocol.attempts.remove(token), retry ? 2 : 1)
    }
  }

  func testDeleteNetworkAndNonHTTPResponses() async throws {
    for mode in ["network", "cancel", "nonHTTP"] {
      do {
        try await client().deleteExternalUser(
          user: "u", options: .init(extraHeaders: ["X-Mode": mode]))
        XCTFail("Expected error")
      } catch {
        if mode == "nonHTTP" {
          guard case OpenRouterError.invalidResponse = error else {
            return XCTFail("Unexpected \(error)")
          }
        } else {
          XCTAssertEqual(
            (error as? URLError)?.code, mode == "cancel" ? .cancelled : .notConnectedToInternet)
        }
      }
    }
  }

  func testMissingAPIKeyAllOperations() async throws {
    let c = client(apiKey: "")
    for operation in 0..<5 {
      do {
        switch operation {
        case 0: _ = try await c.listExternalUsers()
        case 1: _ = try await c.createExternalUser(.init(user: "employee"))
        case 2: _ = try await c.getExternalUser(user: "employee")
        case 3:
          _ = try await c.updateExternalUser(user: "employee", .init(isActive: false))
        default: try await c.deleteExternalUser(user: "employee")
        }
        XCTFail("Expected missingAPIKey for operation \(operation)")
      } catch OpenRouterError.missingAPIKey {
        // Exact expected error; the injected offline protocol must not receive a request.
      } catch {
        XCTFail("Unexpected error for operation \(operation): \(error)")
      }
    }
  }

  func testRequiredSchemaAndRoundTrips() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let create = CreateExternalUserRequest(user: "employee")
    XCTAssertEqual(
      try decoder.decode(CreateExternalUserRequest.self, from: encoder.encode(create)), create)
    let update = UpdateExternalUserRequest(isActive: false)
    XCTAssertEqual(
      try decoder.decode(UpdateExternalUserRequest.self, from: encoder.encode(update)), update)
    let single = ExternalUserResponse(data: record)
    XCTAssertEqual(
      try decoder.decode(ExternalUserResponse.self, from: encoder.encode(single)), single)
    for text in ["{}", #"{"user":null}"#] {
      XCTAssertThrowsError(
        try decoder.decode(CreateExternalUserRequest.self, from: Data(text.utf8)))
    }
    XCTAssertEqual(try decoder.decode(ExternalUser.self, from: encoder.encode(record)), record)
    let response = ListExternalUsersResponse(data: [record], totalCount: 123)
    XCTAssertEqual(
      try decoder.decode(ListExternalUsersResponse.self, from: encoder.encode(response)), response)
    for key in ["user", "is_active", "created_at", "updated_at"] {
      var object = try JSONSerialization.jsonObject(with: encoder.encode(record)) as! [String: Any]
      object.removeValue(forKey: key)
      XCTAssertThrowsError(
        try decoder.decode(ExternalUser.self, from: JSONSerialization.data(withJSONObject: object)))
      object[key] = NSNull()
      XCTAssertThrowsError(
        try decoder.decode(ExternalUser.self, from: JSONSerialization.data(withJSONObject: object)))
    }
    for text in ["{}", #"{"is_active":null}"#] {
      XCTAssertThrowsError(
        try decoder.decode(UpdateExternalUserRequest.self, from: Data(text.utf8)))
    }
    for text in [
      #"{"data":[]}"#, #"{"data":[],"total_count":null}"#, #"{"data":[],"total_count":1.5}"#,
    ] {
      XCTAssertThrowsError(
        try decoder.decode(ListExternalUsersResponse.self, from: Data(text.utf8)))
    }
  }
}

private final class ExternalUserOfflineProtocol: URLProtocol {
  final class Attempts: @unchecked Sendable {
    private let lock = NSLock()
    private var counts: [String: Int] = [:]
    func next(_ token: String) -> Int {
      lock.lock()
      defer { lock.unlock() }
      counts[token, default: 0] += 1
      return counts[token]!
    }
    func remove(_ token: String) -> Int? {
      lock.lock()
      defer { lock.unlock() }
      return counts.removeValue(forKey: token)
    }
  }
  static let attempts = Attempts()
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer management")
      XCTAssertEqual(request.value(forHTTPHeaderField: "HTTP-Referer"), "https://app.example")
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-OpenRouter-Title"), "App")
      if let mode = request.value(forHTTPHeaderField: "X-Mode") {
        if mode == "nonHTTP" {
          client?.urlProtocol(
            self,
            didReceive: URLResponse(
              url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil),
            cacheStoragePolicy: .notAllowed)
          client?.urlProtocolDidFinishLoading(self)
        } else {
          client?.urlProtocol(
            self,
            didFailWithError: URLError(mode == "cancel" ? .cancelled : .notConnectedToInternet))
        }
        return
      }
      if let method = request.value(forHTTPHeaderField: "X-Method"), !method.isEmpty {
        XCTAssertEqual(request.httpMethod, method)
        XCTAssertEqual(components.percentEncodedPath, request.value(forHTTPHeaderField: "X-Path"))
        let query = Dictionary(
          uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        let expected =
          try JSONSerialization.jsonObject(
            with: Data(request.value(forHTTPHeaderField: "X-Query")!.utf8)) as! [String: String]
        XCTAssertEqual(query, expected)
        if method == "POST" || method == "PATCH" {
          var data = request.httpBody ?? Data()
          if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
              let n = stream.read(&buffer, maxLength: buffer.count)
              if n <= 0 { break }
              data.append(contentsOf: buffer.prefix(n))
            }
          }
          XCTAssertEqual(
            try JSONSerialization.jsonObject(with: data) as! NSDictionary,
            try JSONSerialization.jsonObject(
              with: Data(request.value(forHTTPHeaderField: "X-Body")!.utf8)) as! NSDictionary)
        }
      }
      let status: Int
      if let token = request.value(forHTTPHeaderField: "X-Retry-Token") {
        status = Self.attempts.next(token) == 1 ? 503 : 204
      } else {
        status = Int(request.value(forHTTPHeaderField: "X-Status")!)!
      }
      let body: String
      if status >= 400 {
        body = "{\"error\":{\"code\":\(status),\"message\":\"failure\"}}"
      } else if status == 204 {
        body = ""
      } else if components.path == "/api/v1/external-users" && request.httpMethod == "GET" {
        body = #"{"data":[],"total_count":0}"#
      } else {
        body =
          #"{"data":{"user":"employee","is_active":false,"created_at":"created","updated_at":"updated"}}"#
      }
      client?.urlProtocol(
        self,
        didReceive: HTTPURLResponse(
          url: url, statusCode: status, httpVersion: nil, headerFields: nil)!,
        cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: Data(body.utf8))
      client?.urlProtocolDidFinishLoading(self)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }
  override func stopLoading() {}
}
