import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class ChatToolStreamingTests: XCTestCase {
  private struct Arguments: Decodable, Equatable {
    let city: String
  }

  private func client(_ scenario: String) -> OpenRouterClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ChatToolStreamingProtocol.self]
    return OpenRouterClient(
      apiKey: "offline-test",
      configuration: .init(baseURL: URL(string: "https://tools.invalid/\(scenario)")!),
      session: URLSession(configuration: configuration))
  }

  func testInterleavedToolCallsDecodeOnlyAfterStreamExhaustion() async throws {
    var accumulator = ChatToolCallAccumulator()
    var chunks: [ChatCompletionChunk] = []
    var results: [ChatMessage] = []
    for try await chunk in client("success").chat.stream(
      .init(model: "offline", messages: [.user("Look up both cities")]))
    {
      XCTAssertTrue(results.isEmpty, "Tools must not execute while the stream is open")
      chunks.append(chunk)
      try accumulator.append(chunk)
    }

    XCTAssertEqual(chunks.count, 5)
    let raw = try XCTUnwrap(chunks.first?.choices.first?.delta?.toolCalls?.first)
    XCTAssertEqual(raw.index, 1)
    XCTAssertEqual(raw.id, "call_paris")
    XCTAssertEqual(raw.type, "function")
    XCTAssertEqual(raw.function?.name, "lookup")
    XCTAssertEqual(raw.function?.arguments, #"{"city":"Par"#)
    XCTAssertEqual(chunks[1].choices.first?.delta?.toolCalls?.first?.index, 0)
    XCTAssertEqual(chunks[2].choices.first?.delta?.toolCalls?.first?.function?.arguments, "is\"}")
    XCTAssertEqual(chunks[3].choices.first?.finishReason, "tool_calls")
    XCTAssertTrue(chunks[4].choices.isEmpty)
    XCTAssertNotNil(chunks[4].usage)

    let completed = try accumulator.finish()
    XCTAssertEqual(completed.count, 1)
    let calls = try XCTUnwrap(completed[0])
    XCTAssertEqual(calls.map(\.id), ["call_tokyo", "call_paris"])
    XCTAssertEqual(calls.map(\.type), ["function", "function"])
    XCTAssertEqual(calls.map(\.function.name), ["lookup", "lookup"])
    XCTAssertEqual(calls.map(\.function.arguments), [#"{"city":"東京 🌸"}"#, #"{"city":"Paris"}"#])
    let tool = TypedChatTool<Arguments, String>(name: "lookup", parameters: .object([:]))
    for (call, city) in zip(calls, ["東京 🌸", "Paris"]) {
      XCTAssertEqual(try tool.decodeArguments(from: call), Arguments(city: city))
      let message = try tool.resultMessage(for: call, result: city)
      XCTAssertEqual(message.role, .tool)
      XCTAssertEqual(message.toolCallID, call.id)
      guard case .text(let text) = message.content else {
        return XCTFail("Expected encoded tool result")
      }
      XCTAssertEqual(try JSONDecoder().decode(String.self, from: Data(text.utf8)), city)
      results.append(message)
    }
    XCTAssertEqual(results.count, 2)
  }

  func testNormalEOFWithoutTerminalFinishRejectsCompleteLookingArguments() async throws {
    var accumulator = ChatToolCallAccumulator()
    var received = 0
    for try await chunk in client("truncated").chat.stream(
      .init(model: "offline", messages: [.user("hi")]))
    {
      received += 1
      try accumulator.append(chunk)
    }
    XCTAssertEqual(received, 3)
    XCTAssertThrowsError(try accumulator.finish())
  }

  func testErrorChunkAfterToolFinishRejectsAppendAndResults() async throws {
    var accumulator = ChatToolCallAccumulator()
    var sawFinish = false
    var rejectedError = false
    for try await chunk in client("terminal-error").chat.stream(
      .init(model: "offline", messages: [.user("hi")]))
    {
      if chunk.error != nil {
        XCTAssertTrue(sawFinish)
        XCTAssertThrowsError(try accumulator.append(chunk))
        rejectedError = true
      } else {
        try accumulator.append(chunk)
        sawFinish = sawFinish || chunk.choices.contains { $0.finishReason == "tool_calls" }
      }
    }
    XCTAssertTrue(rejectedError)
    XCTAssertThrowsError(try accumulator.finish())
  }

  func testTransportFailurePropagatesWithoutExecutableResults() async throws {
    var accumulator = ChatToolCallAccumulator()
    do {
      for try await chunk in client("transport-error").chat.stream(
        .init(model: "offline", messages: [.user("hi")]))
      {
        try accumulator.append(chunk)
      }
      XCTFail("Expected transport failure, not normal stream exhaustion")
    } catch {
      // Error wrapping is deliberately not part of the accumulator contract.
    }
  }
}

/// Isolated from the shared mocked-client protocol: no mutable static handlers or registration.
private final class ChatToolStreamingProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    if request.url!.path.contains("transport-error") {
      client?.urlProtocol(self, didFailWithError: URLError(.networkConnectionLost))
      return
    }
    let frames = [
      #"{"choices":[{"index":0,"delta":{"tool_calls":[{"index":1,"id":"call_paris","type":"function","function":{"name":"lookup","arguments":"{\"city\":\"Par"}}]}}]}"#,
      #"{"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"id":"call_tokyo","type":"function","function":{"name":"lookup","arguments":"{\"city\":\"東"}}]}}]}"#,
      #"{"choices":[{"index":0,"delta":{"tool_calls":[{"index":1,"function":{"arguments":"is\"}"}},{"index":0,"function":{"arguments":"京 🌸\"}"}}]}}]}"#,
      #"{"choices":[{"index":0,"delta":{},"finish_reason":"tool_calls"}]}"#,
      #"{"choices":[],"usage":{"prompt_tokens":8,"completion_tokens":12,"total_tokens":20}}"#,
    ]
    var selected = request.url!.path.contains("truncated") ? Array(frames.prefix(3)) : frames
    if request.url!.path.contains("terminal-error") {
      selected.append(#"{"choices":[],"error":{"code":500,"message":"late failure"}}"#)
    }
    let response = HTTPURLResponse(
      url: request.url!, statusCode: 200, httpVersion: nil,
      headerFields: ["Content-Type": "text/event-stream"])!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    for frame in selected {
      client?.urlProtocol(self, didLoad: Data("data: \(frame)\n\n".utf8))
    }
    if !request.url!.path.contains("truncated") {
      client?.urlProtocol(self, didLoad: Data("data: [DONE]\n\n".utf8))
    }
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}
