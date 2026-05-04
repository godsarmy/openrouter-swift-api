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
}
