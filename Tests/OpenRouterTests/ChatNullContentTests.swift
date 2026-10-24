import Foundation
import OpenRouter
import XCTest

final class ChatNullContentTests: XCTestCase {
  private struct Arguments: Decodable, Equatable {
    let city: String
  }

  private func response() throws -> ChatCompletionResponse {
    let url = try XCTUnwrap(
      Bundle.module.url(forResource: "chat_tool_calls_null_content", withExtension: "json"))
    return try JSONDecoder().decode(ChatCompletionResponse.self, from: Data(contentsOf: url))
  }

  func testExplicitNullContentEncodesAndDecodes() throws {
    XCTAssertEqual(try JSONDecoder().decode(Content.self, from: Data("null".utf8)), .null)
    XCTAssertEqual(String(decoding: try JSONEncoder().encode(Content.null), as: UTF8.self), "null")
    let message = ChatMessage(role: .assistant, content: .null)
    let data = try JSONEncoder().encode(message)
    let wire = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    XCTAssertTrue(wire["content"] is NSNull)
    XCTAssertEqual(try JSONDecoder().decode(ChatMessage.self, from: data), message)
  }

  func testResponsePreservesToolCallsAndOptionalMetadata() throws {
    let response = try response()
    XCTAssertEqual(response.id, "gen-null-tools")
    XCTAssertEqual(response.model, "test/model")
    let choice = try XCTUnwrap(response.choices.first)
    XCTAssertEqual(choice.index, 0)
    XCTAssertEqual(choice.finishReason, "tool_calls")
    XCTAssertEqual(choice.reasoning, "Look up both cities.")
    let message = choice.message
    XCTAssertEqual(message.role, .assistant)
    XCTAssertEqual(message.content, .null)
    XCTAssertEqual(message.name, "city_assistant")
    XCTAssertEqual(
      message.toolCalls,
      [
        ToolCall(
          id: "call_東京", function: .init(name: "weather", arguments: #"{"city":"東京 🌸"}"#)),
        ToolCall(
          id: "call_paris", function: .init(name: "forecast", arguments: #"{"city":"Paris"}"#)),
      ])
    XCTAssertEqual(
      message.annotations,
      [
        Annotation(
          type: "url_citation",
          urlCitation: URLCitation(title: "Weather source", url: "https://example.com/weather"))
      ])
    XCTAssertEqual(message.audio, OutputAudio(data: "YXVkaW8=", transcript: "Checking weather"))
    XCTAssertEqual(
      try JSONDecoder().decode(
        ChatCompletionResponse.self, from: JSONEncoder().encode(response)), response)
  }

  func testTypedToolReplayPreservesNullAndCallIdentityOnWire() throws {
    let original = try XCTUnwrap(response().choices.first).message
    let calls = try XCTUnwrap(original.toolCalls)
    var results: [ChatMessage] = []
    var tools: [ChatTool] = []
    for (index, call) in calls.enumerated() {
      let helper = TypedChatTool<Arguments, String>(
        name: call.function.name, parameters: .object(["type": .string("object")]))
      let arguments = try helper.decodeArguments(from: call)
      XCTAssertEqual(arguments.city, index == 0 ? "東京 🌸" : "Paris")
      results.append(try helper.resultMessage(for: call, result: "Weather for \(arguments.city)"))
      tools.append(helper.tool)
    }
    let request = ChatCompletionRequest(
      model: "test/model", messages: [original] + results, tools: tools)
    let data = try JSONEncoder().encode(request)
    let decoded = try JSONDecoder().decode(ChatCompletionRequest.self, from: data)
    XCTAssertEqual(decoded, request)
    XCTAssertEqual(decoded.messages[0], original)

    let wire = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let messages = try XCTUnwrap(wire["messages"] as? [[String: Any]])
    XCTAssertEqual(messages.count, 3)
    XCTAssertTrue(messages[0]["content"] is NSNull)
    let wireCalls = try XCTUnwrap(messages[0]["tool_calls"] as? [[String: Any]])
    XCTAssertEqual(wireCalls.count, calls.count)
    for (index, call) in calls.enumerated() {
      XCTAssertEqual(wireCalls[index]["id"] as? String, call.id)
      XCTAssertEqual(wireCalls[index]["type"] as? String, "function")
      let function = try XCTUnwrap(wireCalls[index]["function"] as? [String: Any])
      XCTAssertEqual(function["name"] as? String, call.function.name)
      XCTAssertEqual(function["arguments"] as? String, call.function.arguments)
      XCTAssertEqual(messages[index + 1]["role"] as? String, "tool")
      XCTAssertEqual(messages[index + 1]["tool_call_id"] as? String, call.id)
      let text = try XCTUnwrap(messages[index + 1]["content"] as? String)
      let result = try JSONDecoder().decode(String.self, from: Data(text.utf8))
      XCTAssertEqual(result, index == 0 ? "Weather for 東京 🌸" : "Weather for Paris")
    }
  }

  func testTextAndPartsRemainDistinctFromNull() throws {
    let cases: [(String, Content)] = [
      (#""hello""#, .text("hello")),
      (#""東京 🌸""#, .text("東京 🌸")),
      (#""""#, .text("")),
      (#""null""#, .text("null")),
      (#"[{"type":"text","text":"東京 🌸"}]"#, .parts([.text("東京 🌸")])),
      ("[]", .parts([])),
    ]
    for (json, expected) in cases {
      let content = try JSONDecoder().decode(Content.self, from: Data(json.utf8))
      XCTAssertEqual(content, expected)
      XCTAssertNotEqual(content, .null)
      XCTAssertEqual(
        try JSONDecoder().decode(Content.self, from: JSONEncoder().encode(content)), expected)
    }
  }

  func testInvalidContentTypesAndMissingContentRemainErrors() {
    for json in ["42", "true", "false", "{}", #"{"text":"hello"}"#] {
      XCTAssertThrowsError(try JSONDecoder().decode(Content.self, from: Data(json.utf8))) {
        guard case DecodingError.typeMismatch(_, let context) = $0 else {
          return XCTFail("Expected typeMismatch, got \($0)")
        }
        XCTAssertEqual(context.debugDescription, "Expected null, string or array content")
      }
      let message = "{\"role\":\"assistant\",\"content\":\(json)}"
      XCTAssertThrowsError(try JSONDecoder().decode(ChatMessage.self, from: Data(message.utf8)))
    }
    XCTAssertThrowsError(
      try JSONDecoder().decode(ChatMessage.self, from: Data(#"{"role":"assistant"}"#.utf8))
    ) {
      guard case DecodingError.keyNotFound(let key, _) = $0 else {
        return XCTFail("Expected keyNotFound, got \($0)")
      }
      XCTAssertEqual(key.stringValue, "content")
    }
  }
}
