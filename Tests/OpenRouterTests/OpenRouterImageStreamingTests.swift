import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterImageStreamingTests: XCTestCase {
  func testAllRequestFieldsAndOptionsReachWire() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ImageStreamingURLProtocol.self]
    let client = OpenRouterClient(
      apiKey: "offline", session: URLSession(configuration: configuration))
    let stream = client.createImageStream(
      ImageStreamingURLProtocol.fullRequest,
      options: .init(
        timeout: 17, baseURL: URL(string: "https://images.invalid/custom")!,
        extraHeaders: ["X-Scenario": "full", "X-Custom": "preserved"]))
    var count = 0
    for try await _ in stream { count += 1 }
    XCTAssertEqual(count, 1)
  }

  func testRepeatedArbitraryPartialIndicesAndMultipleCompletions() async throws {
    let result = try await events("partials")
    XCTAssertEqual(result.map(\.partialImageIndex), [99, 99, 3, nil, nil])
    XCTAssertEqual(
      result.suffix(2).map(\.type), Array(repeating: "image_generation.completed", count: 2))
  }

  private func events(_ scenario: String, alias: Bool = false) async throws
    -> [ImageGenerationStreamEvent]
  {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ImageStreamingURLProtocol.self]
    let client = OpenRouterClient(
      apiKey: "offline", session: URLSession(configuration: configuration))
    let request = ImageGenerationRequest(model: "test/image", prompt: "雪", n: 7, seed: Int.max)
    let options = RequestOptions(extraHeaders: ["X-Scenario": scenario])
    let stream =
      alias
      ? client.images.stream(request, options: options)
      : client.createImageStream(request, options: options)
    var result: [ImageGenerationStreamEvent] = []
    for try await event in stream { result.append(event) }
    return result
  }

  func testCompletedAndDoneWithBytewiseUTF8AndMetadata() async throws {
    let result = try await events("success", alias: true)
    XCTAssertEqual(result.count, 4)
    XCTAssertEqual(result[0].text, "雪")
    XCTAssertEqual(result[0].eventName, "mismatched")
    XCTAssertNil(result[1].eventName)
    XCTAssertEqual(result[2].type, "future")
    XCTAssertEqual(result[3].b64JSON, "second")
  }

  func testIncompleteStreams() async throws {
    for scenario in ["eof", "done", "unknown", "empty", "partial-eof"] {
      do {
        _ = try await events(scenario)
        XCTFail("Expected incomplete stream: \(scenario)")
      } catch let error as ImageGenerationStreamError {
        XCTAssertEqual(error, .incompleteStream)
      }
    }
  }

  func testProviderErrorsIncludingAfterCompletion() async throws {
    for scenario in ["provider", "late-provider"] {
      do {
        _ = try await events(scenario)
        XCTFail("Expected provider error")
      } catch let error as ImageGenerationStreamError {
        guard case .provider(let payload) = error else { return XCTFail("\(error)") }
        XCTAssertEqual(payload.code, "blocked")
        XCTAssertEqual(
          payload.rawPayload, .object(["message": .string("no"), "code": .string("blocked")]))
      }
    }
  }

  func testBufferedJSONPreservesAllImages() async throws {
    let result = try await events("json")
    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result[0].bufferedResponse?.data.count, 2)
    guard case .object(let raw) = result[0].rawPayload else { return XCTFail("Missing raw root") }
    XCTAssertEqual(raw["future"], .bool(true))
    XCTAssertEqual(result[0].rawPayload, result[0].bufferedResponse?.rawPayload)
  }

  func testMalformedPayloadsFail() async throws {
    for scenario in ["malformed", "required", "bad-json", "empty-json", "sse-buffered"] {
      do {
        _ = try await events(scenario)
        XCTFail("Expected decoding error: \(scenario)")
      } catch {
        XCTAssertTrue(error is DecodingError, "\(error)")
      }
    }
  }

  func testHTTPErrorsRetainStatusAndBody() async throws {
    for status in [401, 402, 429, 500] {
      do {
        _ = try await events(String(status))
        XCTFail("Expected HTTP error")
      } catch let error as OpenRouterError {
        guard case .apiError(let actual, _, _, let raw) = error else { return XCTFail("\(error)") }
        XCTAssertEqual(actual, status)
        XCTAssertNotNil(raw)
      }
    }
  }

  func testNetworkErrorIsNotReplacedByIncomplete() async throws {
    do {
      _ = try await events("network")
      XCTFail("Expected network error")
    } catch let error as URLError {
      XCTAssertEqual(error.code, .networkConnectionLost)
    }
  }

  func testCancellationStopsHeldOpenTask() async throws {
    let stopped = expectation(description: "URL task stopped")
    let observer = NotificationCenter.default.addObserver(
      forName: ImageStreamingURLProtocol.stopped, object: nil, queue: nil
    ) { _ in stopped.fulfill() }
    defer { NotificationCenter.default.removeObserver(observer) }
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ImageStreamingURLProtocol.self]
    let client = OpenRouterClient(
      apiKey: "offline", session: URLSession(configuration: configuration))
    let stream = client.createImageStream(
      .init(model: "test/image", prompt: "cancel"),
      options: .init(extraHeaders: ["X-Scenario": "hold"]))
    let received = expectation(description: "partial received")
    let consumer = Task {
      do {
        for try await _ in stream { received.fulfill() }
        try Task.checkCancellation()
        XCTFail("Expected cancellation")
      } catch {
        XCTAssertTrue(Task.isCancelled)
      }
    }
    await fulfillment(of: [received], timeout: 2)
    consumer.cancel()
    await consumer.value
    await fulfillment(of: [stopped], timeout: 2)
  }
}

