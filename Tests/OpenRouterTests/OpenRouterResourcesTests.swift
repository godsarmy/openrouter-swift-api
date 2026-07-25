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
