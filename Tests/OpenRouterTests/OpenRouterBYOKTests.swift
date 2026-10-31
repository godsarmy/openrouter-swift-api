import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

private let byokFixture =
  #"{"id":"id","workspace_id":null,"provider":"future/provider","label":"sk-...mask","disabled":false,"is_fallback":true,"is_required":true,"is_byok_only":true,"declared_zdr":null,"declared_region":null,"allowed_models":null,"allowed_api_key_hashes":null,"allowed_user_ids":null,"sort_order":0,"created_at":"now"}"#

final class OpenRouterBYOKTests: XCTestCase {
  func testOperationsAndAliases() async throws {
    for alias in [false, true] {
      for operation in 0..<5 {
        for filtered in [false, true] {
          let c = client()
          let method = ["GET", "POST", "GET", "PATCH", "DELETE"][operation]
          let path = operation < 2 ? "/api/v1/byok" : "/api/v1/byok/a%2Fb%3F%23%25%E9%9B%AA"
          let options = RequestOptions(extraHeaders: [
            "X-Method": method, "X-Path": path, "X-Filtered": String(filtered),
          ])
          switch operation {
          case 0:
            let r =
              try await alias
              ? c.byok.list(
                offset: filtered ? 2 : nil, limit: filtered ? 3 : nil,
                workspaceID: filtered ? "workspace" : nil,
                provider: filtered ? "future/provider" : nil, options: options)
              : c.listBYOKKeys(
                offset: filtered ? 2 : nil, limit: filtered ? 3 : nil,
                workspaceID: filtered ? "workspace" : nil,
                provider: filtered ? "future/provider" : nil, options: options)
            XCTAssertEqual(r.totalCount, 1)
          case 1:
            let request = CreateBYOKKeyRequest(provider: "future/provider", key: "provider-secret")
            let r =
              try await alias
              ? c.byok.create(request, options: options)
              : c.createBYOKKey(request, options: options)
            XCTAssertEqual(r.data.label, "sk-...mask")
          case 2:
            let r =
              try await alias
              ? c.byok.get(id: "a/b?#%雪", options: options)
              : c.getBYOKKey(id: "a/b?#%雪", options: options)
            XCTAssertEqual(r.data.provider, "future/provider")
          case 3:
            let request = UpdateBYOKKeyRequest(key: "provider-secret")
            let r =
              try await alias
              ? c.byok.update(id: "a/b?#%雪", request, options: options)
              : c.updateBYOKKey(id: "a/b?#%雪", request, options: options)
            XCTAssertTrue(r.data.isBYOKOnly)
          default:
            let r =
              try await alias
              ? c.byok.delete(id: "a/b?#%雪", options: options)
              : c.deleteBYOKKey(id: "a/b?#%雪", options: options)
            XCTAssertTrue(r.deleted)
          }
        }
      }
    }
  }

  func testNullableUpdatesPoliciesAndRedaction() throws {
    var update = UpdateBYOKKeyRequest()
    XCTAssertEqual(try object(update).count, 0)
    update.name = .null
    update.declaredRegion = .null
    update.declaredZDR = .null
    update.allowedModels = .null
    update.allowedAPIKeyHashes = .null
    update.allowedUserIDs = .null
    XCTAssertEqual(try object(update).count, 6)
    XCTAssertTrue(try object(update).values.allSatisfy { $0 is NSNull })
    update.name = .value("name")
    update.declaredRegion = .value("future-region")
    update.declaredZDR = .value(false)
    update.allowedModels = .value(["model"])
    update.allowedAPIKeyHashes = .value(["hash"])
    update.allowedUserIDs = .value(["user"])
    update.key = "provider-secret"
    update.disabled = false
    update.isFallback = true
    update.isRequired = true
    update.isBYOKOnly = true
    let fields = try object(update)
    XCTAssertEqual(fields["key"] as? String, "provider-secret")
    XCTAssertEqual(fields["declared_zdr"] as? Bool, false)
    XCTAssertEqual(fields["allowed_models"] as? [String], ["model"])
    let create = CreateBYOKKeyRequest(
      provider: "future/provider", key: "provider-secret",
      allowedAPIKeyHashes: ["hash"], allowedModels: ["model"], allowedUserIDs: ["user"],
      declaredRegion: "future-region", declaredZDR: false, disabled: false, isBYOKOnly: true,
      isFallback: true, isRequired: true, name: "name", workspaceID: "workspace")
    var expected = fields
    expected["provider"] = "future/provider"
    expected["workspace_id"] = "workspace"
    XCTAssertEqual(try object(create) as NSDictionary, expected as NSDictionary)
    for text in [
      String(describing: create), String(reflecting: create), String(describing: update),
      String(reflecting: update),
    ] {
      XCTAssertFalse(text.contains("provider-secret"))
    }
    var dumpText = ""
    dump(create, to: &dumpText)
    dump(update, to: &dumpText)
    XCTAssertFalse(dumpText.contains("provider-secret"))
  }

