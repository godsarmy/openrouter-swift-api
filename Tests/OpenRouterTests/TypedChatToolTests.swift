import Foundation
import OpenRouter
import XCTest

final class TypedChatToolTests: XCTestCase {
  private struct Arguments: Decodable, Equatable {
    let city: String
    let count: Int
  }

  private struct Result: Codable, Equatable {
    let summary: String
  }

  private let parameters: JSONValue = .object([
    "type": .string("object"),
    "properties": .object([
      "city": .object(["type": .string("string")]),
      "count": .object(["type": .string("integer")]),
    ]),
    "required": .array([.string("city"), .string("count")]),
  ])

  private var helper: TypedChatTool<Arguments, Result> {
    TypedChatTool(name: "lookup", description: "Look up a city", parameters: parameters)
  }

  private func call(
    id: String? = "call_雪", type: String = "function", name: String = "lookup",
    arguments: String = #"{"city":"東京 🌸","count":2}"#
  ) -> ToolCall {
    ToolCall(id: id, type: type, function: .init(name: name, arguments: arguments))
  }

  func testArgumentsResultAndRawRequestCompatibility() throws {
    let call = call()
    XCTAssertEqual(
      try helper.decodeArguments(from: call), Arguments(city: "東京 🌸", count: 2))
    XCTAssertEqual(helper.tool.type, "function")
    XCTAssertEqual(helper.tool.function.name, "lookup")
    XCTAssertEqual(helper.tool.function.description, "Look up a city")
    XCTAssertEqual(helper.tool.function.parameters, parameters)

    let result = Result(summary: "晴れ ☀️")
    let message = try helper.resultMessage(for: call, result: result)
    XCTAssertEqual(message.role, .tool)
    XCTAssertEqual(message.toolCallID, call.id)
    guard case .text(let text) = message.content else {
      return XCTFail("Expected JSON text")
    }
    XCTAssertEqual(try JSONDecoder().decode(Result.self, from: Data(text.utf8)), result)

    let request = ChatCompletionRequest(
      model: "test/model",
      messages: [ChatMessage(role: .assistant, content: .text(""), toolCalls: [call]), message],
      tools: [helper.tool])
    let data = try JSONEncoder().encode(request)
    XCTAssertEqual(try JSONDecoder().decode(ChatCompletionRequest.self, from: data), request)
    let wire = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let messages = try XCTUnwrap(wire["messages"] as? [[String: Any]])
    XCTAssertEqual(messages[1]["tool_call_id"] as? String, call.id)
    XCTAssertEqual(messages[1]["role"] as? String, "tool")
    XCTAssertEqual(messages[1]["content"] as? String, text)
    XCTAssertNil(messages[1]["toolCallID"])
  }

  func testBothMethodsRejectWrongTypesAndNames() {
    let cases: [(ToolCall, TypedChatToolError)] = [
      (call(type: "custom"), .unsupportedToolType("custom")),
      (call(name: "other"), .functionNameMismatch(expected: "lookup", actual: "other")),
    ]
    for (call, expected) in cases {
      XCTAssertThrowsError(try helper.decodeArguments(from: call)) {
        XCTAssertEqual($0 as? TypedChatToolError, expected)
      }
      XCTAssertThrowsError(try helper.resultMessage(for: call, result: Result(summary: "ok"))) {
        XCTAssertEqual($0 as? TypedChatToolError, expected)
      }
    }
  }

  func testMissingAndEmptyIDsOnlyPreventResultMessages() throws {
    for id: String? in [nil, ""] {
      let call = call(id: id)
      XCTAssertEqual(try helper.decodeArguments(from: call).count, 2)
      XCTAssertThrowsError(try helper.resultMessage(for: call, result: Result(summary: "ok"))) {
        XCTAssertEqual($0 as? TypedChatToolError, .missingToolCallID)
      }
    }
  }

  func testFoundationDecodingErrorsPropagate() {
    for arguments in ["{", "", "{}", #"{"city":"Paris","count":"two"}"#] {
      XCTAssertThrowsError(try helper.decodeArguments(from: call(arguments: arguments))) {
        XCTAssertTrue($0 is DecodingError, "Unexpected error: \($0)")
      }
    }
  }

  func testCustomDecoderAndEncoderStrategies() throws {
    struct Payload: Codable, Equatable {
      let createdAt: Date
    }
    let helper = TypedChatTool<Payload, Payload>(name: "lookup", parameters: .object([:]))
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .secondsSince1970
    let payload = try helper.decodeArguments(
      from: call(arguments: #"{"created_at":1234}"#), decoder: decoder)
    XCTAssertEqual(payload.createdAt, Date(timeIntervalSince1970: 1234))

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .secondsSince1970
    let message = try helper.resultMessage(for: call(), result: payload, encoder: encoder)
    guard case .text(let text) = message.content else {
      return XCTFail("Expected JSON text")
    }
    let object = try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Double]
    XCTAssertEqual(object, ["created_at": 1234])
  }

  func testEncodingErrorsPropagate() {
    let helper = TypedChatTool<Arguments, Double>(name: "lookup", parameters: parameters)
    XCTAssertThrowsError(try helper.resultMessage(for: call(), result: .infinity)) {
      XCTAssertTrue($0 is EncodingError)
    }

    enum DeliberateError: Error { case failed }
    struct ThrowingResult: Encodable {
      func encode(to encoder: Encoder) throws { throw DeliberateError.failed }
    }
    let throwingHelper = TypedChatTool<Arguments, ThrowingResult>(
      name: "lookup", parameters: parameters)
    XCTAssertThrowsError(try throwingHelper.resultMessage(for: call(), result: ThrowingResult())) {
      guard case DeliberateError.failed = $0 else {
        return XCTFail("Expected unchanged custom error, got \($0)")
      }
    }
  }

  func testStringResultsRemainJSONQuoted() throws {
    let helper = TypedChatTool<Arguments, String>(name: "lookup", parameters: parameters)
    let result = "東京 \"sunny\"\n🌸"
    let message = try helper.resultMessage(for: call(), result: result)
    guard case .text(let text) = message.content else {
      return XCTFail("Expected JSON text")
    }
    XCTAssertNotEqual(text, result)
    XCTAssertTrue(text.hasPrefix("\""))
    XCTAssertTrue(text.hasSuffix("\""))
    XCTAssertEqual(try JSONDecoder().decode(String.self, from: Data(text.utf8)), result)
  }

  func testSendableDoesNotRequireSendableArgumentsOrResults() {
    final class ReferenceArguments: Decodable {
      var value: String
    }
    final class ReferenceResult: Encodable {
      var value: String = "result"
    }
    func requireSendable<T: Sendable>(_ value: T) {}
    requireSendable(
      TypedChatTool<ReferenceArguments, ReferenceResult>(name: "lookup", parameters: parameters))
  }
}
