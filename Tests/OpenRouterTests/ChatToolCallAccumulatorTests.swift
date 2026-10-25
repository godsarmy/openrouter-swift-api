import Foundation
import XCTest

@testable import OpenRouter

final class ChatToolCallAccumulatorTests: XCTestCase {
  private func chunk(
    _ calls: [ToolCallDelta] = [], choice: Int? = 0, finish: String? = nil
  ) -> ChatCompletionChunk {
    .init(choices: [.init(index: choice, delta: .init(toolCalls: calls), finishReason: finish)])
  }

  private func call(
    _ index: Int? = 0, id: String? = "id", name: String? = "fn", args: String? = "{}",
    type: String? = nil
  ) -> ToolCallDelta {
    .init(index: index, id: id, type: type, function: .init(name: name, arguments: args))
  }

  func testDeltaCodingAndOldInitializer() throws {
    let decoder = JSONDecoder()
    for json in ["{}", #"{"role":null,"content":null,"tool_calls":null}"#] {
      XCTAssertEqual(
        try decoder.decode(ChatCompletionChunk.Delta.self, from: Data(json.utf8)), .init())
    }
    let data = Data(#"{"tool_calls":[{"index":null,"id":null,"function":{}}]}"#.utf8)
    let delta = try decoder.decode(ChatCompletionChunk.Delta.self, from: data)
    XCTAssertEqual(delta.toolCalls, [.init(function: .init())])
    let encoded = try JSONEncoder().encode(delta)
    XCTAssertNotNil(
      (try JSONSerialization.jsonObject(with: encoded) as? [String: Any])?["tool_calls"])
    XCTAssertEqual(try decoder.decode(ChatCompletionChunk.Delta.self, from: encoded), delta)
    XCTAssertNil(ChatCompletionChunk.Delta(role: .assistant, content: "hi").toolCalls)
  }

  func testSplitUnicodeInterleavedAndSorted() throws {
    var accumulator = ChatToolCallAccumulator()
    try accumulator.append(chunk([call(4, id: "id4", args: "{\"é\":\"👩")], choice: 2))
    try accumulator.append(chunk([call(3)], choice: 0, finish: "tool_calls"))
    try accumulator.append(chunk([call(1), call(4, id: "id4", args: "🏽‍💻\"}")], choice: 2))
    try accumulator.append(
      chunk([call(4, id: nil, name: nil, args: nil)], choice: 2, finish: "tool_calls"))
    try accumulator.append(.init(choices: []))
    try accumulator.append(chunk(choice: 2))
    let result = try accumulator.finish()
    XCTAssertEqual(result[0]?.count, 1)
    XCTAssertEqual(result[2]?.map(\.function.arguments), ["{}", "{\"é\":\"👩🏽‍💻\"}"])
    XCTAssertEqual(result[2]?.first?.type, "function")
    XCTAssertThrowsError(try accumulator.finish())
    XCTAssertThrowsError(try accumulator.append(.init(choices: [])))
  }

  func testOptionalMetadataAndIdenticalRepeats() throws {
    var accumulator = ChatToolCallAccumulator()
    try accumulator.append(chunk([call(id: nil, name: nil, args: "{")]))
    try accumulator.append(chunk([call(args: "}", type: "function")]))
    try accumulator.append(chunk([call(args: nil, type: "function")], finish: "tool_calls"))
    XCTAssertEqual(try accumulator.finish()[0]?.first?.function.arguments, "{}")
  }

  func testDuplicateIDsWithinChoiceRejectAndCloseCollector() throws {
    var accumulator = ChatToolCallAccumulator()
    try accumulator.append(chunk([call(0), call(1)], choice: 2, finish: "tool_calls"))
    XCTAssertThrowsError(try accumulator.finish()) {
      XCTAssertEqual($0 as? ChatToolCallAccumulatorError, .duplicateToolCallID(choice: 2))
    }
    XCTAssertThrowsError(try accumulator.finish()) {
      XCTAssertEqual($0 as? ChatToolCallAccumulatorError, .invalidState)
    }
    XCTAssertThrowsError(try accumulator.append(.init(choices: []))) {
      XCTAssertEqual($0 as? ChatToolCallAccumulatorError, .invalidState)
    }
  }

  func testSameIDAcrossChoicesAndRepeatedFragmentsRemainValid() throws {
    var accumulator = ChatToolCallAccumulator()
    try accumulator.append(chunk([call(args: "{")], choice: 0))
    try accumulator.append(chunk([call()], choice: 1, finish: "tool_calls"))
    try accumulator.append(chunk([call(args: "}")], choice: 0, finish: "tool_calls"))
    let result = try accumulator.finish()
    for index in [0, 1] {
      XCTAssertEqual(result[index]?.count, 1)
      XCTAssertEqual(result[index]?.first?.id, "id")
      XCTAssertEqual(result[index]?.first?.function.arguments, "{}")
    }
  }

  func testMetadataConflictsAndUnsupportedTypesPoison() throws {
    for delta in [
      call(id: "other"), call(name: "other"), call(type: "other"),
    ] {
      var accumulator = ChatToolCallAccumulator()
      try accumulator.append(chunk([call(type: "function")]))
      XCTAssertThrowsError(try accumulator.append(chunk([delta])))
      XCTAssertThrowsError(try accumulator.finish())
      XCTAssertThrowsError(try accumulator.append(.init(choices: [])))
    }
    var accumulator = ChatToolCallAccumulator()
    XCTAssertThrowsError(try accumulator.append(chunk([call(type: "custom")])))
  }

  func testInvalidIndexes() {
    for invalid in [nil, -1] as [Int?] {
      for input in [
        chunk([call(invalid)]), chunk([call()], choice: invalid),
        chunk(choice: invalid, finish: "tool_calls"),
      ] {
        var accumulator = ChatToolCallAccumulator()
        XCTAssertThrowsError(try accumulator.append(input))
        XCTAssertThrowsError(try accumulator.finish())
      }
    }
  }

  func testInvalidFinalMetadataAndArguments() throws {
    let invalid = [
      call(id: nil), call(id: ""), call(name: nil), call(name: ""),
      call(args: ""), call(args: "{"), call(args: "[]"), call(args: "1"),
      call(args: "null"), call(args: "\"text\""),
    ]
    for delta in invalid {
      var accumulator = ChatToolCallAccumulator()
      try accumulator.append(chunk([delta], finish: "tool_calls"))
      XCTAssertThrowsError(try accumulator.finish())
      XCTAssertThrowsError(try accumulator.finish())
      XCTAssertThrowsError(try accumulator.append(.init(choices: [])))
    }
  }

  func testMissingOrWrongCompletion() throws {
    var incomplete = ChatToolCallAccumulator()
    try incomplete.append(chunk([call()]))
    XCTAssertThrowsError(try incomplete.finish())
    for reason in ["stop", "length", "content_filter"] {
      var accumulator = ChatToolCallAccumulator()
      try accumulator.append(chunk([call()]))
      XCTAssertThrowsError(try accumulator.append(chunk(finish: reason)))
      XCTAssertThrowsError(try accumulator.finish())
    }
    var empty = ChatToolCallAccumulator()
    XCTAssertThrowsError(try empty.append(chunk(finish: "tool_calls")))
  }

  func testTextOnlyAndNoTools() throws {
    var accumulator = ChatToolCallAccumulator()
    try accumulator.append(.init(choices: [.init(delta: .init(content: "hi"))]))
    try accumulator.append(chunk(finish: "stop"))
    try accumulator.append(chunk(choice: nil, finish: "stop"))
    XCTAssertEqual(try accumulator.finish(), [:])
    var empty = ChatToolCallAccumulator()
    XCTAssertEqual(try empty.finish(), [:])
  }

  func testTerminalMarkersRejectLaterToolDataAndDuplicateFinish() throws {
    for later in [chunk([call()]), chunk(finish: "tool_calls")] {
      var accumulator = ChatToolCallAccumulator()
      try accumulator.append(chunk([call()], finish: "tool_calls"))
      XCTAssertThrowsError(try accumulator.append(later))
      XCTAssertThrowsError(try accumulator.finish())
    }
  }

  func testStreamErrorsBeforeAndAfterToolFinish() throws {
    for completed in [false, true] {
      var accumulator = ChatToolCallAccumulator()
      if completed { try accumulator.append(chunk([call()], finish: "tool_calls")) }
      let error = ChatStreamError(code: 500, message: "failed")
      XCTAssertThrowsError(try accumulator.append(.init(choices: [], error: error))) {
        XCTAssertEqual($0 as? ChatToolCallAccumulatorError, .streamError(error))
      }
      XCTAssertThrowsError(try accumulator.finish())
    }
  }
}
