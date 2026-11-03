import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterOrganizationSettingsTests: XCTestCase {
  private func makeClient(key: String? = "settings-key") -> OpenRouterClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [OrganizationSettingsURLProtocol.self]
    let session = URLSession(configuration: configuration)
    if let key { return OpenRouterClient(apiKey: key, session: session) }
    return OpenRouterClient(session: session)
  }

  private func call(
    alias: Bool, update: Bool, value: Bool = false, key: String? = "settings-key",
    options: RequestOptions? = nil
  ) async throws -> OrganizationSettingsResponse {
    let client = makeClient(key: key)
    if update {
      let request = UpdateOrganizationSettingsRequest(isFilteredModelCatalogEnabled: value)
      return try await alias
        ? client.organization.updateSettings(request, options: options)
        : client.updateOrganizationSettings(request, options: options)
    }
    return try await alias
      ? client.organization.getSettings(options: options)
      : client.getOrganizationSettings(options: options)
  }

  func testMethodsAliasesAndOptions() async throws {
    for alias in [false, true] {
      for update in [false, true] {
        for value in [false, true] {
          for override in [false, true] {
            var options = RequestOptions(extraHeaders: [
              "X-Expected-Method": update ? "PATCH" : "GET",
              "X-Expected-Value": String(value),
            ])
            if override {
              options.baseURL = URL(string: "https://settings.invalid/custom")!
              options.timeout = 17
              options.extraHeaders["X-Custom"] = "override"
            }
            let response = try await call(
              alias: alias, update: update, value: value, options: options)
            XCTAssertEqual(response.data.id, "org_1")
            XCTAssertEqual(response.data.isFilteredModelCatalogEnabled, value)
          }
        }
      }
    }
  }

  func testTypedErrorsAndMissingKey() async throws {
    for alias in [false, true] {
      for update in [false, true] {
        for status in update ? [400, 401, 403, 404, 500] : [401, 403, 404, 500] {
          var options = RequestOptions(extraHeaders: ["X-Test-Status": String(status)])
          options.retries = RetryPolicy.none
          do {
            _ = try await call(alias: alias, update: update, options: options)
            XCTFail("Expected API error")
          } catch let error as OpenRouterError {
            guard case .apiError(let actual, let code, let message, _) = error else {
              return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(actual, status)
            XCTAssertEqual(code, status)
            XCTAssertEqual(message, "settings failure")
          }
        }
        do {
          _ = try await call(alias: alias, update: update, key: nil)
          XCTFail("Expected missing key")
        } catch let error as OpenRouterError {
          guard case .missingAPIKey = error else { return XCTFail("Unexpected error: \(error)") }
        }
      }
    }
  }

  func testMalformedJSONMapsToDecodingFailed() async throws {
    for alias in [false, true] {
      for update in [false, true] {
        do {
          _ = try await call(
            alias: alias, update: update,
            options: RequestOptions(extraHeaders: ["X-Malformed": "true"]))
          XCTFail("Expected decoding failure")
        } catch let error as OpenRouterError {
          guard case .decodingFailed = error else { return XCTFail("Unexpected error: \(error)") }
        }
      }
    }
  }

  func testRequiredFieldsAndRoundTrips() throws {
    for value in [false, true] {
      let settings = OrganizationSettings(id: "org_1", isFilteredModelCatalogEnabled: value)
      let response = OrganizationSettingsResponse(data: settings)
      let request = UpdateOrganizationSettingsRequest(isFilteredModelCatalogEnabled: value)
      let encoder = JSONEncoder()
      let decoder = JSONDecoder()
      XCTAssertEqual(
        try decoder.decode(OrganizationSettings.self, from: encoder.encode(settings)), settings)
      XCTAssertEqual(
        try decoder.decode(OrganizationSettingsResponse.self, from: encoder.encode(response)),
        response)
      XCTAssertEqual(
        try decoder.decode(UpdateOrganizationSettingsRequest.self, from: encoder.encode(request)),
        request)
      let object = try XCTUnwrap(
        JSONSerialization.jsonObject(with: encoder.encode(request)) as? [String: Bool])
      XCTAssertEqual(object, ["is_filtered_model_catalog_enabled": value])
    }
    for invalid in [
      "{}", #"{"is_filtered_model_catalog_enabled":null}"#,
      #"{"is_filtered_model_catalog_enabled":"false"}"#,
      #"{"is_filtered_model_catalog_enabled":0}"#,
    ] {
      XCTAssertThrowsError(
        try JSONDecoder().decode(UpdateOrganizationSettingsRequest.self, from: Data(invalid.utf8)))
      let withID = "{\"id\":\"org_1\"," + invalid.dropFirst()
      XCTAssertThrowsError(
        try JSONDecoder().decode(OrganizationSettings.self, from: Data(withID.utf8)))
    }
    for id in ["", "\"id\":null,", "\"id\":3,"] {
      let json = "{\(id)\"is_filtered_model_catalog_enabled\":false}"
      XCTAssertThrowsError(
        try JSONDecoder().decode(OrganizationSettings.self, from: Data(json.utf8)))
    }
    for invalid in ["{}", #"{"data":null}"#, #"{"data":false}"#] {
      XCTAssertThrowsError(
        try JSONDecoder().decode(OrganizationSettingsResponse.self, from: Data(invalid.utf8)))
    }
  }
}

private final class OrganizationSettingsURLProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer settings-key")
      XCTAssertNil(url.query)
      let overridden = request.value(forHTTPHeaderField: "X-Custom") != nil
      XCTAssertEqual(
        url.path, overridden ? "/custom/organization/settings" : "/api/v1/organization/settings")
      if overridden {
        XCTAssertEqual(url.host, "settings.invalid")
        XCTAssertEqual(request.timeoutInterval, 17)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "override")
      }
      if let method = request.value(forHTTPHeaderField: "X-Expected-Method") {
        XCTAssertEqual(request.httpMethod, method)
      }
      let value = request.value(forHTTPHeaderField: "X-Expected-Value") == "true"
      if request.httpMethod == "PATCH" {
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        var body = request.httpBody
        if body == nil, let stream = request.httpBodyStream {
          stream.open()
          defer { stream.close() }
          var data = Data()
          var buffer = [UInt8](repeating: 0, count: 1024)
          while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(contentsOf: buffer.prefix(count))
          }
          body = data
        }
        let object = try JSONSerialization.jsonObject(with: XCTUnwrap(body)) as? [String: Bool]
        XCTAssertEqual(object, ["is_filtered_model_catalog_enabled": value])
      } else {
        XCTAssertNil(request.httpBody)
        XCTAssertNil(request.httpBodyStream)
      }
      let status = Int(request.value(forHTTPHeaderField: "X-Test-Status") ?? "200") ?? 200
      let object: [String: Any] =
        status == 200
        ? ["data": ["id": "org_1", "is_filtered_model_catalog_enabled": value]]
        : ["error": ["code": status, "message": "settings failure"]]
      let data =
        request.value(forHTTPHeaderField: "X-Malformed") == "true"
        ? Data("{".utf8) : try JSONSerialization.data(withJSONObject: object)
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: url, statusCode: status, httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]))
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
