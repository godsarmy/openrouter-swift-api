import Foundation
import XCTest

@testable import OpenRouter

final class FileResponsesTests: XCTestCase {
  private let native: [String: Any] = [
    "id": "native", "type": "file", "filename": "a.txt", "mime_type": "text/plain",
    "size_bytes": 3, "created_at": "2026-01-01", "downloadable": true, "extra": ["x": 1],
  ]
  private let openAI: [String: Any] = [
    "id": "ai", "object": "file", "filename": "b.txt", "bytes": 4,
    "created_at": 123, "purpose": "future-purpose", "status": "future-status", "extra": true,
  ]

  private func decode<T: Decodable>(_ type: T.Type, _ object: [String: Any]) throws -> T {
    try JSONDecoder().decode(type, from: JSONSerialization.data(withJSONObject: object))
  }

  private func raw<T: Encodable>(_ value: T) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
  }

  func testTaggedShapesAndWireRoundTrips() throws {
    for shape in ["openrouter", "anthropic", "openai"] {
      var payload = shape == "openai" ? openAI : native
      payload["_shape"] = shape
      let file = try decode(FileResponse.self, payload)
      switch (shape, file) {
      case ("openrouter", .openRouter), ("anthropic", .anthropic):
        XCTAssertEqual(file.id, "native")
      case ("openai", .openAI(let metadata)):
        XCTAssertEqual(metadata.purpose, "future-purpose")
        XCTAssertEqual(metadata.status, "future-status")
      default: XCTFail("Incorrect selected case")
      }
      XCTAssertNotNil(file.filename)
      XCTAssertEqual(try raw(file), try decode(JSONValue.self, payload))
    }
  }

  func testLegacyInference() throws {
    guard case .openRouter = try decode(FileResponse.self, native) else {
      return XCTFail("Expected native")
    }
    guard case .openAI = try decode(FileResponse.self, openAI) else {
      return XCTFail("Expected OpenAI")
    }
    var numericDate = openAI
    numericDate["object"] = "future-object"
    guard case .openAI = try decode(FileResponse.self, numericDate) else {
      return XCTFail("Expected numeric date inference")
    }
    var objectHint = openAI
    objectHint["created_at"] = "invalid"
    XCTAssertThrowsError(try decode(FileResponse.self, objectHint))
    var provider = native
    provider["provider"] = "openai"
    guard case .openRouter = try decode(FileResponse.self, provider) else {
      return XCTFail("Provider must not select shape")
    }
  }

  func testMalformedKnownShapesNeverFallBack() throws {
    for shape in ["openrouter", "anthropic", "openai"] {
      var payload = shape == "openai" ? openAI : native
      payload["_shape"] = shape
      payload.removeValue(forKey: "filename")
      XCTAssertThrowsError(try decode(FileResponse.self, payload))
      payload["filename"] = 12
      XCTAssertThrowsError(try decode(FileResponse.self, payload))
    }
    var wrongShape = native
    wrongShape["_shape"] = "openai"
    XCTAssertThrowsError(try decode(FileResponse.self, wrongShape))
    for bad: Any in [NSNull(), 1] {
      var payload = native
      payload["_shape"] = bad
      XCTAssertThrowsError(try decode(FileResponse.self, payload))
    }
  }

  func testFutureShapePreservesPayload() throws {
    let payload: [String: Any] = ["_shape": "future", "nested": ["a": [1, 2]]]
    let response = try decode(FileResponse.self, payload)
    guard case .unknown = response else { return XCTFail("Expected unknown") }
    XCTAssertNil(response.id)
    XCTAssertNil(response.filename)
    XCTAssertEqual(try raw(response), try decode(JSONValue.self, payload))
  }

  func testListsAndPagination() throws {
    let payload: [String: Any] = [
      "_shape": "anthropic", "data": [native, openAI, ["_shape": "future", "extra": true]],
      "has_more": true, "first_id": "first", "last_id": "last", "cursor": "next",
      "object": "list", "extra": [1, 2],
    ]
    let list = try decode(FileListResponse.self, payload)
    XCTAssertEqual(list.data.count, 3)
    XCTAssertTrue(list.hasMore)
    XCTAssertEqual(list.shape, "anthropic")
    XCTAssertEqual(list.firstID, "first")
    XCTAssertEqual(list.lastID, "last")
    XCTAssertEqual(list.cursor, "next")
    XCTAssertEqual(list.object, "list")
    XCTAssertEqual(try raw(list), try decode(JSONValue.self, payload))
    for extra in [[:], ["cursor": NSNull(), "first_id": NSNull(), "last_id": NSNull()]] {
      var empty: [String: Any] = ["data": [], "has_more": false]
      empty.merge(extra) { _, new in new }
      let page = try decode(FileListResponse.self, empty)
      XCTAssertTrue(page.data.isEmpty)
      XCTAssertNil(page.shape)
      XCTAssertNil(page.cursor)
    }
  }

  func testInvalidLists() throws {
    let base: [String: Any] = ["data": [], "has_more": false]
    for key in ["data", "has_more"] {
      var missing = base
      missing.removeValue(forKey: key)
      XCTAssertThrowsError(try decode(FileListResponse.self, missing))
      for bad: Any in [NSNull(), "invalid", 1] {
        var invalid = base
        invalid[key] = bad
        XCTAssertThrowsError(try decode(FileListResponse.self, invalid))
      }
    }
    for key in ["_shape", "first_id", "last_id", "cursor", "object"] {
      var invalid = base
      invalid[key] = 12
      XCTAssertThrowsError(try decode(FileListResponse.self, invalid))
    }
    var nullShape = base
    nullShape["_shape"] = NSNull()
    XCTAssertThrowsError(try decode(FileListResponse.self, nullShape))
  }

  func testInitializersAndAuthoritativeRawPayload() throws {
    var ai = OpenAIFileMetadata(
      id: "id", object: "file", filename: "file", purpose: "new", status: "new",
      bytes: 1, createdAt: 2)
    let original = ai.rawPayload
    ai.filename = "changed"
    XCTAssertEqual(try raw(ai), original)
    ai.rawPayload = .object(["_shape": .string("wrong"), "extra": .bool(true)])
    XCTAssertEqual(
      try raw(FileResponse.openAI(ai)),
      .object(["_shape": .string("openai"), "extra": .bool(true)]))
    var metadata = try decode(FileMetadata.self, native)
    metadata.rawPayload = ai.rawPayload
    for (response, shape) in [
      (FileResponse.openRouter(metadata), "openrouter"), (.anthropic(metadata), "anthropic"),
    ] {
      XCTAssertEqual(
        try raw(response), .object(["_shape": .string(shape), "extra": .bool(true)]))
    }
    let normal = FileListResponse(data: [.openAI(ai)], hasMore: false, shape: "openai")
    XCTAssertEqual(try raw(normal), normal.rawPayload)
    var page = FileListResponse(data: [], hasMore: false, rawPayload: .object(["extra": .null]))
    page.hasMore = true
    XCTAssertEqual(try raw(page), .object(["extra": .null]))
    XCTAssertEqual(FileContentDownload(data: Data([1])).data, Data([1]))
    XCTAssertNil(FileContentDownload(data: Data()).contentType)
  }
}
