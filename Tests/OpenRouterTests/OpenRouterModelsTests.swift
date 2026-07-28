import XCTest

@testable import OpenRouter

final class OpenRouterModelsTests: XCTestCase {
  func testFileMetadataDecodesRequiredFieldsAndPreservesExtensions() throws {
    let metadata = try JSONDecoder().decode(
      FileMetadata.self,
      from:
        #"{"id":"file_1","type":"file","filename":"notes.txt","mime_type":"text/plain","size_bytes":12,"created_at":"2026-01-01T00:00:00Z","downloadable":false,"checksum":"abc"}"#
        .data(using: .utf8)!)
    XCTAssertEqual(metadata.filename, "notes.txt")
    XCTAssertEqual(metadata.createdAt, "2026-01-01T00:00:00Z")
    XCTAssertEqual(
      metadata.rawPayload,
      .object([
        "id": .string("file_1"), "type": .string("file"), "filename": .string("notes.txt"),
        "mime_type": .string("text/plain"), "size_bytes": .number(12),
        "created_at": .string("2026-01-01T00:00:00Z"), "downloadable": .bool(false),
        "checksum": .string("abc"),
      ]))
  }

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

  func testResponsesToolsEncodeFlatToolAndForcedChoice() throws {
    let request = ResponsesRequest(
      model: "m", input: .text("weather"),
      tools: [
        .init(
          name: "get_weather", description: "Get weather",
          parameters: .object(["type": .string("object")]), strict: true)
      ],
      toolChoice: .function(name: "get_weather"), parallelToolCalls: true
    )
    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])
    let tool = try XCTUnwrap((json["tools"] as? [[String: Any]])?.first)
    XCTAssertEqual(tool["type"] as? String, "function")
    XCTAssertEqual(tool["name"] as? String, "get_weather")
    XCTAssertEqual(tool["strict"] as? Bool, true)
    XCTAssertNil(tool["function"])
    let choice = try XCTUnwrap(json["tool_choice"] as? [String: Any])
    XCTAssertEqual(choice["type"] as? String, "function")
    XCTAssertEqual(choice["name"] as? String, "get_weather")
    XCTAssertNil(choice["function"])
    XCTAssertEqual(json["parallel_tool_calls"] as? Bool, true)
    XCTAssertEqual(
      try JSONDecoder().decode(ResponsesToolChoice.self, from: #""required""#.data(using: .utf8)!),
      .required)
    XCTAssertEqual(
      String(data: try JSONEncoder().encode(ResponsesToolChoice.required), encoding: .utf8),
      #""required""#)
  }

  func testResponsesMixedItemHistoryRoundTrips() throws {
    let items: [ResponsesInputItem] = [
      .message(.init(role: "user", content: [.init(text: "weather")])),
      .functionCall(
        .init(
          id: "fc_1", callID: "call_1", name: "get_weather", arguments: #"{"city":"Paris"}"#,
          status: "completed")),
      .functionCallOutput(.init(callID: "call_1", output: .text("sunny"))),
      .functionCallOutput(
        .init(
          callID: "call_2",
          output: .parts([
            .object([
              "type": .string("input_image"), "image_url": .string("https://example.com/image.png"),
            ])
          ]))),
    ]
    let request = ResponsesRequest(model: "m", input: .items(items))
    let data = try JSONEncoder().encode(request)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let input = try XCTUnwrap(json["input"] as? [[String: Any]])
    XCTAssertEqual(
      input.map { $0["type"] as? String },
      ["message", "function_call", "function_call_output", "function_call_output"])
    XCTAssertEqual(input[1]["call_id"] as? String, "call_1")
    XCTAssertEqual(input[2]["output"] as? String, "sunny")
    XCTAssertTrue(input[3]["output"] is [[String: Any]])
    XCTAssertEqual(try JSONDecoder().decode(ResponsesRequest.self, from: data), request)
  }

  func testResponsesItemsTreatMissingTypeAsMessageAndEncodeMessageType() throws {
    let rawMessage = #"{"role":"user","content":[{"type":"input_text","text":"hello"}]}"#.data(
      using: .utf8)!
    XCTAssertEqual(
      try JSONDecoder().decode(ResponsesInputItem.self, from: rawMessage),
      .message(.init(type: nil, role: "user", content: [.init(text: "hello")])))
    let input = try JSONDecoder().decode(
      ResponsesInput.self,
      from: Data("[".utf8) + rawMessage + Data("]".utf8))
    XCTAssertEqual(
      input, .messages([.init(type: nil, role: "user", content: [.init(text: "hello")])]))

    let request = ResponsesRequest(
      model: "m",
      input: .items([.message(.init(type: nil, role: "user", content: [.init(text: "hello")]))]))
    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])
    let item = try XCTUnwrap((json["input"] as? [[String: Any]])?.first)
    XCTAssertEqual(item["type"] as? String, "message")
  }

  func testResponsesReasoningItemReplaysAndEncodesReasoningContext() throws {
    let response = try JSONDecoder().decode(
      ResponsesResponse.self,
      from:
        #"{"id":"resp_1","output":[{"type":"reasoning","id":"rs_1","summary":[{"type":"summary_text","text":"brief"}],"content":[{"type":"reasoning_text","text":"detail"}],"encrypted_content":"enc","status":"completed","format":"openai","signature":"sig"}]}"#
        .data(using: .utf8)!)
    let reasoning = try XCTUnwrap(response.output.first?.reasoningItem)
    XCTAssertEqual(reasoning.encryptedContent, "enc")
    XCTAssertEqual(reasoning.summary.first?.text, "brief")
    XCTAssertEqual(reasoning.content?.first?.text, "detail")

    let request = ResponsesRequest(
      model: "m", input: .items([.reasoning(reasoning)]),
      reasoning: .init(context: "all_turns"), include: ["reasoning.encrypted_content"])
    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])
    let item = try XCTUnwrap((json["input"] as? [[String: Any]])?.first)
    XCTAssertEqual(item["type"] as? String, "reasoning")
    XCTAssertEqual(item["encrypted_content"] as? String, "enc")
    XCTAssertEqual((item["summary"] as? [[String: Any]])?.first?["text"] as? String, "brief")
    XCTAssertEqual((json["reasoning"] as? [String: Any])?["context"] as? String, "all_turns")
    XCTAssertEqual(json["include"] as? [String], ["reasoning.encrypted_content"])
  }

  func testResponsesReasoningStringSummaryPreservesReplayWireShape() throws {
    let response = try JSONDecoder().decode(
      ResponsesResponse.self,
      from:
        #"{"id":"resp_1","output":[{"type":"reasoning","id":"rs_1","summary":["Analyzed the problem"]}]}"#
        .data(using: .utf8)!)
    let reasoning = try XCTUnwrap(response.output.first?.reasoningItem)
    XCTAssertEqual(reasoning.summary.first?.text, "Analyzed the problem")

    let request = ResponsesRequest(model: "m", input: .items([.reasoning(reasoning)]))
    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])
    let item = try XCTUnwrap((json["input"] as? [[String: Any]])?.first)
    XCTAssertEqual(item["summary"] as? [String], ["Analyzed the problem"])
  }

  func testResponsesReasoningSummaryEqualityAndMutationRespectPublicFields() throws {
    var decoded = try JSONDecoder().decode(
      ResponsesReasoningSummary.self, from: #""brief""#.data(using: .utf8)!)
    XCTAssertEqual(decoded, ResponsesReasoningSummary(text: "brief"))

    decoded.type = "summary_text"
    let object = try XCTUnwrap(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(decoded)) as? [String: Any])
    XCTAssertEqual(object["type"] as? String, "summary_text")
    XCTAssertEqual(object["text"] as? String, "brief")
  }

  func testMessagesRequestAndResponseToolContinuation() throws {
    let request = MessagesRequest(
      model: "anthropic/claude",
      messages: [
        .init(
          role: .user,
          content: .blocks([
            .text("hi"),
            .image(
              .object([
                "type": .string("base64"), "media_type": .string("image/png"),
                "data": .string("abc"),
              ])),
            .document(
              .object(["type": .string("url"), "url": .string("https://example.com/doc.pdf")])),
          ]))
      ], maxTokens: 2048, thinking: .enabled(budgetTokens: 1024),
      tools: [.init(name: "weather", inputSchema: .object(["type": .string("object")]))],
      toolChoice: .tool(name: "weather"))
    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])
    XCTAssertEqual(json["max_tokens"] as? Int, 2048)
    XCTAssertEqual(
      ((json["tools"] as? [[String: Any]])?.first?["input_schema"] as? [String: Any])?["type"]
        as? String,
      "object")

    let response = try JSONDecoder().decode(
      MessagesResponse.self,
      from:
        #"{"id":"msg_1","role":"assistant","content":[{"type":"text","text":"checking"},{"type":"tool_use","id":"tool_1","name":"weather","input":{"city":"Paris"}},{"type":"thinking","thinking":"reason","signature":"sig"}]}"#
        .data(using: .utf8)!)
    let followUp = MessagesMessage(
      role: .user, content: .blocks([.toolResult(toolUseID: "tool_1", content: .text("sunny"))]))
    XCTAssertEqual(response.assistantMessage.role, .assistant)
    XCTAssertEqual(
      followUp.content, .blocks([.toolResult(toolUseID: "tool_1", content: .text("sunny"))]))
  }

  func testMessagesContinuationPreservesRawBlocksAndServerTools() throws {
    let response = try JSONDecoder().decode(
      MessagesResponse.self,
      from:
        #"{"role":"assistant","content":[{"type":"text","text":"ok","cache_control":{"type":"ephemeral"},"citation":"x"},{"type":"tool_use","id":"u1","name":"tool","input":{},"vendor":"extra"}]}"#
        .data(using: .utf8)!)
    let request = MessagesRequest(
      model: "m", messages: [response.assistantMessage], maxTokens: 10,
      tools: [
        try JSONDecoder().decode(
          MessagesTool.self,
          from: #"{"type":"web_search_20250305","name":"web_search"}"#.data(using: .utf8)!)
      ])
    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])
    let blocks = try XCTUnwrap(
      (json["messages"] as? [[String: Any]])?.first?["content"] as? [[String: Any]])
    XCTAssertEqual((blocks[0]["cache_control"] as? [String: Any])?["type"] as? String, "ephemeral")
    XCTAssertEqual(blocks[1]["vendor"] as? String, "extra")
    XCTAssertEqual(
      (json["tools"] as? [[String: Any]])?.first?["type"] as? String, "web_search_20250305")
  }

  func testMessagesToolResultAndSystemPromptEncoding() throws {
    let request = MessagesRequest(
      model: "m",
      messages: [
        .init(
          role: .user,
          content: .blocks([
            .toolResult(toolUseID: "u1", isError: true),
            .toolResult(toolUseID: "u2", content: .text("ok")),
          ]))
      ], maxTokens: 10, system: .blocks([.init(text: "Be concise")]))
    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])
    let blocks = try XCTUnwrap(
      (json["messages"] as? [[String: Any]])?.first?["content"] as? [[String: Any]])
    XCTAssertEqual(blocks[0]["tool_use_id"] as? String, "u1")
    XCTAssertEqual(blocks[0]["is_error"] as? Bool, true)
    XCTAssertNil(blocks[0]["content"])
    XCTAssertEqual(((json["system"] as? [[String: Any]])?.first)?["type"] as? String, "text")
  }

  func testRerankRequestEncodesDocumentsAndProvider() throws {
    let request = RerankRequest(
      model: "cohere/rerank", query: "swift",
      documents: [
        .text("Swift language"),
        .object(.init(text: "Guide", image: "https://example.com/image.png")),
      ],
      topN: 2, provider: .init(order: ["cohere"]))
    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])
    XCTAssertEqual(json["top_n"] as? Int, 2)
    let documents = try XCTUnwrap(json["documents"] as? [Any])
    XCTAssertEqual(documents[0] as? String, "Swift language")
    XCTAssertEqual(
      (documents[1] as? [String: Any])?["image"] as? String, "https://example.com/image.png")
    XCTAssertEqual((json["provider"] as? [String: Any])?["order"] as? [String], ["cohere"])
  }

  func testDecodedMessagesToolPreservesExtensionFields() throws {
    let tool = try JSONDecoder().decode(
      MessagesTool.self,
      from:
        #"{"name":"weather","description":"forecast","input_schema":{"type":"object"},"cache_control":{"type":"ephemeral"},"strict":true,"input_examples":[{"city":"Paris"}],"defer_loading":true}"#
        .data(using: .utf8)!)
    XCTAssertEqual(tool.name, "weather")
    XCTAssertEqual(tool.inputSchema, .object(["type": .string("object")]))

    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(tool)) as? [String: Any])
    XCTAssertEqual((json["cache_control"] as? [String: Any])?["type"] as? String, "ephemeral")
    XCTAssertEqual(json["strict"] as? Bool, true)
    XCTAssertEqual((json["input_examples"] as? [[String: Any]])?.first?["city"] as? String, "Paris")
    XCTAssertEqual(json["defer_loading"] as? Bool, true)
  }

  func testResponsesFunctionCallOutputSupportsReplayAndStreamToolFields() throws {
    let response = try JSONDecoder().decode(
      ResponsesResponse.self,
      from:
        #"{"id":"resp_1","output":[{"type":"function_call","id":"fc_1","call_id":"call_1","name":"get_weather","arguments":"{}","status":"completed"}]}"#
        .data(using: .utf8)!)
    let call = try XCTUnwrap(response.output.first?.functionCall)
    XCTAssertEqual(call.callID, "call_1")
    let replay = ResponsesRequest(
      model: "m",
      input: .items([
        .functionCall(call),
        .functionCallOutput(.init(callID: call.callID, output: .text("sunny"))),
      ]))
    XCTAssertEqual(
      replay.input,
      .items([
        .functionCall(call),
        .functionCallOutput(.init(callID: call.callID, output: .text("sunny"))),
      ]))

    let itemEvent = try JSONDecoder().decode(
      ResponsesStreamEvent.self,
      from:
        #"{"type":"response.output_item.added","item":{"type":"function_call","call_id":"call_1","name":"get_weather","arguments":"{}"}}"#
        .data(using: .utf8)!)
    let argumentsEvent = try JSONDecoder().decode(
      ResponsesStreamEvent.self,
      from: #"{"type":"response.function_call_arguments.done","arguments":"{}"}"#.data(
        using: .utf8)!)
    XCTAssertEqual(itemEvent.item?.functionCall?.name, "get_weather")
    XCTAssertEqual(argumentsEvent.arguments, "{}")
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
