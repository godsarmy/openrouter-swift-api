import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterImageGenerationTests: XCTestCase {
  private func client(key: String = "image-key") -> OpenRouterClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [ImageGenerationURLProtocol.self]
    return OpenRouterClient(apiKey: key, session: URLSession(configuration: config))
  }

  private func invoke(
    alias: Bool, full: Bool = false, options: RequestOptions? = nil, key: String = "image-key"
  ) async throws -> ImageGenerationResponse {
    let request: ImageGenerationRequest
    if full {
      request = ImageGenerationRequest(
        model: "studio/image", prompt: "A snowy mountain", aspectRatio: "16:9",
        background: "transparent",
        inputReferences: [
          .init(url: "https://reference.invalid/image.png"),
          .init(url: "data:image/png;base64,cG5n"),
        ],
        n: 2, outputCompression: 80, outputFormat: "png",
        provider: .init(
          only: ["studio"], ignore: ["other"], order: ["studio"], allowFallbacks: false,
          sort: .object(["by": .string("price")]),
          options: ["studio": ["steps": .number(20)]]),
        quality: "high", resolution: "2K", seed: 42, sessionID: "session",
        size: "1536x1024", trace: ["tag": .string("offline")], user: "user")
    } else {
      request = ImageGenerationRequest(model: "studio/image", prompt: "A snowy mountain")
    }
    let client = client(key: key)
    return try await
      (alias
      ? client.images.create(request, options: options)
      : client.createImage(request, options: options))
  }

  func testMinimalAndFullRequestsThroughBothAPIs() async throws {
    for alias in [false, true] {
      for full in [false, true] {
        var options = RequestOptions(extraHeaders: ["X-Full": String(full)])
        if full {
          options.baseURL = URL(string: "https://images.invalid/custom")!
          options.timeout = 17
          options.extraHeaders["X-Custom"] = "preserved"
        }
        let response = try await invoke(alias: alias, full: full, options: options)
        XCTAssertEqual(response.created, 123)
        XCTAssertEqual(response.data.count, 1, "n is only an upper bound")
        XCTAssertEqual(response.data.first?.b64JSON, "cG5n")
        XCTAssertEqual(
          response.rawPayload,
          try JSONDecoder().decode(
            JSONValue.self, from: ImageGenerationURLProtocol.body(variant: "default")))
      }
    }
  }

  func testMediaTypesUsageAndUnknownMetadataArePreservedWithoutDownloads() async throws {
    for variant in ["image/png", "image/jpeg", "image/webp", "image/svg+xml", "absent", "null"] {
      let result = try await invoke(
        alias: true, options: RequestOptions(extraHeaders: ["X-Variant": variant]))
      XCTAssertEqual(result.data.first?.mediaType, variant.contains("/") ? variant : nil)
      if variant == "absent" || variant == "null" {
        XCTAssertNil(result.usage)
      } else {
        XCTAssertEqual(result.usage?.promptTokens, 3)
        XCTAssertEqual(result.usage?.completionTokens, 4)
        XCTAssertEqual(result.usage?.totalTokens, 7)
        XCTAssertEqual(result.usage?.cost, variant == "image/png" ? 0.04 : nil)
      }
      XCTAssertEqual(
        result.rawPayload,
        try JSONDecoder().decode(
          JSONValue.self, from: ImageGenerationURLProtocol.body(variant: variant)))
    }
  }

  func testMalformedAndSSEBodiesFailDecoding() async throws {
    for alias in [false, true] {
      for invalid in ["missing", "image", "malformed", "sse"] {
        do {
          _ = try await invoke(alias: alias, options: .init(extraHeaders: ["X-Invalid": invalid]))
          XCTFail("Expected decoding failure")
        } catch let error as OpenRouterError {
          guard case .decodingFailed = error else { return XCTFail("Unexpected: \(error)") }
        }
      }
    }
  }

  func testConventionalErrorsAndNoRetriesByDefault() async throws {
    for alias in [false, true] {
      for status in [400, 401, 402, 403, 404, 413, 429, 500, 502, 524, 529] {
        let dispatch = expectation(description: "Single dispatch")
        dispatch.assertForOverFulfill = true
        let token = UUID().uuidString
        let observer = NotificationCenter.default.addObserver(
          forName: ImageGenerationURLProtocol.dispatched, object: nil, queue: nil
        ) { note in
          if note.userInfo?["token"] as? String == token { dispatch.fulfill() }
        }
        defer { NotificationCenter.default.removeObserver(observer) }
        do {
          _ = try await invoke(
            alias: alias,
            options: .init(extraHeaders: [
              "X-Status": String(status), "X-Token": token,
            ]))
          XCTFail("Expected API error")
        } catch let error as OpenRouterError {
          guard case .apiError(let actual, let code, let message, let rawBody) = error else {
            return XCTFail("Unexpected: \(error)")
          }
          XCTAssertEqual(actual, status)
          XCTAssertEqual(code, status)
          XCTAssertEqual(message, "size conflict")
          XCTAssertNotNil(rawBody)
        }
        await fulfillment(of: [dispatch], timeout: 0.05)
      }
    }
  }

  func testMissingAPIKeyNeverDispatches() async throws {
    let dispatch = expectation(description: "No dispatch")
    dispatch.isInverted = true
    let token = UUID().uuidString
    let observer = NotificationCenter.default.addObserver(
      forName: ImageGenerationURLProtocol.dispatched, object: nil, queue: nil
    ) { note in
      if note.userInfo?["token"] as? String == token { dispatch.fulfill() }
    }
    defer { NotificationCenter.default.removeObserver(observer) }
    for alias in [false, true] {
      do {
        _ = try await invoke(
          alias: alias, options: .init(extraHeaders: ["X-Token": token]), key: "")
        XCTFail("Expected missing key")
      } catch let error as OpenRouterError {
        guard case .missingAPIKey = error else { return XCTFail("Unexpected: \(error)") }
      }
    }
    await fulfillment(of: [dispatch], timeout: 0.05)
  }
}

