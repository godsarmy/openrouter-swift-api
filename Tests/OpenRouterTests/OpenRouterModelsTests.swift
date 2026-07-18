import XCTest

@testable import OpenRouter

final class OpenRouterModelsTests: XCTestCase {
  func testChatCompletionRequestRoundTripWithMultimodalContent() throws {
    let request = ChatCompletionRequest(
      model: "openai/gpt-4o-mini",
      messages: [
        .system("You are helpful."),
        .init(
          role: .user,
          content: .parts([
            .text("Describe this image"),
            .imageURL("https://example.com/image.png"),
            .fileURL("https://example.com/file.pdf"),
          ])
        ),
      ],
      stream: true,
      tools: [
        .init(
          function: .init(
            name: "get_weather",
            description: "Get weather",
            parameters: .object([
              "type": .string("object"),
              "properties": .object([
                "location": .object([
                  "type": .string("string")
                ])
              ]),
            ])
          )
        )
      ],
      toolChoice: .function(name: "get_weather"),
      responseFormat: .init(
        type: "json_schema",
        jsonSchema: .init(
          name: "weather",
          strict: true,
          schema: .object([
            "type": .string("object")
          ])
        )
      )
    )

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let data = try encoder.encode(request)
    let decoded = try decoder.decode(ChatCompletionRequest.self, from: data)

    XCTAssertEqual(decoded, request)
  }

  func testContentDecodesFromStringAndArray() throws {
    let stringJSON = "\"hello\"".data(using: .utf8)!
    let arrJSON = "[{\"type\":\"text\",\"text\":\"hello\"}]".data(using: .utf8)!

    let decoder = JSONDecoder()
    XCTAssertEqual(try decoder.decode(Content.self, from: stringJSON), .text("hello"))
    XCTAssertEqual(try decoder.decode(Content.self, from: arrJSON), .parts([.text("hello")]))
  }

  func testEmbeddingInputRoundTrip() throws {
    let request = EmbeddingRequest(model: "text-embedding-3-small", input: .strings(["a", "b"]))
    let data = try JSONEncoder().encode(request)
    let decoded = try JSONDecoder().decode(EmbeddingRequest.self, from: data)
    XCTAssertEqual(decoded, request)
  }

  func testResponsesRequestEncodesStringInputAndSnakeCaseOptions() throws {
    let request = ResponsesRequest(
      model: "openai/o4-mini",
      input: .text("hello"),
      stream: true,
      maxOutputTokens: 128,
      topP: 0.9,
      reasoning: .init(effort: "medium"),
      metadata: .object(["trace_id": .string("abc")]),
      sessionID: "session-1",
      previousResponseID: "resp_prev",
      serviceTier: "default"
    )

    let data = try JSONEncoder().encode(request)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(object["input"] as? String, "hello")
    XCTAssertEqual(object["stream"] as? Bool, true)
    XCTAssertEqual(object["max_output_tokens"] as? Int, 128)
    XCTAssertEqual(object["top_p"] as? Double, 0.9)
    XCTAssertEqual(object["session_id"] as? String, "session-1")
    XCTAssertEqual(object["previous_response_id"] as? String, "resp_prev")
    XCTAssertEqual(object["service_tier"] as? String, "default")
    XCTAssertNil(object["maxOutputTokens"])
  }

  func testResponsesStreamEventPreservesUnknownPayload() throws {
    let json =
      #"{"type":"response.output_text.delta","delta":"Hi","response_id":"resp_1","future_field":{"value":1}}"#
      .data(using: .utf8)!
    let event = try JSONDecoder().decode(ResponsesStreamEvent.self, from: json)

    XCTAssertEqual(event.type, "response.output_text.delta")
    XCTAssertEqual(event.delta, "Hi")
    XCTAssertEqual(event.responseID, "resp_1")
    XCTAssertEqual(
      event.rawPayload,
      .object([
        "type": .string("response.output_text.delta"),
        "delta": .string("Hi"),
        "response_id": .string("resp_1"),
        "future_field": .object(["value": .number(1)]),
      ]))
  }

