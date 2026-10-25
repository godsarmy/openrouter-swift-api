import Foundation
import OpenRouter
import XCTest

final class BatchDeleteResponseTests: XCTestCase {
  private func decode(_ payload: [String: Any]) throws -> BatchDeleteResponse {
    try JSONDecoder().decode(
      BatchDeleteResponse.self, from: JSONSerialization.data(withJSONObject: payload))
  }

  private func raw<T: Encodable>(_ value: T) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
  }

  private func body(_ deletion: Any = ["openrouter": "deleted"]) -> [String: Any] {
    ["id": "batch-1", "object": "batch", "deletion": deletion]
  }

  private func assertInvalid(
    _ payload: [String: Any], file: StaticString = #filePath, line: UInt = #line
  ) {
    XCTAssertThrowsError(try decode(payload), file: file, line: line) { error in
      XCTAssertTrue(error is DecodingError, file: file, line: line)
    }
  }

  func testKnownAndFutureUpstreamOutcomesRemainDistinct() throws {
    for status in ["deleted", "unsupported", "not_applicable", "future-status"] {
      let value = try decode(
        body([
          "openrouter": "deleted", "upstream": ["provider": "OpenAI", "status": status],
        ]))
      XCTAssertEqual(value.id, "batch-1")
      XCTAssertEqual(value.object, "batch")
      XCTAssertEqual(value.deletion.openRouter, "deleted")
      XCTAssertEqual(value.deletion.upstream, .init(provider: "OpenAI", status: status))
      XCTAssertEqual(try raw(value), value.rawPayload)
    }
    XCTAssertNil(try decode(body()).deletion.upstream)
  }

  func testUnknownExtensionsAndTypedMutationsPreserveAuthoritativePayload() throws {
    var payload = body([
      "openrouter": "deleted", "extra": ["nested": true],
      "upstream": ["provider": "Future", "status": "future", "extra": [1, 2]],
    ])
    payload["extra"] = ["nullable": NSNull()]
    var value = try decode(payload)
    let expected = try JSONDecoder().decode(
      JSONValue.self, from: JSONSerialization.data(withJSONObject: payload))
    XCTAssertEqual(value.rawPayload, expected)
    value.id = "changed"
    value.object = "changed"
    value.deletion.openRouter = "changed"
    value.deletion.upstream = nil
    XCTAssertEqual(try raw(value), expected)
    XCTAssertEqual(
      try JSONDecoder().decode(BatchDeleteResponse.self, from: JSONEncoder().encode(value)),
      try decode(payload))
  }

  func testStrictMarkers() {
    var payload = body()
    payload["object"] = "file"
    assertInvalid(payload)
    for marker in ["unsupported", "not_applicable", "future", "Deleted", ""] {
      assertInvalid(body(["openrouter": marker]))
    }
  }

  func testRequiredTopLevelFieldsAndTypes() {
    for key in ["id", "object", "deletion"] {
      var payload = body()
      payload.removeValue(forKey: key)
      assertInvalid(payload)
      for invalid: Any in [NSNull(), 1, true, []] {
        payload[key] = invalid
        assertInvalid(payload)
      }
    }
    assertInvalid(body("deleted"))
    assertInvalid(body([:]))
    for invalid: Any in [NSNull(), 1, true, [], [:]] {
      assertInvalid(body(["openrouter": invalid]))
    }
  }

  func testUpstreamIsOptionalButNotNullableAndRequiresProviderAndStatus() {
    for invalid: Any in [NSNull(), "deleted", 1, true, []] {
      assertInvalid(body(["openrouter": "deleted", "upstream": invalid]))
    }
    for key in ["provider", "status"] {
      var upstream: [String: Any] = ["provider": "OpenAI", "status": "deleted"]
      upstream.removeValue(forKey: key)
      assertInvalid(body(["openrouter": "deleted", "upstream": upstream]))
      for invalid: Any in [NSNull(), 1, true, [], [:]] {
        upstream[key] = invalid
        assertInvalid(body(["openrouter": "deleted", "upstream": upstream]))
      }
    }
    assertInvalid(
      body([
        "openrouter": "deleted", "upstream": ["provider": "", "status": "deleted"],
      ]))
  }

  func testPublicConstructorsBuildPayloadAndHonorRawOverride() throws {
    let minimal = BatchDeleteResponse(id: "batch-1", deletion: .init())
    XCTAssertEqual(
      try raw(minimal),
      .object([
        "id": .string("batch-1"), "object": .string("batch"),
        "deletion": .object(["openrouter": .string("deleted")]),
      ]))
    let upstream = BatchUpstreamDeletion(provider: "Anthropic", status: "unsupported")
    let targets = BatchDeletionTargets(openRouter: "deleted", upstream: upstream)
    let full = BatchDeleteResponse(id: "batch-1", object: "batch", deletion: targets)
    XCTAssertEqual(
      try JSONDecoder().decode(BatchDeleteResponse.self, from: JSONEncoder().encode(full)), full)
    XCTAssertEqual(
      try JSONDecoder().decode(BatchDeletionTargets.self, from: JSONEncoder().encode(targets)),
      targets)
    XCTAssertEqual(try raw(BatchDeletionTargets()), .object(["openrouter": .string("deleted")]))
    let override: JSONValue = .object(["authoritative": .bool(true)])
    var custom = BatchDeleteResponse(id: "b", deletion: targets, rawPayload: override)
    XCTAssertEqual(try raw(custom), override)
    custom.rawPayload = minimal.rawPayload
    XCTAssertEqual(try raw(custom), minimal.rawPayload)
  }
}