private final class ImageGenerationURLProtocol: URLProtocol {
  static let dispatched = Notification.Name("OpenRouterImageGenerationTests.dispatched")

  static func body(variant: String) throws -> Data {
    var image: [String: Any] = [
      "b64_json": "cG5n", "future_image": true,
      "url": "https://untrusted.invalid/never-download",
    ]
    if variant.contains("/") { image["media_type"] = variant }
    var body: [String: Any] = ["created": 123, "data": [image], "future_root": ["enabled": true]]
    if variant == "null" {
      body["usage"] = NSNull()
    } else if variant != "absent" {
      var usage: [String: Any] = [
        "prompt_tokens": 3, "completion_tokens": 4, "total_tokens": 7, "future_usage": true,
      ]
      if variant == "image/png" {
        usage["cost"] = 0.04
      } else if variant != "default" {
        usage["cost"] = NSNull()
      }
      body["usage"] = usage
    }
    return try JSONSerialization.data(withJSONObject: body)
  }

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    NotificationCenter.default.post(
      name: Self.dispatched, object: nil,
      userInfo: [
        "token": request.value(forHTTPHeaderField: "X-Token") ?? ""
      ])
    do {
      let url = try XCTUnwrap(request.url)
      let full = request.value(forHTTPHeaderField: "X-Full") == "true"
      XCTAssertEqual(url.host, full ? "images.invalid" : "openrouter.ai")
      XCTAssertEqual(url.path, full ? "/custom/images" : "/api/v1/images")
      XCTAssertNil(url.query)
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer image-key")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
      if full {
        XCTAssertEqual(request.timeoutInterval, 17)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "preserved")
      }
      var data = request.httpBody
      if data == nil, let stream = request.httpBodyStream {
        stream.open()
        defer { stream.close() }
        var bytes = [UInt8](repeating: 0, count: 4096)
        var buffer = Data()
        while stream.hasBytesAvailable {
          let count = stream.read(&bytes, maxLength: bytes.count)
          if count <= 0 { break }
          buffer.append(contentsOf: bytes.prefix(count))
        }
        data = buffer
      }
      let actual = try JSONSerialization.jsonObject(with: XCTUnwrap(data)) as? NSDictionary
      var expected: [String: Any] = [
        "model": "studio/image", "prompt": "A snowy mountain", "stream": false,
      ]
      if full {
        expected.merge([
          "aspect_ratio": "16:9", "background": "transparent", "n": 2,
          "output_compression": 80, "output_format": "png", "quality": "high",
          "resolution": "2K", "seed": 42, "session_id": "session", "size": "1536x1024",
          "trace": ["tag": "offline"], "user": "user",
          "input_references": [
            ["type": "image_url", "image_url": ["url": "https://reference.invalid/image.png"]],
            ["type": "image_url", "image_url": ["url": "data:image/png;base64,cG5n"]],
          ],
          "provider": [
            "only": ["studio"], "ignore": ["other"], "order": ["studio"],
            "allow_fallbacks": false, "sort": ["by": "price"],
            "options": ["studio": ["steps": 20]],
          ],
        ]) { _, new in new }
      }
      XCTAssertEqual(actual, expected as NSDictionary)
      let status = Int(request.value(forHTTPHeaderField: "X-Status") ?? "200") ?? 200
      var responseBody = try Self.body(
        variant: request.value(forHTTPHeaderField: "X-Variant") ?? "default")
      let invalid = request.value(forHTTPHeaderField: "X-Invalid")
      switch invalid {
      case "missing": responseBody = Data("{}".utf8)
      case "image": responseBody = Data(#"{"created":123,"data":[{}]}"#.utf8)
      case "malformed": responseBody = Data("{".utf8)
      case "sse": responseBody = Data("data: {\"created\":123,\"data\":[]}\n\n".utf8)
      default: break
      }
      if status != 200 {
        responseBody = Data("{\"error\":{\"code\":\(status),\"message\":\"size conflict\"}}".utf8)
      }
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: url, statusCode: status, httpVersion: nil,
          headerFields: [
            "Content-Type": invalid == "sse" ? "text/event-stream" : "application/json"
          ]))
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: responseBody)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
