import Foundation
import OpenRouter
import XCTest

final class BatchModelsTests: XCTestCase {
  private var snapshot: [String: Any] {
    [
      "id": "batch-1", "object": "batch", "endpoint": "/chat/completions", "model": "test/model",
      "completion_window": "24h", "status": "validating", "created_at": 123,
      "finalized_at": NSNull(), "provider": NSNull(), "expires_at": NSNull(),
      "request_counts": ["total": 1, "completed": 0, "failed": 0],
      "usage": NSNull(), "results": NSNull(), "error": NSNull(),
    ]
  }

  private func decode<T: Decodable>(_ type: T.Type, _ value: [String: Any]) throws -> T {
    try JSONDecoder().decode(type, from: JSONSerialization.data(withJSONObject: value))
  }

  private func raw<T: Encodable>(_ value: T) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
  }

  func testMinimalAndFullSubmission() throws {
    let item = BatchRequestItem(
      customID: "item-1", body: ["input": .array([.string("hello"), .null])])
    let minimal = CreateBatchRequest(endpoint: "/embeddings", model: "test/model", requests: [item])
    XCTAssertEqual(
      try raw(minimal),
      .object([
        "endpoint": .string("/embeddings"), "model": .string("test/model"),
        "requests": .array([.object(["custom_id": .string("item-1"), "body": .object(item.body)])]),
      ]))
    let full = CreateBatchRequest(
      endpoint: "/embeddings", model: "test/model", requests: [item], completionWindow: "24h",
      provider: .init(only: ["future"], allowFallbacks: false),
      callbackURL: "https://example.com/callback")
    let encoded = try JSONEncoder().encode(full)
    XCTAssertEqual(try JSONDecoder().decode(CreateBatchRequest.self, from: encoded), full)
    let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    XCTAssertEqual(fields["completion_window"] as? String, "24h")
    XCTAssertEqual(fields["callback_url"] as? String, full.callbackURL)
    let provider = try XCTUnwrap(fields["provider"] as? [String: Any])
    XCTAssertEqual(Set(provider.keys), ["only", "allow_fallbacks"])
    XCTAssertEqual(provider["allow_fallbacks"] as? Bool, false)
    XCTAssertEqual(try raw(BatchProviderPreferences()), .object([:]))
    let nulls = try decode(
      CreateBatchRequest.self,
      [
        "endpoint": "x", "model": "m", "requests": [], "provider": NSNull(),
        "callback_url": NSNull(), "completion_window": NSNull(),
      ])
    XCTAssertNil(nulls.provider)
    XCTAssertEqual(
      try raw(nulls),
      .object(["endpoint": .string("x"), "model": .string("m"), "requests": .array([])]))
  }

  func testSubmissionRejectsNonObjectBodiesAndMissingRequests() throws {
    for body: Any in [NSNull(), "text", 1, [1, 2]] {
      XCTAssertThrowsError(try decode(BatchRequestItem.self, ["custom_id": "x", "body": body]))
    }
    XCTAssertThrowsError(try decode(BatchRequestItem.self, ["custom_id": "x"]))
    XCTAssertThrowsError(try decode(CreateBatchRequest.self, ["endpoint": "x", "model": "m"]))
    XCTAssertThrowsError(
      try decode(CreateBatchRequest.self, ["endpoint": "x", "model": "m", "requests": NSNull()]))
  }

  func testValidatingCompletedAndFailedSnapshots() throws {
    let validating = try decode(BatchObject.self, snapshot)
    XCTAssertEqual(validating.createdAt, 123)
    XCTAssertNil(validating.results)
    XCTAssertNil(validating.finalizedAt)
    XCTAssertNil(validating.expiresAt)
    XCTAssertNil(validating.provider)
    XCTAssertNil(validating.usage)
    XCTAssertNil(validating.error)
    var completed = snapshot
    completed["status"] = "completed"
    completed["finalized_at"] = 456
    completed["expires_at"] = 789
    completed["provider"] = "future-provider"
    completed["results"] = []
    completed["request_counts"] = ["total": 1, "completed": 1, "failed": 0]
    let value = try decode(BatchObject.self, completed)
    XCTAssertEqual(value.finalizedAt, 456)
    XCTAssertEqual(value.expiresAt, 789)
    XCTAssertEqual(value.results, [])
    XCTAssertEqual(value.requestCounts.completed, 1)
    var failed = snapshot
    failed["status"] = "failed"
    failed["error"] = ["message": "Payment required", "code": 402, "extra": true]
    let failure = try decode(BatchObject.self, failed)
    XCTAssertEqual(failure.error, BatchError(message: "Payment required", code: 402))
    XCTAssertEqual(try raw(failure), failure.rawPayload)
  }

  func testEndpointBodiesAndPerResultErrors() throws {
    let bodies: [JSONValue] = [
      .object([
        "object": .string("chat.completion"),
        "choices": .array([.object(["message": .object(["content": .string("hello")])])]),
      ]),
      .object([
        "object": .string("response"), "output": .array([.object(["type": .string("message")])]),
      ]),
      .object([
        "type": .string("message"),
        "content": .array([.object(["type": .string("text"), "text": .string("hello")])]),
      ]),
      .object([
        "object": .string("list"), "data": .array([.object(["embedding": .array([.number(0.5)])])]),
      ]),
      .object(["future": .array([.null, .bool(true), .number(2)])]),
    ]
    for body in bodies {
      let result = BatchResult(
        id: "r", customID: "c", response: .init(statusCode: 200, requestID: "req", body: body))
      let decoded = try JSONDecoder().decode(BatchResult.self, from: JSONEncoder().encode(result))
      XCTAssertEqual(decoded, result)
      XCTAssertEqual(decoded.response?.body, body)
    }
    let result = BatchResult(
      id: "r", customID: "c",
      error: .init(
        type: "provider_error", message: "failed", param: "input", errorType: "future_error"))
    XCTAssertEqual(
      try JSONDecoder().decode(BatchResult.self, from: JSONEncoder().encode(result)), result)
    let nullBody = try decode(
      BatchResultResponse.self, ["status_code": 200, "request_id": NSNull(), "body": NSNull()])
    XCTAssertEqual(nullBody.body, .null)
    XCTAssertNil(nullBody.requestID)
  }

  func testFutureFieldsAndAuthoritativeRawRoundTrip() throws {
    var payload = snapshot
    payload["status"] = "future-status"
    payload["endpoint"] = "/future"
    payload["provider"] = "future-provider"
    payload["usage"] = ["cost": 0.25, "future": ["nested": [1, 2]], "nullable": NSNull()]
    payload["extension"] = ["enabled": true]
    payload["request_counts"] = ["total": 1, "completed": 1, "failed": 0, "future": 4]
    payload["results"] = [
      [
        "id": "r", "custom_id": "c", "extension": 1,
        "response": [
          "status_code": 200, "request_id": NSNull(), "body": ["future": true], "extension": 2,
        ], "error": ["type": "future", "message": "m", "param": NSNull(), "extension": 3],
      ]
    ]
    var batch = try decode(BatchObject.self, payload)
    let original = batch.rawPayload
    XCTAssertEqual(batch.status, "future-status")
    XCTAssertEqual(batch.provider, "future-provider")
    XCTAssertEqual(
      batch.usage,
      .object([
        "cost": .number(0.25), "future": .object(["nested": .array([.number(1), .number(2)])]),
        "nullable": .null,
      ]))
    batch.status = "changed"
    batch.results = nil
    XCTAssertEqual(try raw(batch), original)
    XCTAssertEqual(try decode(BatchObject.self, payload).rawPayload, original)
  }

  func testListMetadataAndFutureResults() throws {
    let empty = try decode(
      BatchListResponse.self,
      ["object": "list", "data": [], "first_id": NSNull(), "last_id": NSNull(), "has_more": false])
    XCTAssertEqual(empty.data, [])
    XCTAssertNil(empty.firstID)
    XCTAssertNil(empty.lastID)
    XCTAssertFalse(empty.hasMore)
    var entry = snapshot
    entry["results"] = [["id": "r", "custom_id": "c", "response": NSNull(), "error": NSNull()]]
    var page = try decode(
      BatchListResponse.self,
      [
        "object": "list", "data": [entry], "first_id": "batch-1", "last_id": "batch-1",
        "has_more": true, "future": 1,
      ])
    XCTAssertEqual(page.data[0].results?.count, 1)
    XCTAssertEqual(page.firstID, "batch-1")
    XCTAssertEqual(page.lastID, "batch-1")
    XCTAssertTrue(page.hasMore)
    let original = page.rawPayload
    page.data = []
    XCTAssertEqual(try raw(page), original)
  }

  func testRequiredFieldsAndTypesAreValidated() throws {
    for key in [
      "id", "object", "endpoint", "model", "completion_window", "status", "created_at",
      "request_counts",
    ] {
      var payload = snapshot
      payload.removeValue(forKey: key)
      XCTAssertThrowsError(try decode(BatchObject.self, payload), key)
      payload[key] = NSNull()
      XCTAssertThrowsError(try decode(BatchObject.self, payload), key)
    }
    for (key, value): (String, Any) in [
      ("id", 1), ("created_at", "123"), ("provider", 2), ("results", "bad"),
      ("finalized_at", "456"),
    ] {
      var payload = snapshot
      payload[key] = value
      XCTAssertThrowsError(try decode(BatchObject.self, payload), key)
    }
    for counts: [String: Any] in [
      ["total": 1, "completed": 0], ["total": "1", "completed": 0, "failed": 0],
    ] {
      var payload = snapshot
      payload["request_counts"] = counts
      XCTAssertThrowsError(try decode(BatchObject.self, payload))
    }
    XCTAssertThrowsError(try decode(BatchResultResponse.self, ["status_code": 200]))
    XCTAssertThrowsError(try decode(BatchResultResponse.self, ["status_code": "200", "body": [:]]))
    XCTAssertThrowsError(try decode(BatchResult.self, ["custom_id": "c"]))
    XCTAssertThrowsError(
      try decode(BatchListResponse.self, ["object": "list", "data": [], "has_more": "false"]))
  }

  func testPublicTypedConstructorsBuildPayloads() throws {
    let batch = BatchObject(
      id: "b", object: "batch", endpoint: "/future", model: "m", completionWindow: "24h",
      status: "completed", createdAt: 1, finalizedAt: 2, provider: "p", expiresAt: 3,
      requestCounts: .init(total: 2, completed: 1, failed: 1), usage: .object(["cost": .number(1)]),
      results: [
        .init(
          id: "r", customID: "c",
          response: .init(statusCode: 200, body: .object(["ok": .bool(true)]))),
        .init(
          id: "e", customID: "d",
          error: .init(type: "error", message: "failed", errorType: "server")),
      ], error: .init(message: "partial", code: 402))
    XCTAssertEqual(
      try JSONDecoder().decode(BatchObject.self, from: JSONEncoder().encode(batch)), batch)
    let page = BatchListResponse(
      object: "list", data: [batch], firstID: "b", lastID: "b", hasMore: false)
    XCTAssertEqual(
      try JSONDecoder().decode(BatchListResponse.self, from: JSONEncoder().encode(page)), page)
    let override: JSONValue = .object(["authoritative": .bool(true)])
    XCTAssertEqual(
      try raw(BatchListResponse(object: "list", data: [], hasMore: false, rawPayload: override)),
      override)
    var custom = batch
    custom.rawPayload = override
    XCTAssertEqual(try raw(custom), override)
  }
}
