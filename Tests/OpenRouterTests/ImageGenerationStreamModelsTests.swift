import Foundation
import XCTest

@testable import OpenRouter

final class ImageGenerationStreamModelsTests: XCTestCase {
  private func event(_ fields: [String: Any]) throws -> ImageGenerationStreamEvent {
    try decode(["data": fields])
  }

  private func decode(_ root: [String: Any]) throws -> ImageGenerationStreamEvent {
    try JSONDecoder().decode(
      ImageGenerationStreamEvent.self, from: JSONSerialization.data(withJSONObject: root))
  }

  private func raw<T: Encodable>(_ value: T) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
  }

  func testKnownSnapshots() throws {
    let partial = try event([
      "type": "image_generation.partial_image", "partial_image_index": -2, "b64_json": "opaque",
    ])
    XCTAssertEqual(partial.partialImageIndex, -2)
    XCTAssertEqual(partial.b64JSON, "opaque")
    XCTAssertNil(partial.eventName)
    let text = try event([
      "type": "image_generation.text_chunk", "text": "<svg", "phase": "future",
    ])
    XCTAssertEqual(text.text, "<svg")
    XCTAssertEqual(text.phase, "future")
    let completed = try event([
      "type": "image_generation.completed", "b64_json": "final", "created": -1,
      "media_type": "image/svg+xml",
      "usage": ["prompt_tokens": 1, "completion_tokens": 2, "total_tokens": 3],
    ])
    XCTAssertEqual(completed.b64JSON, "final")
    XCTAssertEqual(completed.created, -1)
    XCTAssertEqual(completed.mediaType, "image/svg+xml")
    XCTAssertEqual(completed.usage?.totalTokens, 3)
    let failure = try event([
      "type": "error",
      "error": [
        "message": "failed", "code": NSNull(), "param": NSNull(), "type": "provider",
        "extra": true,
      ],
    ])
    XCTAssertEqual(failure.error?.message, "failed")
    XCTAssertNil(failure.error?.code)
    XCTAssertNil(failure.error?.param)
    XCTAssertEqual(failure.error?.type, "provider")
    XCTAssertEqual(try raw(failure.error!), failure.error?.rawPayload)
    XCTAssertNotEqual(failure.error?.rawPayload, failure.rawPayload)
  }

  func testStrictKnownRequirements() throws {
    let variants: [[String: Any]] = [
      ["type": "image_generation.partial_image", "partial_image_index": 0, "b64_json": "x"],
      ["type": "image_generation.text_chunk", "text": "x", "phase": "content"],
      ["type": "image_generation.completed", "b64_json": "x", "created": 1],
      ["type": "error", "error": ["message": "x"]],
    ]
    for fields in variants {
      for key in fields.keys {
        var missing = fields
        missing.removeValue(forKey: key)
        XCTAssertThrowsError(try event(missing), key)
        var wrong = fields
        wrong[key] = false
        XCTAssertThrowsError(try event(wrong), key)
      }
    }
    for root in [[:], ["data": NSNull()], ["data": [:]], ["data": ["type": 1]]] {
      XCTAssertThrowsError(try decode(root))
    }
    for fields in [
      [String: Any](), ["message": 1], ["message": "x", "code": 2],
      ["message": "x", "param": false], ["message": "x", "type": []],
    ] {
      XCTAssertThrowsError(try event(["type": "error", "error": fields]))
    }
    for optional in ["media_type", "usage"] {
      XCTAssertThrowsError(
        try event([
          "type": "image_generation.completed", "b64_json": "x", "created": 1,
          optional: false,
        ]))
    }
  }

  func testUnknownAndMetadataAndRawAuthority() throws {
    var unknown = try event([
      "type": "future", "b64_json": 42, "created": false, "error": [], "phase": 7,
    ])
    XCTAssertEqual(unknown.type, "future")
    XCTAssertNil(unknown.b64JSON)
    XCTAssertNil(unknown.created)
    XCTAssertNil(unknown.error)
    let original = unknown.rawPayload
    unknown.eventName = "image_generation.completed"
    unknown.type = "changed"
    unknown.b64JSON = "changed"
    XCTAssertEqual(try raw(unknown), original)
    let reconstructed = try ImageGenerationStreamEvent(
      rawPayload: original, eventName: "mismatched")
    XCTAssertEqual(reconstructed.type, "future")
    XCTAssertEqual(reconstructed.eventName, "mismatched")
    XCTAssertNil(
      try JSONDecoder().decode(
        ImageGenerationStreamEvent.self, from: JSONEncoder().encode(reconstructed)
      ).eventName)
    var provider = ImageGenerationProviderError(message: "original", code: "code")
    provider.message = "changed"
    XCTAssertEqual(try raw(provider), provider.rawPayload)
  }

  func testBufferedRoundTrip() throws {
    let response = ImageGenerationResponse(
      created: 5, data: [.init(b64JSON: "one"), .init(b64JSON: "two")],
      usage: .init(promptTokens: 1, completionTokens: 2, totalTokens: 3))
    let normalized = ImageGenerationStreamEvent(bufferedResponse: response)
    XCTAssertEqual(normalized.type, "image_generation.buffered_response")
    XCTAssertEqual(normalized.bufferedResponse?.data.count, 2)
    XCTAssertEqual(normalized.created, 5)
    XCTAssertEqual(normalized.usage, response.usage)
    XCTAssertNil(normalized.b64JSON)
    XCTAssertEqual(try raw(normalized), response.rawPayload)
    XCTAssertEqual(
      try JSONDecoder().decode(
        ImageGenerationStreamEvent.self, from: JSONEncoder().encode(normalized)), normalized)
    XCTAssertThrowsError(try decode(["data": []]))
  }

  func testSharedRequestEncoderPreservesAllFieldsAndIntegerSeed() throws {
    struct Streaming: Encodable {
      let request: ImageGenerationRequest
      func encode(to encoder: Encoder) throws { try request.encode(to: encoder, stream: true) }
    }
    let request = ImageGenerationRequest(
      model: "m", prompt: "p", aspectRatio: "a", background: "b",
      inputReferences: [.init(url: "data:image/png;base64,x")], n: 2,
      outputCompression: 90, outputFormat: "png",
      provider: .init(
        only: ["p"], ignore: ["q"], order: ["p"], allowFallbacks: true,
        sort: .string("price"), options: ["p": ["future": .bool(true)]]),
      quality: "q", resolution: "r", seed: Int.max, sessionID: "s", size: "s",
      trace: ["x": .string("y")], user: "u")
    let normal = try JSONEncoder().encode(request)
    let streaming = try JSONEncoder().encode(Streaming(request: request))
    let normalObject =
      try XCTUnwrap(JSONSerialization.jsonObject(with: normal) as? NSDictionary)
      .mutableCopy() as! NSMutableDictionary
    let streamObject = try JSONSerialization.jsonObject(with: streaming) as! NSDictionary
    XCTAssertEqual(normalObject["stream"] as? Bool, false)
    XCTAssertEqual(streamObject["stream"] as? Bool, true)
    normalObject["stream"] = true
    XCTAssertEqual(normalObject, streamObject)
    XCTAssertEqual(streamObject["seed"] as? Int, Int.max)
    XCTAssertEqual(
      try JSONDecoder().decode(ImageGenerationRequest.self, from: normal).seed, Int.max)
    XCTAssertFalse(request.stream)
    XCTAssertThrowsError(try JSONDecoder().decode(ImageGenerationRequest.self, from: streaming))
  }
}