  func testResponsesInputMessagesRoundTrip() throws {
    let request = ResponsesRequest(
      model: "openai/o4-mini",
      input: .messages([
        .init(role: "user", content: [.init(text: "hello")])
      ])
    )

    let data = try JSONEncoder().encode(request)
    let decoded = try JSONDecoder().decode(ResponsesRequest.self, from: data)

    XCTAssertEqual(decoded, request)
  }

  func testResponsesResponseDecodesOutputAndUsage() throws {
    let json =
      #"{"id":"resp_123","object":"response","created_at":1710000000,"model":"openai/o4-mini","status":"completed","output":[{"id":"msg_1","type":"message","status":"completed","role":"assistant","content":[{"type":"output_text","text":"Hello!","annotations":[{"type":"url_citation","url_citation":{"title":"Doc","url":"https://example.com"}}]}]},{"id":"rs_1","type":"reasoning","summary":[{"type":"summary_text","text":"short reasoning"}],"encrypted_content":"enc"}],"usage":{"input_tokens":10,"output_tokens":2,"total_tokens":12,"input_tokens_details":{"cached_tokens":3},"output_tokens_details":{"reasoning_tokens":1}}}"#
      .data(using: .utf8)!

    let decoded = try JSONDecoder().decode(ResponsesResponse.self, from: json)

    XCTAssertEqual(decoded.id, "resp_123")
    XCTAssertEqual(decoded.createdAt, 1_710_000_000)
    XCTAssertEqual(decoded.output.first?.content?.first?.text, "Hello!")
    XCTAssertEqual(
      decoded.output.first?.content?.first?.annotations?.first?.urlCitation?.url,
      "https://example.com")
    XCTAssertEqual(decoded.output.last?.summary?.first?.text, "short reasoning")
    XCTAssertEqual(decoded.output.last?.encryptedContent, "enc")
    XCTAssertEqual(decoded.usage?.inputTokensDetails?.cachedTokens, 3)
    XCTAssertEqual(decoded.usage?.outputTokensDetails?.reasoningTokens, 1)
  }

  func testReasoningPromptCachingAndWebSearchRoundTrip() throws {
    let request = ChatCompletionRequest(
      model: "openai/gpt-4o-mini",
      messages: [
        .init(
          role: .user,
          content: .parts([
            .textWithCache(
              text: "Long reusable context", cacheControl: .init(type: "ephemeral", ttl: "5m"))
          ])
        )
      ],
      reasoning: .init(effort: "high", maxTokens: 256, exclude: false, enabled: true),
      webSearchOptions: .init(searchContextSize: "high"),
      responseCache: .init(enabled: true, ttlSeconds: 300, clear: false)
    )

    let data = try JSONEncoder().encode(request)
    let decoded = try JSONDecoder().decode(ChatCompletionRequest.self, from: data)

    XCTAssertEqual(decoded.reasoning?.effort, "high")
    XCTAssertEqual(decoded.reasoning?.maxTokens, 256)
    XCTAssertEqual(decoded.webSearchOptions?.searchContextSize, "high")
    XCTAssertNil(decoded.responseCache)

    let json = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertTrue(json.contains("\"reasoning\""))
    XCTAssertTrue(json.contains("\"web_search_options\""))
    XCTAssertTrue(json.contains("\"cache_control\""))
    XCTAssertFalse(json.contains("\"responseCache\""))
  }

