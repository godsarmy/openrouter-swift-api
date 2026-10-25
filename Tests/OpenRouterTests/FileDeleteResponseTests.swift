import Foundation
import XCTest

@testable import OpenRouter

final class FileDeleteResponseTests: XCTestCase {
  private let native: [String: Any] = ["id": "file-1", "type": "file_deleted", "extra": ["x": 1]]
  private let openAI: [String: Any] = [
    "id": "file-1", "object": "file", "deleted": true, "extra": true,
  ]

  private func decode(_ object: [String: Any]) throws -> FileDeleteResponse {
    try JSONDecoder().decode(
      FileDeleteResponse.self, from: JSONSerialization.data(withJSONObject: object))
  }

  private func raw(_ value: FileDeleteResponse) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
  }

  func testTaggedShapesAndPreservedExtras() throws {
    for shape in ["openrouter", "anthropic", "openai"] {
      var payload = shape == "openai" ? openAI : native
      payload["_shape"] = shape
      let result = try decode(payload)
      switch (shape, result) {
      case ("openrouter", .openRouter), ("anthropic", .anthropic), ("openai", .openAI): break
      default: XCTFail("Wrong shape")
      }
      XCTAssertEqual(result.id, "file-1")
      XCTAssertTrue(result.isConfirmed)
      XCTAssertEqual(
        try raw(result),
        try JSONDecoder().decode(
          JSONValue.self, from: JSONSerialization.data(withJSONObject: payload)))
    }
  }

  func testLegacyInferenceAndUnknownShape() throws {
    var payload = native
    payload["provider"] = "openai"
    guard case .openRouter = try decode(payload) else { return XCTFail("Expected native") }
    guard case .openAI = try decode(openAI) else { return XCTFail("Expected OpenAI") }
    payload["_shape"] = "future"
    let unknown = try decode(payload)
    guard case .unknown(let original) = unknown else { return XCTFail("Expected unknown") }
    XCTAssertFalse(unknown.isConfirmed)
    XCTAssertNil(unknown.id)
    XCTAssertEqual(try raw(unknown), original)
  }

  func testMalformedKnownShapesThrowDecodingErrors() throws {
    for shape in ["openrouter", "anthropic", "openai"] {
      var base = shape == "openai" ? openAI : native
      base["_shape"] = shape
      let keys = shape == "openai" ? ["id", "object", "deleted"] : ["id", "type"]
      for key in keys {
        for invalid: Any? in [nil, NSNull(), 7, "wrong", false] {
          if key == "id", invalid is String { continue }
          var payload = base
          payload[key] = invalid
          XCTAssertThrowsError(
            try decode(payload), "\(shape).\(key): \(String(describing: invalid))"
          ) {
            XCTAssertTrue($0 is DecodingError)
          }
        }
      }
    }
    for invalid: Any in [NSNull(), 7, false] {
      var payload = native
      payload["_shape"] = invalid
      XCTAssertThrowsError(try decode(payload)) { XCTAssertTrue($0 is DecodingError) }
    }
    for key in ["object", "deleted"] {
      var payload = native
      payload[key] = NSNull()
      XCTAssertThrowsError(try decode(payload))
    }
  }

  func testConstructorsAndMutableConfirmation() throws {
    XCTAssertTrue(FileDeleteResponse.openRouter(FileDeleted(id: "x")).isConfirmed)
    XCTAssertTrue(FileDeleteResponse.anthropic(FileDeleted(id: "x")).isConfirmed)
    XCTAssertTrue(FileDeleteResponse.openAI(OpenAIFileDeleted(id: "x", deleted: true)).isConfirmed)
    XCTAssertFalse(
      FileDeleteResponse.openAI(OpenAIFileDeleted(id: "x", deleted: false)).isConfirmed)
    XCTAssertFalse(FileDeleteResponse.openRouter(FileDeleted(id: "x", type: "file")).isConfirmed)
    var file = OpenAIFileDeleted(id: "x", deleted: true)
    file.deleted = false
    XCTAssertFalse(FileDeleteResponse.openAI(file).isConfirmed)
    file.deleted = true
    file.rawPayload = .object([
      "id": .string("x"), "object": .string("file"), "deleted": .bool(false),
    ])
    XCTAssertFalse(FileDeleteResponse.openAI(file).isConfirmed)
    var native = FileDeleted(id: "x")
    native.rawPayload = .null
    XCTAssertFalse(FileDeleteResponse.openRouter(native).isConfirmed)
    XCTAssertThrowsError(try raw(.openRouter(native))) { XCTAssertTrue($0 is EncodingError) }
    XCTAssertThrowsError(
      try raw(.openAI(OpenAIFileDeleted(id: "x", deleted: true, rawPayload: .null))))
    let encoded = try raw(.anthropic(FileDeleted(id: "x")))
    XCTAssertEqual(
      encoded,
      .object([
        "_shape": .string("anthropic"), "id": .string("x"), "type": .string("file_deleted"),
      ]))
  }
}
