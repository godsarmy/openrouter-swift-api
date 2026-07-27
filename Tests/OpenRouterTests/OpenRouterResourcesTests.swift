import Foundation
import XCTest

@testable import OpenRouter

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class OpenRouterResourcesTests: XCTestCase {
  override class func setUp() {
    super.setUp()
    URLProtocolResourcesStub.register()
  }

  override class func tearDown() {
    URLProtocolResourcesStub.unregister()
    super.tearDown()
  }

  func testListModelsBuildsRequestAndDecodesTypedModel() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/v1/models")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
      let body =
        #"{"data":[{"id":"openai/gpt-4o-mini","name":"GPT-4o mini","context_length":128000,"supported_parameters":["temperature"],"pricing":{"prompt":"0.15","completion":"0.60","input_cache_read":"0.01"}}]}"#
        .data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, body)
    }

    let result = try await makeClient().listModels()
    XCTAssertEqual(result.data.count, 1)
    XCTAssertEqual(result.data.first?.id, "openai/gpt-4o-mini")
    XCTAssertEqual(result.data.first?.contextLength, 128000)
    XCTAssertEqual(result.data.first?.supportedParameters, ["temperature"])
    XCTAssertEqual(result.data.first?.pricing?.prompt, "0.15")
    XCTAssertEqual(result.data.first?.pricing?.inputCacheRead, "0.01")
  }

  func testListEmbeddingsModelsBuildsRequestAndDecodesPagination() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/v1/embeddings/models")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(
        URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(components.queryItems?.first(where: { $0.name == "offset" })?.value, "10")
      XCTAssertEqual(components.queryItems?.first(where: { $0.name == "limit" })?.value, "25")
      let body =
        #"{"data":[{"id":"openai/text-embedding-3-small","name":"text-embedding-3-small","context_length":8191}],"links":{"next":null},"total_count":42}"#
        .data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, body)
    }

    let result = try await makeClient().listEmbeddingsModels(offset: 10, limit: 25)
    XCTAssertEqual(result.data.first?.id, "openai/text-embedding-3-small")
    XCTAssertEqual(result.data.first?.contextLength, 8191)
    XCTAssertNil(result.links.next)
    XCTAssertEqual(result.totalCount, 42)
  }

  func testEmbeddingsResourceListsModelsWithoutNilQueryItems() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/v1/embeddings/models")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
      XCTAssertNil(request.url?.query)
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      let body =
        #"{"data":[],"links":{"next":"cursor-2"},"total_count":1}"#
        .data(using: .utf8)!
      return (response, body)
    }

    let result = try await makeClient().embeddings.listModels()
    XCTAssertEqual(result.links.next, "cursor-2")
  }

  func testAudioSpeechBuildsRequestAndReturnsAudioBytes() async throws {
    let audio = Data([0x49, 0x44, 0x33, 0x04])
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/v1/audio/speech")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "audio/mpeg, audio/pcm")
      let body = try XCTUnwrap(request.httpBody)
      let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
      XCTAssertEqual(json["model"] as? String, "openai/gpt-4o-mini-tts")
      XCTAssertEqual(json["input"] as? String, "Hello")
      XCTAssertEqual(json["voice"] as? String, "alloy")
      XCTAssertEqual(json["response_format"] as? String, "pcm")
      XCTAssertEqual(json["speed"] as? Double, 1.25)
      XCTAssertEqual((json["provider"] as? [String: Any])?["voice"] as? String, "custom")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "audio/pcm"])!
      return (response, audio)
    }

    let result = try await makeClient().audio.speech(
      .init(
        model: "openai/gpt-4o-mini-tts", input: "Hello", voice: "alloy", responseFormat: .pcm,
        speed: 1.25, provider: .object(["voice": .string("custom")])))
    XCTAssertEqual(result, audio)
  }

  func testAudioSpeechMapsJSONErrorResponse() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/v1/audio/speech")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!
      return (response, #"{"error":{"code":400,"message":"invalid voice"}}"#.data(using: .utf8)!)
    }

    do {
      _ = try await makeClient().createAudioSpeech(.init(model: "m", input: "hi", voice: "bad"))
      XCTFail("Expected apiError")
    } catch let error as OpenRouterError {
      guard case .apiError(let status, let code, let message, _) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(status, 400)
      XCTAssertEqual(code, 400)
      XCTAssertEqual(message, "invalid voice")
    }
  }

  func testAudioTranscriptionBuildsMultipartRequestAndDecodesVerboseResponse() async throws {
    let audio = Data([0x52, 0x49, 0x46, 0x46])
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/v1/audio/transcriptions")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
      let contentType = try XCTUnwrap(request.value(forHTTPHeaderField: "Content-Type"))
      XCTAssertTrue(contentType.hasPrefix("multipart/form-data; boundary="))
      let body = try XCTUnwrap(request.httpBody)
      let payload = String(decoding: body, as: UTF8.self)
      XCTAssertTrue(payload.contains("name=\"file\"; filename=\"sample.wav\""))
      XCTAssertTrue(payload.contains("Content-Type: audio/wav"))
      XCTAssertTrue(payload.contains("name=\"model\"\r\n\r\nopenai/whisper"))
      XCTAssertTrue(payload.contains("name=\"language\"\r\n\r\nen"))
      XCTAssertTrue(payload.contains("name=\"temperature\"\r\n\r\n0.25"))
      XCTAssertTrue(payload.contains("name=\"response_format\"\r\n\r\nverbose_json"))
      let granularities = payload.components(
        separatedBy: "name=\"timestamp_granularities[]\"")
      XCTAssertEqual(granularities.count - 1, 2)
      XCTAssertTrue(payload.contains("name=\"prompt\"\r\n\r\nNames and places"))
      XCTAssertNotNil(body.range(of: audio))
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      let json =
        #"{"text":"Hello world","usage":{"seconds":1.5,"total_tokens":7,"#
        + #""input_tokens":5,"output_tokens":2,"cost":0.01},"#
        + #""segments":[{"text":"Hello world"}]}"#
      return (response, json.data(using: .utf8)!)
    }

    let result = try await makeClient().audio.transcribe(
      .init(
        file: .init(data: audio, filename: "sample.wav", mediaType: "audio/wav"),
        model: "openai/whisper", language: "en", temperature: 0.25,
        responseFormat: .verboseJSON,
        timestampGranularities: [.segment, .word], prompt: "Names and places"))
    XCTAssertEqual(result.text, "Hello world")
    XCTAssertEqual(result.usage?.seconds, 1.5)
    XCTAssertEqual(result.usage?.totalTokens, 7)
    XCTAssertEqual(result.usage?.inputTokens, 5)
    XCTAssertEqual(result.usage?.outputTokens, 2)
    XCTAssertEqual(result.usage?.cost, 0.01)
    XCTAssertEqual(
      result.rawPayload,
      .object([
        "text": .string("Hello world"),
        "usage": .object([
          "seconds": .number(1.5), "total_tokens": .number(7),
          "input_tokens": .number(5), "output_tokens": .number(2),
          "cost": .number(0.01),
        ]),
        "segments": .array([.object(["text": .string("Hello world")])]),
      ]))
  }

  func testAudioTranscriptionMapsJSONErrorResponse() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/v1/audio/transcriptions")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!
      let errorJson =
        #"{"error":{"code":400,"message":"invalid audio"}}"#
      return (response, errorJson.data(using: .utf8)!)
    }
    do {
      _ = try await makeClient().createAudioTranscriptions(
        .init(
          file: .init(data: Data(), filename: "empty.wav"), model: "m"))
      XCTFail("Expected apiError")
    } catch let error as OpenRouterError {
      guard case .apiError(let status, let code, let message, _) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertEqual(status, 400)
      XCTAssertEqual(code, 400)
      XCTAssertEqual(message, "invalid audio")
    }
  }

  func testCreateVideosBuildsRequestAndDecodesJob() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/v1/videos")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
      let json = try XCTUnwrap(
        JSONSerialization.jsonObject(with: try XCTUnwrap(request.httpBody)) as? [String: Any])
      XCTAssertEqual(json["model"] as? String, "google/veo-3")
      XCTAssertEqual(json["prompt"] as? String, "A mountain sunrise")
      XCTAssertEqual(json["aspect_ratio"] as? String, "16:9")
      XCTAssertEqual(json["duration"] as? Int, 8)
      XCTAssertEqual(json["resolution"] as? String, "1080p")
      XCTAssertEqual(json["size"] as? String, "large")
      XCTAssertEqual(json["generate_audio"] as? Bool, true)
      XCTAssertEqual(json["seed"] as? Int, 42)
      XCTAssertEqual(json["callback_url"] as? String, "https://example.com/callback")
      XCTAssertEqual(
        (json["frame_images"] as? [[String: Any]])?.first?["url"] as? String,
        "https://example.com/frame.png")
      XCTAssertEqual(
        (json["input_references"] as? [[String: Any]])?.first?["type"] as? String, "image")
      XCTAssertEqual((json["provider"] as? [String: Any])?["quality"] as? String, "high")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 202, httpVersion: nil, headerFields: nil)!
      return (
        response,
        #"{"id":"video_1","polling_url":"https://api.example.com/videos/video_1","status":"in_progress","generation_id":"gen_1","error":"provider warning","unsigned_urls":["https://signed.example.com/video"],"usage":{"cost":0.25,"is_byok":false},"provider_job_id":"provider_1"}"#
          .data(using: .utf8)!
      )
    }

    let result = try await makeClient().videos.create(
      .init(
        model: "google/veo-3", prompt: "A mountain sunrise", aspectRatio: .landscape, duration: 8,
        resolution: .p1080, size: "large", generateAudio: true, seed: 42,
        callbackURL: "https://example.com/callback",
        frameImages: [.object(["url": .string("https://example.com/frame.png")])],
        inputReferences: [.object(["type": .string("image")])],
        provider: .object(["quality": .string("high")])
      ))
    XCTAssertEqual(result.id, "video_1")
    XCTAssertEqual(result.pollingURL, "https://api.example.com/videos/video_1")
    XCTAssertEqual(result.status, .inProgress)
    XCTAssertEqual(result.generationID, "gen_1")
    XCTAssertEqual(result.error, "provider warning")
    XCTAssertEqual(result.unsignedURLs, ["https://signed.example.com/video"])
    XCTAssertEqual(result.usage, .init(cost: 0.25, isByok: false))
    XCTAssertEqual(
      result.rawPayload,
      .object([
        "id": .string("video_1"),
        "polling_url": .string("https://api.example.com/videos/video_1"),
        "status": .string("in_progress"),
        "generation_id": .string("gen_1"),
        "error": .string("provider warning"),
        "unsigned_urls": .array([.string("https://signed.example.com/video")]),
        "usage": .object(["cost": .number(0.25), "is_byok": .bool(false)]),
        "provider_job_id": .string("provider_1"),
      ]))
  }

  func testGetVideosBuildsRequestAndDecodesCompletedJob() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/v1/videos/video_1")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (
        response,
        #"{"id":"video_1","polling_url":"https://api.example.com/videos/video_1","status":"completed","unsigned_urls":["https://signed.example.com/video.mp4"],"usage":{"cost":0.25,"is_byok":true}}"#
          .data(using: .utf8)!
      )
    }

    let result = try await makeClient().videos.get(jobId: "video_1")
    XCTAssertEqual(result.id, "video_1")
    XCTAssertEqual(result.status, .completed)
    XCTAssertEqual(result.unsignedURLs, ["https://signed.example.com/video.mp4"])
    XCTAssertEqual(result.usage, .init(cost: 0.25, isByok: true))
  }

  func testGetCreditsDecodesWrappedCreditsPayload() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/v1/credits")
      let body = #"{"data":{"total_credits":123.4,"total_usage":12.3}}"#.data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, body)
    }

    let result = try await makeClient().getCredits()
    XCTAssertEqual(result.data?.totalCredits, 123.4)
    XCTAssertEqual(result.data?.totalUsage, 12.3)
  }

  func testResourceNamespacesRouteToExpectedEndpoints() async throws {
    let client = makeClient()

    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/v1/responses")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (
        response,
        #"{"id":"resp_1","object":"response","output":[],"status":"completed"}"#.data(using: .utf8)!
      )
    }
    _ = try await client.responses.create(.init(model: "openai/o4-mini", input: .text("hi")))

    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/v1/models")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, #"{"data":[]}"#.data(using: .utf8)!)
    }
    _ = try await client.models.list()

    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/v1/credits")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, #"{"data":{"total_credits":1,"total_usage":0}}"#.data(using: .utf8)!)
    }
    _ = try await client.credits.get()

    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/v1/generation")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, #"{"data":{"id":"gen_1"}}"#.data(using: .utf8)!)
    }
    _ = try await client.generations.get(id: "gen_1")

    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/v1/generation/content")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, #"{"data":{"id":"gen_1"}}"#.data(using: .utf8)!)
    }
    _ = try await client.generations.content(id: "gen_1")
  }

  func testCreateResponseBuildsRequestAndDecodesTypedResponse() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/v1/responses")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")

      let payload = try XCTUnwrap(request.httpBody)
      let json = try XCTUnwrap(JSONSerialization.jsonObject(with: payload) as? [String: Any])
      XCTAssertEqual(json["model"] as? String, "openai/o4-mini")
      XCTAssertEqual(json["input"] as? String, "Hello, world!")
      XCTAssertEqual(json["max_output_tokens"] as? Int, 64)
      XCTAssertNil(json["stream"])

      let body =
        #"{"id":"resp_123","object":"response","created_at":1710000000,"model":"openai/o4-mini","status":"completed","output":[{"id":"msg_1","type":"message","status":"completed","role":"assistant","content":[{"type":"output_text","text":"Hello!"}]}],"usage":{"input_tokens":5,"output_tokens":2,"total_tokens":7,"output_tokens_details":{"reasoning_tokens":1}}}"#
        .data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, body)
    }

    let result = try await makeClient().createResponse(
      .init(
        model: "openai/o4-mini",
        input: .text("Hello, world!"),
        maxOutputTokens: 64
      )
    )

    XCTAssertEqual(result.id, "resp_123")
    XCTAssertEqual(result.object, "response")
    XCTAssertEqual(result.output.first?.content?.first?.text, "Hello!")
    XCTAssertEqual(result.usage?.inputTokens, 5)
    XCTAssertEqual(result.usage?.outputTokensDetails?.reasoningTokens, 1)
  }

  func testResponsesResourceStreams() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/v1/responses")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
      )!
      return (
        response,
        "data: {\"type\":\"response.output_text.delta\",\"delta\":\"ok\"}\ndata: [DONE]\n".data(
          using: .utf8)!
      )
    }

    var events: [ResponsesStreamEvent] = []
    for try await event in makeClient().responses.stream(.init(model: "m", input: .text("hi"))) {
      events.append(event)
    }
    XCTAssertEqual(events.first?.delta, "ok")
  }

  func testMessagesResourceCreatesMessage() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/api/v1/messages")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (
        response,
        #"{"id":"m1","role":"assistant","content":[{"type":"text","text":"ok"}]}"#.data(
          using: .utf8)!
      )
    }
    let result = try await makeClient().messages.create(
      .init(model: "m", messages: [.init(role: .user, content: .text("hi"))], maxTokens: 10))
    XCTAssertEqual(result.content, [.text("ok")])
  }

  func testRerankBuildsRequestAndDecodesResponse() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/v1/rerank")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
      let json = try XCTUnwrap(
        JSONSerialization.jsonObject(with: try XCTUnwrap(request.httpBody)) as? [String: Any])
      XCTAssertEqual(json["top_n"] as? Int, 1)
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (
        response,
        #"{"id":"rr_1","model":"cohere/rerank","results":[{"index":1,"relevance_score":0.98,"document":{"text":"match","extension":true}}],"usage":{"cost":0.01,"search_units":2,"total_tokens":7,"extra":"kept"}}"#
          .data(using: .utf8)!
      )
    }
    let result = try await makeClient().rerank.create(
      .init(
        model: "cohere/rerank", query: "q", documents: [.text("a"), .object(.init(text: "match"))],
        topN: 1))
    XCTAssertEqual(result.id, "rr_1")
    XCTAssertEqual(result.results.first?.index, 1)
    XCTAssertEqual(result.results.first?.relevanceScore, 0.98)
    XCTAssertEqual(result.results.first?.document.text, "match")
    XCTAssertEqual(
      result.results.first?.document.rawPayload,
      .object(["text": .string("match"), "extension": .bool(true)]))
    XCTAssertEqual(result.usage?.searchUnits, 2)
    XCTAssertEqual(result.usage?.totalTokens, 7)
  }

  func testCreateResponseReplaysFunctionCallAndOutput() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/v1/responses")
      let body = try XCTUnwrap(request.httpBody)
      let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
      let tool = try XCTUnwrap((json["tools"] as? [[String: Any]])?.first)
      XCTAssertEqual(tool["type"] as? String, "function")
      XCTAssertNil(tool["function"])
      let input = try XCTUnwrap(json["input"] as? [[String: Any]])
      XCTAssertEqual(input[0]["type"] as? String, "function_call")
      XCTAssertEqual(input[0]["call_id"] as? String, "call_1")
      XCTAssertEqual(input[1]["type"] as? String, "function_call_output")
      XCTAssertEqual(input[1]["call_id"] as? String, "call_1")
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, #"{"id":"resp_2","output":[]}"#.data(using: .utf8)!)
    }

    _ = try await makeClient().createResponse(
      .init(
        model: "m",
        input: .items([
          .functionCall(
            .init(callID: "call_1", name: "get_weather", arguments: #"{"city":"Paris"}"#)),
          .functionCallOutput(.init(callID: "call_1", output: .text("sunny"))),
        ]),
        tools: [.init(name: "get_weather")], toolChoice: .function(name: "get_weather")
      ))
  }

  func testListProvidersBuildsRequestAndDecodesTypedProvider() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/v1/providers")
      let body =
        #"{"data":[{"name":"OpenAI","slug":"openai","privacy_policy_url":"https://openai.com/privacy","status_page_url":"https://status.openai.com"}]}"#
        .data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, body)
    }

    let result = try await makeClient().providers.list()
    XCTAssertEqual(result.data.first?.name, "OpenAI")
    XCTAssertEqual(result.data.first?.slug, "openai")
    XCTAssertEqual(result.data.first?.privacyPolicyURL, "https://openai.com/privacy")
  }

  func testListModelEndpointsBuildsRequestAndDecodesEndpoint() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/v1/models/openai/gpt-4o-mini/endpoints")
      let body =
        #"{"data":{"id":"openai/gpt-4o-mini","name":"GPT-4o mini","endpoints":[{"name":"OpenAI","provider_name":"openai","context_length":128000,"max_completion_tokens":4096,"supported_parameters":["temperature"]}]}}"#
        .data(using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, body)
    }

    let result = try await makeClient().endpoints.list(author: "openai", slug: "gpt-4o-mini")
    XCTAssertEqual(result.data.id, "openai/gpt-4o-mini")
    XCTAssertEqual(result.data.endpoints.first?.providerName, "openai")
    XCTAssertEqual(result.data.endpoints.first?.contextLength, 128000)
    XCTAssertEqual(result.data.endpoints.first?.supportedParameters, ["temperature"])
  }

  func testListZDREndpointsBuildsRequestAndDecodesEndpoint() async throws {
    URLProtocolResourcesStub.handler = { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/v1/endpoints/zdr")
      let body = #"{"data":[{"name":"ZDR provider","context_length":32000}]}"#.data(
        using: .utf8)!
      let response = HTTPURLResponse(
        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, body)
    }

    let result = try await makeClient().endpoints.listZDR()
    XCTAssertEqual(result.data.first?.name, "ZDR provider")
    XCTAssertEqual(result.data.first?.contextLength, 32000)
  }

  private func makeClient() -> OpenRouterClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolResourcesStub.self]
    return OpenRouterClient(apiKey: "test-key", session: URLSession(configuration: config))
  }
}

private final class URLProtocolResourcesStub: URLProtocol {
  static nonisolated(unsafe) var handler:
    (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?
  static func register() { _ = URLProtocol.registerClass(URLProtocolResourcesStub.self) }
  static func unregister() {
    URLProtocol.unregisterClass(URLProtocolResourcesStub.self)
    handler = nil
  }
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    guard let handler = Self.handler else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }
    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }
  override func stopLoading() {}
}
