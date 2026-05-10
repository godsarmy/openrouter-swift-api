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
}