private final class ImageStreamingURLProtocol: URLProtocol {
  static var fullRequest: ImageGenerationRequest {
    ImageGenerationRequest(
      model: "studio/image", prompt: "雪", aspectRatio: "16:9", background: "transparent",
      inputReferences: [
        .init(url: "https://reference.invalid/image.png"), .init(url: "data:image/png;base64,cG5n"),
      ],
      n: 7, outputCompression: 80, outputFormat: "png",
      provider: .init(
        only: ["studio"], ignore: ["other"], order: ["studio"], allowFallbacks: false,
        sort: .object(["by": .string("price")]), options: ["studio": ["steps": .number(20)]]),
      quality: "high", resolution: "2K", seed: Int.max, sessionID: "session", size: "1536x1024",
      trace: ["tag": .string("offline")], user: "user")
  }

  private func requestBody() throws -> Data {
    if let body = request.httpBody { return body }
    let stream = try XCTUnwrap(request.httpBodyStream, "Missing HTTP request body")
    stream.open()
    defer { stream.close() }
    var result = Data()
    var buffer = [UInt8](repeating: 0, count: 4096)
    while true {
      let count = stream.read(&buffer, maxLength: buffer.count)
      if count < 0 { throw stream.streamError ?? URLError(.cannotDecodeContentData) }
      if count == 0 { return result }
      result.append(contentsOf: buffer.prefix(count))
    }
  }

  static let stopped = Notification.Name("ImageStreamingURLProtocol.stopped")
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    XCTAssertEqual(
      request.value(forHTTPHeaderField: "Accept"), "text/event-stream, application/json")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer offline")
    do {
      let body = try requestBody()
      let text = String(decoding: body, as: UTF8.self)
      XCTAssertTrue(text.contains("\"stream\":true"))
      if request.value(forHTTPHeaderField: "X-Scenario") != "hold" {
        XCTAssertTrue(text.contains(String(Int.max)))
      }
      if request.value(forHTTPHeaderField: "X-Scenario") == "full" {
        XCTAssertEqual(request.url?.absoluteString, "https://images.invalid/custom/images")
        XCTAssertEqual(request.timeoutInterval, 17)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "preserved")
        var wire = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        var buffered = try XCTUnwrap(
          JSONSerialization.jsonObject(with: JSONEncoder().encode(Self.fullRequest))
            as? [String: Any])
        XCTAssertEqual(wire.removeValue(forKey: "stream") as? Bool, true)
        XCTAssertEqual(buffered.removeValue(forKey: "stream") as? Bool, false)
        XCTAssertEqual((wire["seed"] as? NSNumber)?.int64Value, Int64(Int.max))
        XCTAssertEqual(wire as NSDictionary, buffered as NSDictionary)
      }
    } catch {
      XCTFail("Unable to inspect request body: \(error)")
    }
    let scenario = request.value(forHTTPHeaderField: "X-Scenario") ?? ""
    let completed =
      "data: {\"data\":{\"type\":\"image_generation.completed\",\"b64_json\":\"first\",\"created\":1}}\r\n\r\n"
    let provider =
      "data: {\"data\":{\"type\":\"error\",\"error\":{\"message\":\"no\",\"code\":\"blocked\"}}}\n\n"
    let unknown = "data: {\"data\":{\"type\":\"future\"}}\n\n"
    let json =
      "{\"created\":1,\"data\":[{\"b64_json\":\"one\"},{\"b64_json\":\"two\"}],\"future\":true}"
    let done = "data: [DONE]\n\n"
    let partial =
      "data: {\"data\":{\"type\":\"image_generation.partial_image\",\"partial_image_index\":99,\"b64_json\":\"partial\"}}\n\n"
    let body: String
    switch scenario {
    case "success":
      body =
        "event: mismatched\r\ndata: {\"data\":\r\ndata: {\"type\":\"image_generation.text_chunk\",\"text\":\"雪\",\"phase\":\"thinking\"}}\r\n\r\n"
        + completed + unknown + completed.replacingOccurrences(of: "first", with: "second") + done
    case "eof": body = completed
    case "full": body = completed + done
    case "partials":
      body =
        partial + partial + partial.replacingOccurrences(of: "99", with: "3") + completed
        + completed + done
    case "partial-eof": body = partial
    case "done": body = done
    case "unknown": body = unknown + done
    case "provider": body = provider
    case "late-provider": body = completed + provider
    case "json": body = json
    case "sse-buffered": body = "data: \(json)\n\n"
    case "bad-json", "malformed": body = scenario == "bad-json" ? "{" : "data: {\n\n"
    case "required": body = "data: {\"data\":{\"type\":\"image_generation.completed\"}}\n\n"
    case "network", "hold": body = partial
    default: body = Int(scenario) == nil ? "" : "{\"error\":{\"message\":\"denied\",\"code\":401}}"
    }
    let response = HTTPURLResponse(
      url: request.url!, statusCode: Int(scenario) ?? 200, httpVersion: nil,
      headerFields: [
        "Content-Type": scenario.contains("json")
          ? "application/JSON; charset=utf-8" : "text/event-stream"
      ])!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    for byte in body.utf8 { client?.urlProtocol(self, didLoad: Data([byte])) }
    if scenario == "hold" { return }
    if scenario == "network" {
      client?.urlProtocol(self, didFailWithError: URLError(.networkConnectionLost))
    } else {
      client?.urlProtocolDidFinishLoading(self)
    }
  }

  override func stopLoading() {
    if request.value(forHTTPHeaderField: "X-Scenario") == "hold" {
      NotificationCenter.default.post(name: Self.stopped, object: nil)
    }
  }
}
