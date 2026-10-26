import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterImageDiscoveryTests: XCTestCase {
  private func client(key: String = "image-discovery-key") -> OpenRouterClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ImageDiscoveryURLProtocol.self]
    return OpenRouterClient(apiKey: key, session: URLSession(configuration: configuration))
  }

  private func invoke(
    _ client: OpenRouterClient, endpoints: Bool, alias: Bool,
    author: String = "studio", slug: String = "image-model", options: RequestOptions? = nil
  ) async throws -> JSONValue {
    if endpoints {
      let result =
        try await
        (alias
        ? client.images.models.endpoints(author: author, slug: slug, options: options)
        : client.listImageModelEndpoints(author: author, slug: slug, options: options))
      return result.rawPayload
    }
    let result =
      try await
      (alias
      ? client.images.models.list(options: options)
      : client.listImageModels(options: options))
    return result.rawPayload
  }

  func testFlatAndNestedDiscoveryPreserveFullPayloadAndEmptyCollections() async throws {
    for endpoints in [false, true] {
      for alias in [false, true] {
        for empty in [false, true] {
          let options = RequestOptions(extraHeaders: ["X-Empty": String(empty)])
          let result = try await invoke(
            client(), endpoints: endpoints, alias: alias, options: options)
          let expected = try JSONDecoder().decode(
            JSONValue.self, from: ImageDiscoveryURLProtocol.body(endpoints: endpoints, empty: empty)
          )
          XCTAssertEqual(result, expected)
        }
      }
    }
    let models = try await client().images.models.list()
    let item = try XCTUnwrap(models.data.first)
    XCTAssertEqual(item.id, "studio/image-model")
    XCTAssertEqual(item.architecture.inputModalities, ["text", "image"])
    XCTAssertEqual(item.architecture.outputModalities, ["image"])
    XCTAssertFalse(item.supportsStreaming)
    XCTAssertEqual(item.supportedParameters.count, 4)
    let response = try await client().images.models.endpoints(author: "studio", slug: "image-model")
    let endpoint = try XCTUnwrap(response.endpoints.first)
    XCTAssertNil(endpoint.providerTag)
    XCTAssertEqual(endpoint.providerName, "Studio")
    XCTAssertEqual(endpoint.providerSlug, "studio")
    XCTAssertEqual(endpoint.allowedPassthroughParameters, ["seed", "future_option"])
    XCTAssertEqual(endpoint.pricing.first?.costUSD, 0.05)
    XCTAssertEqual(endpoint.pricing.first?.variant, "high")
  }

  func testOptionsAndIndependentlyEscapedSegments() async throws {
    for endpoints in [false, true] {
      for alias in [false, true] {
        let path =
          endpoints
          ? "/custom/images/models/a%2Fb%3F%23%25%E9%9B%AA/c%2Fd%3F%23%25%C3%A9/endpoints"
          : "/custom/images/models"
        var options = RequestOptions(extraHeaders: [
          "X-Path": path, "X-Custom": "preserved", "Accept": "application/custom+json",
        ])
        options.baseURL = URL(string: "https://image-discovery.invalid/custom")!
        options.timeout = 17
        _ = try await invoke(
          client(), endpoints: endpoints, alias: alias, author: "a/b?#%雪", slug: "c/d?#%é",
          options: options)
      }
    }
  }

  func testErrorsAreMappedThroughBothAPIs() async throws {
    for endpoints in [false, true] {
      for alias in [false, true] {
        for status in endpoints ? [401, 403, 404, 500] : [401, 403, 500] {
          do {
            _ = try await invoke(
              client(), endpoints: endpoints, alias: alias,
              options: RequestOptions(extraHeaders: ["X-Status": String(status)]))
            XCTFail("Expected API error")
          } catch let error as OpenRouterError {
            guard case .apiError(let actual, let code, let message, _) = error else {
              return XCTFail("Unexpected: \(error)")
            }
            XCTAssertEqual(actual, status)
            XCTAssertEqual(code, status)
            XCTAssertEqual(message, "discovery failure")
          }
        }
      }
    }
  }

  func testMissingRequiredFieldsAndMalformedJSONFailDecoding() async throws {
    for endpoints in [false, true] {
      for alias in [false, true] {
        for invalid in ["root", "item", "malformed"] {
          do {
            _ = try await invoke(
              client(), endpoints: endpoints, alias: alias,
              options: RequestOptions(extraHeaders: ["X-Invalid": invalid]))
            XCTFail("Expected decoding failure")
          } catch let error as OpenRouterError {
            guard case .decodingFailed = error else { return XCTFail("Unexpected: \(error)") }
          }
        }
      }
    }
  }

  func testMissingKeyNeverDispatches() async throws {
    let dispatch = expectation(description: "No discovery dispatch without key")
    dispatch.isInverted = true
    let token = UUID().uuidString
    let observer = NotificationCenter.default.addObserver(
      forName: ImageDiscoveryURLProtocol.dispatched, object: nil, queue: nil
    ) { notification in
      if notification.userInfo?["token"] as? String == token { dispatch.fulfill() }
    }
    defer { NotificationCenter.default.removeObserver(observer) }
    for endpoints in [false, true] {
      for alias in [false, true] {
        do {
          _ = try await invoke(
            client(key: ""), endpoints: endpoints, alias: alias,
            options: RequestOptions(extraHeaders: ["X-Token": token]))
          XCTFail("Expected missing key")
        } catch let error as OpenRouterError {
          guard case .missingAPIKey = error else { return XCTFail("Unexpected: \(error)") }
        }
      }
    }
    await fulfillment(of: [dispatch], timeout: 0.05)
  }
}