  func testDecodesWebSearchAnnotationsOnAssistantMessage() throws {
    let json =
      #"{"id":"chat-1","model":"m","choices":[{"index":0,"message":{"role":"assistant","content":"answer","annotations":[{"type":"url_citation","url_citation":{"start_index":0,"end_index":6,"title":"Doc","content":"snippet","url":"https://example.com"}}]},"finish_reason":"stop"}]}"#
      .data(using: .utf8)!

    let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: json)
    let citation = decoded.choices.first?.message.annotations?.first?.urlCitation
    XCTAssertEqual(citation?.title, "Doc")
    XCTAssertEqual(citation?.url, "https://example.com")
  }

  func testMultimodalImageAndFileObjectRoundTrip() throws {
    let request = ChatCompletionRequest(
      model: "m",
      messages: [
        .init(
          role: .user,
          content: .parts([
            .image(.init(url: "https://example.com/img.png", detail: "high")),
            .file(.init(filename: "paper.pdf", fileData: "base64-pdf")),
            .inputAudio(.init(data: "base64-audio", format: "wav")),
          ])
        )
      ]
    )

    let data = try JSONEncoder().encode(request)
    let decoded = try JSONDecoder().decode(ChatCompletionRequest.self, from: data)
    XCTAssertEqual(decoded.messages.count, 1)

    guard case .parts(let parts) = decoded.messages[0].content else {
      return XCTFail("Expected multipart content")
    }

    XCTAssertEqual(parts.count, 3)
    if case .image(let image) = parts[0] {
      XCTAssertEqual(image.url, "https://example.com/img.png")
      XCTAssertEqual(image.detail, "high")
    } else {
      XCTFail("Expected image object part")
    }

    if case .file(let file) = parts[1] {
      XCTAssertEqual(file.filename, "paper.pdf")
      XCTAssertEqual(file.fileData, "base64-pdf")
    } else {
      XCTFail("Expected file object part")
    }
  }

  func testChatCompletionRequestEncodesModelsArray() throws {
    let request = ChatCompletionRequest(
      model: "primary",
      models: ["fallback-1", "fallback-2"],
      messages: [.user("hi")]
    )

    let data = try JSONEncoder().encode(request)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    XCTAssertEqual(object["models"] as? [String], ["fallback-1", "fallback-2"])
  }

  func testChatCompletionRequestEncodesProviderPreferences() throws {
    let request = ChatCompletionRequest(
      model: "m",
      messages: [.user("hi")],
      provider: .init(
        allowFallbacks: true,
        order: ["openai"],
        only: ["anthropic"],
        ignore: ["meta"],
        requireParameters: true,
        sort: "throughput",
        zdr: false
      )
    )

    let data = try JSONEncoder().encode(request)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let provider = try XCTUnwrap(object["provider"] as? [String: Any])
    XCTAssertEqual(provider["allow_fallbacks"] as? Bool, true)
    XCTAssertEqual(provider["order"] as? [String], ["openai"])
    XCTAssertEqual(provider["only"] as? [String], ["anthropic"])
    XCTAssertEqual(provider["ignore"] as? [String], ["meta"])
    XCTAssertEqual(provider["require_parameters"] as? Bool, true)
    XCTAssertEqual(provider["sort"] as? String, "throughput")
    XCTAssertEqual(provider["zdr"] as? Bool, false)
  }

  func testChatCompletionRequestEncodesStreamOptionsServiceTierSessionAndParallelToolCalls() throws
  {
    let request = ChatCompletionRequest(
      model: "m",
      messages: [.user("hi")],
      streamOptions: .init(includeUsage: true),
      serviceTier: "default",
      sessionID: "session-1",
      parallelToolCalls: true
    )

    let data = try JSONEncoder().encode(request)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let streamOptions = try XCTUnwrap(object["stream_options"] as? [String: Any])
    XCTAssertEqual(streamOptions["include_usage"] as? Bool, true)
    XCTAssertEqual(object["service_tier"] as? String, "default")
    XCTAssertEqual(object["session_id"] as? String, "session-1")
    XCTAssertEqual(object["parallel_tool_calls"] as? Bool, true)
  }

  func testChatCompletionChunkDecodesErrorPayload() throws {
    let json =
      #"{"id":"chunk-err","object":"chat.completion.chunk","created":1710000000,"model":"m","service_tier":"default","system_fingerprint":"fp_123","choices":[],"error":{"code":400,"message":"invalid request"}}"#
      .data(using: .utf8)!

    let decoded = try JSONDecoder().decode(ChatCompletionChunk.self, from: json)
    XCTAssertEqual(decoded.error?.code, 400)
    XCTAssertEqual(decoded.error?.message, "invalid request")
    XCTAssertEqual(decoded.object, "chat.completion.chunk")
    XCTAssertEqual(decoded.created, 1_710_000_000)
    XCTAssertEqual(decoded.serviceTier, "default")
    XCTAssertEqual(decoded.systemFingerprint, "fp_123")
  }
}
