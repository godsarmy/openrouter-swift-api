import XCTest

@testable import OpenRouter

final class SSEParserTests: XCTestCase {
  func testParsesDataEvent() {
    let event = SSEParser.parse(line: "data: {\"id\":\"x\"}")
    XCTAssertEqual(event, .data("{\"id\":\"x\"}"))
  }

  func testParsesDoneEvent() {
    let event = SSEParser.parse(line: "data: [DONE]")
    XCTAssertEqual(event, .done)
  }

  func testIgnoresNonDataLines() {
    XCTAssertNil(SSEParser.parse(line: "event: ping"))
    XCTAssertNil(SSEParser.parse(line: ""))
  }

  func testParserIgnoresBlankAndCommentLines() {
    XCTAssertNil(SSEParser.parse(line: "   "))
    XCTAssertNil(SSEParser.parse(line: ": keepalive"))
  }

  func testParserTreatsEachDataLineAsIndependentEvent() {
    XCTAssertEqual(SSEParser.parse(line: "data: first"), .data("first"))
    XCTAssertEqual(SSEParser.parse(line: "data: second"), .data("second"))
  }

  func testParsesMultilineFrameData() {
    let event = SSEParser.parseFrame(lines: [
      "event: message",
      "id: 42",
      "retry: 1000",
      "data: {\"a\":1,",
      "data: \"b\":2}",
    ])

    XCTAssertEqual(event, .data("{\"a\":1,\n\"b\":2}"))
  }

  func testParsesFrameMetadata() {
    let frame = SSEParser.parseMetadataFrame(lines: [
      ": keepalive",
      "event: update",
      "id: evt_1",
      "retry: 2500",
      "data: payload",
    ])

    XCTAssertEqual(frame.event, "update")
    XCTAssertEqual(frame.id, "evt_1")
    XCTAssertEqual(frame.retry, 2500)
    XCTAssertEqual(frame.data, "payload")
  }

  func testParsesDoneFrame() {
    XCTAssertEqual(SSEParser.parseFrame(lines: ["data: [DONE]"]), .done)
  }
}