private final class ImageDiscoveryURLProtocol: URLProtocol {
  static let dispatched = Notification.Name("OpenRouterImageDiscoveryTests.dispatched")

  static func body(endpoints: Bool, empty: Bool) throws -> Data {
    let capabilities: [String: Any] = [
      "resolution": ["type": "enum", "values": ["1K", "2K", "4K"]],
      "steps": ["type": "range", "min": 1, "max": 50],
      "enhance": ["type": "boolean"],
      "future_capability": ["type": "future", "nested": ["enabled": true]],
    ]
    if endpoints {
      return try JSONSerialization.data(withJSONObject: [
        "id": "studio/image-model", "future_root": true,
        "endpoints": empty
          ? []
          : [
            [
              "provider_name": "Studio", "provider_slug": "studio", "provider_tag": NSNull(),
              "supported_parameters": capabilities, "supports_streaming": false,
              "allowed_passthrough_parameters": ["seed", "future_option"],
              "pricing": [
                ["billable": "output_image", "unit": "image", "cost_usd": 0.05, "variant": "high"]
              ],
              "future_endpoint": 42,
            ]
          ],
      ])
    }
    return try JSONSerialization.data(withJSONObject: [
      "future_root": true,
      "data": empty
        ? []
        : [
          [
            "id": "studio/image-model", "name": "Studio Image",
            "description": "Text and image editing",
            "created": 1_692_901_234,
            "architecture": [
              "input_modalities": ["text", "image"], "output_modalities": ["image"],
            ],
            "supported_parameters": capabilities, "supports_streaming": false,
            // This metadata must never be followed or receive the API key.
            "endpoints": "https://untrusted.invalid/do-not-follow", "future_model": 42,
          ]
        ],
    ])
  }

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    NotificationCenter.default.post(
      name: Self.dispatched, object: nil,
      userInfo: ["token": request.value(forHTTPHeaderField: "X-Token") ?? ""])
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      let endpoints = components.percentEncodedPath.hasSuffix("/endpoints")
      XCTAssertEqual(request.httpMethod, "GET", "Discovery must never dispatch generation POSTs")
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Authorization"), "Bearer image-discovery-key")
      XCTAssertNil(request.httpBody)
      XCTAssertNil(request.httpBodyStream)
      XCTAssertNil(components.query)
      XCTAssertNil(components.fragment)
      XCTAssertEqual(
        components.percentEncodedPath,
        request.value(forHTTPHeaderField: "X-Path")
          ?? (endpoints
            ? "/api/v1/images/models/studio/image-model/endpoints" : "/api/v1/images/models"))
      if request.value(forHTTPHeaderField: "X-Custom") != nil {
        XCTAssertEqual(url.host, "image-discovery.invalid")
        XCTAssertEqual(request.timeoutInterval, 17)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "preserved")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/custom+json")
      } else {
        XCTAssertEqual(url.host, "openrouter.ai")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
      }
      let status = Int(request.value(forHTTPHeaderField: "X-Status") ?? "200") ?? 200
      var data = try Self.body(
        endpoints: endpoints, empty: request.value(forHTTPHeaderField: "X-Empty") == "true")
      switch request.value(forHTTPHeaderField: "X-Invalid") {
      case "root": data = Data("{}".utf8)
      case "item":
        data = Data(
          (endpoints ? #"{"id":"studio/image-model","endpoints":[{}]}"# : #"{"data":[{}]}"#).utf8)
      case "malformed": data = Data("{".utf8)
      default: break
      }
      if status != 200 {
        data = Data("{\"error\":{\"code\":\(status),\"message\":\"discovery failure\"}}".utf8)
      }
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
