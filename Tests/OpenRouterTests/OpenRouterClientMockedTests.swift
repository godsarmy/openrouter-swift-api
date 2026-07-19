import Foundation
import XCTest

@testable import OpenRouter

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterClientMockedTests: XCTestCase {
  override class func setUp() {
    super.setUp()
    URLProtocolStub.register()
  }

  override class func tearDown() {
    URLProtocolStub.unregister()
    super.tearDown()
  }

  func testCreateChatCompletionUsesMockedTransport() async throws {
    let fixture = try fixtureData(named: "chat_completion_success.json")
    URLProtocolStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/v1/chat/completions")
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!
      return (response, fixture)
    }

    let client = makeClient()
    let response = try await client.createChatCompletion(
      ChatCompletionRequest(model: "openai/gpt-4o-mini", messages: [.user("hi")]))

    XCTAssertEqual(response.id, "chatcmpl-test-1")
    XCTAssertEqual(response.choices.first?.message.content, .text("Hello from fixture"))
  }

  func testCreateChatCompletionMapsAPIError() async throws {
    let fixture = try fixtureData(named: "api_error_429.json")
    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 429,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!
      return (response, fixture)
    }

    let client = makeClient()

    do {
      _ = try await client.createChatCompletion(
        ChatCompletionRequest(model: "openai/gpt-4o-mini", messages: [.user("hi")]))
      XCTFail("Expected error")
    } catch let error as OpenRouterError {
      guard case .apiError(let status, let code, let message, _) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(status, 429)
      XCTAssertEqual(code, 429)
      XCTAssertEqual(message, "rate limited")
    }
  }

  func testCreateChatCompletionStreamSessionIncludesCacheMetadata() async throws {
    let streamBody = """
      data: {"id":"chunk-1","model":"openai/gpt-4o-mini","choices":[{"index":0,"delta":{"content":"hello"},"finish_reason":null}]}
      data: [DONE]
      """.data(using: .utf8)!

    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: [
          "Content-Type": "text/event-stream",
          "X-OpenRouter-Cache-Status": "HIT",
          "X-OpenRouter-Cache-Age": "3",
          "X-OpenRouter-Cache-TTL": "297",
          "X-Generation-Id": "gen_stream_1",
        ]
      )!
      return (response, streamBody)
    }

    let client = makeClient()
    let session = try await client.createChatCompletionStreamSession(
      ChatCompletionRequest(model: "openai/gpt-4o-mini", messages: [.user("hi")], stream: true)
    )

    XCTAssertEqual(session.responseCacheMetadata?.status, "HIT")
    XCTAssertEqual(session.responseCacheMetadata?.ageSeconds, 3)
    XCTAssertEqual(session.responseCacheMetadata?.ttlSeconds, 297)
    XCTAssertEqual(session.responseCacheMetadata?.generationID, "gen_stream_1")

    var got = ""
    for try await chunk in session.stream {
      got += chunk.choices.first?.delta?.content ?? ""
    }
    XCTAssertEqual(got, "hello")
  }

  func testCreateResponseStreamForcesStreamAndYieldsEventsInOrder() async throws {
    let streamBody = """
      data: {"type":"response.output_text.delta","delta":"Hello","response_id":"resp_1","output_index":0,"content_index":0}
      data: {"type":"response.content_part.delta","delta":" world","response_id":"resp_1"}
      data: {"type":"response.function_call_arguments.delta","delta":"{\\"city\\":\\"Paris\\"}","item_id":"call_1","output_index":1}
      data: {"type":"response.completed","response":{"id":"resp_1","output":[],"status":"completed"}}
      data: [DONE]
      """.data(using: .utf8)!

    URLProtocolStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/v1/responses")
      let body = try XCTUnwrap(request.httpBody)
      let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
      XCTAssertEqual(json["stream"] as? Bool, true)
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (response, streamBody)
    }

    let stream = makeClient().createResponseStream(
      .init(model: "m", input: .text("hi"), stream: false))
    var events: [ResponsesStreamEvent] = []
    for try await event in stream { events.append(event) }

    XCTAssertEqual(
      events.map(\.type),
      [
        "response.output_text.delta", "response.content_part.delta",
        "response.function_call_arguments.delta", "response.completed",
      ])
    XCTAssertEqual(events[0].delta, "Hello")
    XCTAssertEqual(events[1].delta, " world")
    XCTAssertEqual(events[2].delta, #"{"city":"Paris"}"#)
    XCTAssertEqual(events[3].response?.status, "completed")
  }

  func testCreateResponseStreamThrowsForErrorEvent() async throws {
    let streamBody =
      "data: {\"type\":\"response.failed\",\"response\":{\"error\":{\"code\":400,\"message\":\"invalid input\"}}}\r\n\r\ndata: [DONE]\r\n\r\n"
      .data(using: .utf8)!
    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (response, streamBody)
    }

    do {
      for try await _ in makeClient().createResponseStream(.init(model: "m", input: .text("hi"))) {}
      XCTFail("Expected stream error")
    } catch let error as OpenRouterError {
      guard case .apiError(_, let code, let message, _) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(code, 400)
      XCTAssertEqual(message, "invalid input")
    }
  }

  func testCreateResponseStreamDecodesMultilineSSEFrame() async throws {
    let streamBody = """
      event: response.output_text.delta\r
      data: {"type":"response.output_text.delta",\r
      data: "delta":"hello"}\r
      \r
      data: [DONE]\r
      \r
      """.data(using: .utf8)!
    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (response, streamBody)
    }

    var events: [ResponsesStreamEvent] = []
    for try await event in makeClient().createResponseStream(.init(model: "m", input: .text("hi")))
    {
      events.append(event)
    }
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events.first?.type, "response.output_text.delta")
    XCTAssertEqual(events.first?.delta, "hello")
  }

  func testCreateMessageStreamUsesNamedEventsAndMapsErrors() async throws {
    let streamBody = """
      event: message_start
      data: {"type":"message_start","message":{"id":"m1","role":"assistant","content":[]}}

      event: content_block_delta
      data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hi"},"future":true}

      event: content_block_delta
      data: {"type":"content_block_delta","delta":{"type":"input_json_delta","partial_json":"{\\\"x\\\":1"}}

      event: content_block_delta
      data: {"type":"content_block_delta","delta":{"type":"thinking_delta","thinking":"reason"}}

      event: content_block_delta
      data: {"type":"content_block_delta","delta":{"type":"signature_delta","signature":"sig"}}

      data: [DONE]

      """.data(using: .utf8)!
    URLProtocolStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/v1/messages")
      let body = try XCTUnwrap(request.httpBody)
      XCTAssertEqual(
        (try JSONSerialization.jsonObject(with: body) as? [String: Any])?["stream"] as? Bool, true)
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"])!
      return (response, streamBody)
    }
    var events: [MessagesStreamEvent] = []
    for try await event in makeClient().createMessageStream(
      .init(model: "m", messages: [.init(role: .user, content: .text("hi"))], maxTokens: 10))
    { events.append(event) }
    XCTAssertEqual(
      events.map(\.eventName),
      [
        "message_start", "content_block_delta", "content_block_delta", "content_block_delta",
        "content_block_delta",
      ])
    XCTAssertEqual(
      events[1].delta, .object(["type": .string("text_delta"), "text": .string("Hi")]))
    XCTAssertEqual(
      events[1].rawPayload,
      .object([
        "type": .string("content_block_delta"), "index": .number(0),
        "delta": .object(["type": .string("text_delta"), "text": .string("Hi")]),
        "future": .bool(true),
      ]))
    XCTAssertEqual(events[2].inputJSONDelta, #"{"x":1"#)
    XCTAssertEqual(events[3].thinkingDelta, "reason")
    XCTAssertEqual(events[4].signatureDelta, "sig")
  }

  func testCreateMessageStreamThrowsForErrorEvent() async throws {
    let streamBody =
      "event: error\ndata: {\"type\":\"error\",\"error\":{\"code\":400,\"message\":\"bad message\"}}\n\n"
      .data(using: .utf8)!
    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"])!
      return (response, streamBody)
    }
    do {
      for try await _ in makeClient().createMessageStream(
        .init(model: "m", messages: [.init(role: .user, content: .text("hi"))], maxTokens: 10))
      {}
      XCTFail("Expected stream error")
    } catch let error as OpenRouterError {
      guard case .apiError(_, let code, let message, _) = error else {
        return XCTFail("Unexpected error")
      }
      XCTAssertEqual(code, 400)
      XCTAssertEqual(message, "bad message")
    }
  }

  func testChatStreamStillDecodesNamedSSEFrames() async throws {
    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"])!
      return (
        response,
        "event: chunk\ndata: {\"choices\":[{\"delta\":{\"content\":\"ok\"}}]}\n\ndata: [DONE]\n\n"
          .data(using: .utf8)!
      )
    }
    var output = ""
    for try await chunk in makeClient().createChatCompletionStream(
      .init(model: "m", messages: [.user("hi")]))
    { output += chunk.choices.first?.delta?.content ?? "" }
    XCTAssertEqual(output, "ok")
  }

  func testStreamFallbackUsesNextModelOnFallbackableError() async throws {
    let streamBody = """
      data: {"id":"chunk-1","model":"fallback-model","choices":[{"index":0,"delta":{"content":"ok"},"finish_reason":null}]}
      data: [DONE]
      """.data(using: .utf8)!

    URLProtocolStub.handler = { request in
      let payload = try XCTUnwrap(request.httpBody)
      let json = try XCTUnwrap(JSONSerialization.jsonObject(with: payload) as? [String: Any])
      let model = try XCTUnwrap(json["model"] as? String)

      if model == "primary-model" {
        let errorData = #"{"error":{"code":429,"message":"rate limited"}}"#.data(using: .utf8)!
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 429,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )!
        return (response, errorData)
      }

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (response, streamBody)
    }

    let client = makeClient()
    let stream = client.createChatCompletionStreamWithFallback(
      ChatCompletionRequest(model: "primary-model", messages: [.user("hi")]),
      fallbackModels: ["fallback-model"]
    )

    var output = ""
    for try await chunk in stream {
      output += chunk.choices.first?.delta?.content ?? ""
    }
    XCTAssertEqual(output, "ok")
  }

  func testStreamIncludesTerminalUsageChunkWithCost() async throws {
    let streamBody = """
      data: {"id":"chunk-1","choices":[{"index":0,"delta":{"content":"hi"},"finish_reason":null}]}
      data: {"id":"chunk-2","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}
      data: {"id":"chunk-3","choices":[],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15,"cost":0.003}}
      data: [DONE]
      """.data(using: .utf8)!

    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (response, streamBody)
    }

    let client = makeClient()
    let stream = try await client.createChatCompletionStream(
      ChatCompletionRequest(model: "m", messages: [.user("hi")], stream: true)
    )

    var chunks: [ChatCompletionChunk] = []
    for try await chunk in stream { chunks.append(chunk) }

    XCTAssertEqual(chunks.count, 3)
    XCTAssertEqual(chunks.last?.usage?.cost, 0.003)
    XCTAssertEqual(chunks.last?.usage?.totalTokens, 15)
  }

  func testStreamDoesNotTerminateBeforeDoneWhenFinishReasonArrives() async throws {
    let streamBody = """
      data: {"id":"chunk-1","choices":[{"index":0,"delta":{"content":"a"},"finish_reason":null}]}
      data: {"id":"chunk-2","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}
      data: {"id":"chunk-3","choices":[],"usage":{"total_tokens":9,"cost":0.009}}
      data: [DONE]
      """.data(using: .utf8)!

    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (response, streamBody)
    }

    let client = makeClient()
    let stream = try await client.createChatCompletionStream(
      ChatCompletionRequest(model: "m", messages: [.user("hi")], stream: true)
    )

    var sawFinishReason = false
    var sawUsageAfterFinish = false
    for try await chunk in stream {
      if chunk.choices.first?.finishReason != nil { sawFinishReason = true }
      if sawFinishReason, chunk.usage != nil { sawUsageAfterFinish = true }
    }

    XCTAssertTrue(sawFinishReason)
    XCTAssertTrue(sawUsageAfterFinish)
  }

  func testStreamDecodesUsageOnlyChunk() async throws {
    let streamBody = """
      data: {"id":"chunk-usage","choices":[],"usage":{"prompt_tokens":3,"completion_tokens":2,"total_tokens":5,"cost":0.0005,"is_byok":false}}
      data: [DONE]
      """.data(using: .utf8)!

    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (response, streamBody)
    }

    let client = makeClient()
    let stream = try await client.createChatCompletionStream(
      ChatCompletionRequest(model: "m", messages: [.user("hi")], stream: true)
    )

    var chunks: [ChatCompletionChunk] = []
    for try await chunk in stream { chunks.append(chunk) }
    XCTAssertEqual(chunks.count, 1)
    XCTAssertEqual(chunks[0].usage?.promptTokens, 3)
    XCTAssertEqual(chunks[0].usage?.cost, 0.0005)
    XCTAssertEqual(chunks[0].usage?.isByok, false)
  }

  func testStreamYieldsChunkWithErrorFieldWithoutDecoderFailure() async throws {
    let streamBody = """
      data: {"id":"chunk-err","object":"chat.completion.chunk","created":1710000000,"model":"m","service_tier":"default","system_fingerprint":"fp_1","choices":[],"error":{"code":499,"message":"stream warning"}}
      data: [DONE]
      """.data(using: .utf8)!

    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (response, streamBody)
    }

    let client = makeClient()
    let stream = try await client.createChatCompletionStream(
      ChatCompletionRequest(model: "m", messages: [.user("hi")], stream: true)
    )

    var chunks: [ChatCompletionChunk] = []
    for try await chunk in stream { chunks.append(chunk) }
    XCTAssertEqual(chunks.count, 1)
    XCTAssertEqual(chunks[0].error?.code, 499)
    XCTAssertEqual(chunks[0].error?.message, "stream warning")
    XCTAssertEqual(chunks[0].serviceTier, "default")
    XCTAssertEqual(chunks[0].systemFingerprint, "fp_1")
  }

  func testCreateChatCompletionStreamMalformedJSONChunkFailsStream() async throws {
    let streamBody = """
      data: {"id":"chunk-1","choices":[{"index":0,"delta":{"content":"ok"},"finish_reason":null}]}
      data: {"id":"bad",
      data: [DONE]
      """.data(using: .utf8)!

    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (response, streamBody)
    }

    let client = makeClient()
    let stream = try await client.createChatCompletionStream(
      ChatCompletionRequest(model: "m", messages: [.user("hi")], stream: true)
    )

    do {
      for try await _ in stream {}
      XCTFail("Expected decoding failure")
    } catch {
      XCTAssertTrue(error is DecodingError, "Expected DecodingError, got \(error)")
    }
  }

  func testCreateChatCompletionStreamMapsNon2xxEnvelopeError() async throws {
    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 429, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!
      let body = #"{"error":{"code":429,"message":"rate limited"}}"#.data(using: .utf8)!
      return (response, body)
    }

    let client = makeClient()
    let stream = try await client.createChatCompletionStream(
      ChatCompletionRequest(model: "m", messages: [.user("hi")], stream: true)
    )

    do {
      for try await _ in stream {}
      XCTFail("Expected apiError")
    } catch let error as OpenRouterError {
      guard case .apiError(let status, let code, let message, _) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(status, 429)
      XCTAssertEqual(code, 429)
      XCTAssertEqual(message, "rate limited")
    }
  }

  func testCreateChatCompletionStreamMapsNon2xxNonJSONErrorRawBody() async throws {
    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 502, httpVersion: nil,
        headerFields: ["Content-Type": "text/plain"]
      )!
      return (response, "bad gateway".data(using: .utf8)!)
    }

    let client = makeClient()
    let stream = try await client.createChatCompletionStream(
      ChatCompletionRequest(model: "m", messages: [.user("hi")], stream: true)
    )

    do {
      for try await _ in stream {}
      XCTFail("Expected apiError")
    } catch let error as OpenRouterError {
      guard case .apiError(let status, let code, let message, let rawBody) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(status, 502)
      XCTAssertNil(code)
      XCTAssertNil(message)
      XCTAssertEqual(rawBody, "bad gateway")
    }
  }

  func testCreateChatCompletionStreamFinishesWhenTransportCompletesWithoutDone() async throws {
    let streamBody = """
      data: {"id":"chunk-1","choices":[{"index":0,"delta":{"content":"hello"},"finish_reason":null}]}

      """.data(using: .utf8)!

    URLProtocolStub.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (response, streamBody)
    }

    let client = makeClient()
    let stream = try await client.createChatCompletionStream(
      ChatCompletionRequest(model: "m", messages: [.user("hi")], stream: true)
    )

    var chunks: [ChatCompletionChunk] = []
    for try await chunk in stream { chunks.append(chunk) }
    XCTAssertEqual(chunks.count, 1)
    XCTAssertEqual(chunks[0].choices.first?.delta?.content, "hello")
  }

  func testCreateChatCompletionStreamIncludeUsageEncodesRequestAndYieldsUsageChunk() async throws {
    let streamBody = """
      data: {"id":"chunk-1","choices":[{"index":0,"delta":{"content":"hi"},"finish_reason":null}]}
      data: {"id":"chunk-usage","choices":[],"usage":{"total_tokens":15,"cost":0.000123}}
      data: [DONE]
      """.data(using: .utf8)!

    URLProtocolStub.handler = { request in
      URLProtocolStub.lastRequest = request
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (response, streamBody)
    }

    let client = makeClient()
    let stream = try await client.createChatCompletionStream(
      ChatCompletionRequest(
        model: "m",
        messages: [.user("hi")],
        stream: true,
        streamOptions: .init(includeUsage: true)
      )
    )

    var chunks: [ChatCompletionChunk] = []
    for try await chunk in stream { chunks.append(chunk) }

    let body = try XCTUnwrap(URLProtocolStub.lastRequest?.httpBody)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
    let streamOptions = try XCTUnwrap(object["stream_options"] as? [String: Any])
    XCTAssertEqual(streamOptions["include_usage"] as? Bool, true)

    XCTAssertEqual(chunks.last?.usage?.totalTokens, 15)
    XCTAssertEqual(chunks.last?.usage?.cost, 0.000123)
  }

  func testCreateChatCompletionAppliesRequestOptionsHeadersAndTimeout() async throws {
    URLProtocolStub.handler = { request in
      XCTAssertEqual(request.value(forHTTPHeaderField: "X-Test"), "1")
      XCTAssertEqual(request.timeoutInterval, 5)
      XCTAssertEqual(request.url?.host, "example.org")

      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )!
      let body =
        #"{"id":"chatcmpl-1","choices":[{"index":0,"message":{"role":"assistant","content":"ok"}}]}"#
        .data(using: .utf8)!
      return (response, body)
    }

    let client = makeClient()
    _ = try await client.createChatCompletion(
      ChatCompletionRequest(model: "m", messages: [.user("hi")]),
      options: RequestOptions(
        timeout: 5,
        baseURL: URL(string: "https://example.org/api/v1")!,
        extraHeaders: ["X-Test": "1"]
      )
    )
  }

  func testCreateChatCompletionRetriesOnConfiguredStatusCode() async throws {
    final class AttemptBox: @unchecked Sendable {
      var value = 0
      private let lock = NSLock()
      func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
      }
    }

    let attempts = AttemptBox()
    URLProtocolStub.handler = { request in
      let attempt = attempts.next()
      if attempt == 1 {
        let response = HTTPURLResponse(
          url: request.url!, statusCode: 503, httpVersion: nil,
          headerFields: ["Retry-After": "0"]
        )!
        return (response, #"{"error":{"code":503,"message":"try again"}}"#.data(using: .utf8)!)
      }

      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      let body =
        #"{"id":"chatcmpl-2","choices":[{"index":0,"message":{"role":"assistant","content":"ok"}}]}"#
        .data(using: .utf8)!
      return (response, body)
    }

    let client = makeClient()
    let response = try await client.createChatCompletion(
      ChatCompletionRequest(model: "m", messages: [.user("hi")]),
      options: RequestOptions(
        retries: .backoff(
          maxAttempts: 2,
          initialDelay: 0,
          maxDelay: 0,
          exponent: 1,
          retryStatusCodes: [503],
          retryConnectionErrors: false
        )
      )
    )

    XCTAssertEqual(response.id, "chatcmpl-2")
  }

  private func makeClient() -> OpenRouterClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolStub.self]
    let session = URLSession(configuration: config)
    return OpenRouterClient(
      apiKey: "test-key",
      configuration: .init(baseURL: URL(string: "https://openrouter.ai/api/v1")!),
      session: session
    )
  }

  private func fixtureData(named name: String) throws -> Data {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("Fixtures")
      .appendingPathComponent(name)
    return try Data(contentsOf: url)
  }
}

private final class URLProtocolStub: URLProtocol {
  static nonisolated(unsafe) var handler:
    (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?
  static nonisolated(unsafe) var lastRequest: URLRequest?

  static func register() {
    _ = URLProtocol.registerClass(URLProtocolStub.self)
  }

  static func unregister() {
    URLProtocol.unregisterClass(URLProtocolStub.self)
    handler = nil
    lastRequest = nil
  }

  override class func canInit(with request: URLRequest) -> Bool { true }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    guard let handler = Self.handler else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    do {
      Self.lastRequest = request
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