  func testNullResponseRoundTripsAndRequiredEncodedKeys() throws {
    let key = try JSONDecoder().decode(BYOKKey.self, from: Data(byokFixture.utf8))
    let encoded = try object(key)
    for field in [
      "allowed_api_key_hashes", "allowed_models", "allowed_user_ids",
      "declared_region", "declared_zdr", "workspace_id",
    ] {
      XCTAssertTrue(encoded[field] is NSNull, field)
    }
    XCTAssertNil(encoded["name"])
    try assertRoundTrip(key)
    try assertRoundTrip(CreateBYOKKeyResponse(data: key))
    try assertRoundTrip(GetBYOKKeyResponse(data: key))
    try assertRoundTrip(UpdateBYOKKeyResponse(data: key))
    try assertRoundTrip(ListBYOKKeysResponse(data: [key], totalCount: 1))
  }

  private func assertRoundTrip<T: Codable & Equatable>(_ value: T) throws {
    XCTAssertEqual(try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value)), value)
  }

  func testResponseRequirementsAndDeletion() throws {
    var fixture = try JSONSerialization.jsonObject(with: Data(byokFixture.utf8)) as! [String: Any]
    let decoded = try JSONDecoder().decode(BYOKKey.self, from: Data(byokFixture.utf8))
    XCTAssertNil(decoded.name)
    XCTAssertNil(decoded.workspaceID)
    XCTAssertTrue(decoded.isFallback)
    for field in fixture.keys {
      var missing = fixture
      missing.removeValue(forKey: field)
      XCTAssertThrowsError(
        try JSONDecoder().decode(
          BYOKKey.self, from: JSONSerialization.data(withJSONObject: missing)), field)
    }
    fixture["name"] = "name"
    fixture["workspace_id"] = "workspace"
    fixture["declared_region"] = "future-region"
    fixture["declared_zdr"] = false
    for field in ["allowed_models", "allowed_api_key_hashes", "allowed_user_ids"] {
      fixture[field] = ["value"]
    }
    let value = try JSONDecoder().decode(
      BYOKKey.self, from: JSONSerialization.data(withJSONObject: fixture))
    XCTAssertEqual(value.allowedUserIDs, ["value"])
    for invalid in [#"{}"#, #"{"deleted":false}"#, #"{"deleted":"true"}"#] {
      XCTAssertThrowsError(
        try JSONDecoder().decode(DeleteBYOKKeyResponse.self, from: Data(invalid.utf8)))
    }
  }

  func testErrors() async throws {
    for status in [400, 401, 403, 404, 409, 500] {
      do {
        _ = try await client().byok.get(
          id: "id", options: RequestOptions(extraHeaders: ["X-Status": String(status)]))
        XCTFail("Expected error")
      } catch let error as OpenRouterError {
        guard case .apiError(let actual, _, _, _) = error else {
          return XCTFail("Unexpected error")
        }
        XCTAssertEqual(actual, status)
      }
    }
    do {
      _ = try await client(key: nil).byok.list()
      XCTFail("Expected missing key")
    } catch let error as OpenRouterError {
      guard case .missingAPIKey = error else { return XCTFail("Unexpected error") }
    }
  }

  private func object<T: Encodable>(_ value: T) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as! [String: Any]
  }
  private func client(key: String? = "management-key") -> OpenRouterClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [BYOKOfflineProtocol.self]
    let session = URLSession(configuration: config)
    return key.map { OpenRouterClient(apiKey: $0, session: session) }
      ?? OpenRouterClient(session: session)
  }
}

private final class BYOKOfflineProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer management-key")
      if let method = request.value(forHTTPHeaderField: "X-Method") {
        XCTAssertEqual(request.httpMethod, method)
        XCTAssertEqual(components.percentEncodedPath, request.value(forHTTPHeaderField: "X-Path"))
        if method == "GET" && url.lastPathComponent == "byok"
          && request.value(forHTTPHeaderField: "X-Filtered") == "true"
        {
          XCTAssertEqual(
            Dictionary(
              uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }),
            [
              "offset": "2", "limit": "3", "workspace_id": "workspace",
              "provider": "future/provider",
            ])
        } else {
          XCTAssertNil(components.query)
        }
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
          let body = try JSONSerialization.jsonObject(with: data) as! [String: String]
          XCTAssertEqual(body["key"], "provider-secret")
          XCTAssertEqual(body.count, method == "POST" ? 2 : 1)
        }
      }
      let status = Int(request.value(forHTTPHeaderField: "X-Status") ?? "200")!
      let json: String
      if status != 200 {
        json = "{\"error\":{\"code\":\(status),\"message\":\"BYOK failure\"}}"
      } else if request.httpMethod == "DELETE" {
        json = #"{"deleted":true}"#
      } else if request.httpMethod == "GET" && url.lastPathComponent == "byok" {
        json = "{\"data\":[\(byokFixture)],\"total_count\":1}"
      } else {
        json = "{\"data\":\(byokFixture)}"
      }
      client?.urlProtocol(
        self,
        didReceive: HTTPURLResponse(
          url: url, statusCode: request.httpMethod == "POST" && status == 200 ? 201 : status,
          httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
        cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: Data(json.utf8))
      client?.urlProtocolDidFinishLoading(self)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }
  override func stopLoading() {}
}
