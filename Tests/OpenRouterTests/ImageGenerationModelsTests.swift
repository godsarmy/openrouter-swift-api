import Foundation
import OpenRouter
import XCTest

final class ImageGenerationModelsTests: XCTestCase {
  private func decode<T: Decodable>(_ type: T.Type, _ value: [String: Any]) throws -> T {
    try JSONDecoder().decode(type, from: JSONSerialization.data(withJSONObject: value))
  }

  private func raw<T: Encodable>(_ value: T) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
  }

  func testMinimalRequestAndStrictStream() throws {
    let request = ImageGenerationRequest(model: "future/model", prompt: "")
    XCTAssertFalse(request.stream)
    XCTAssertEqual(
      try raw(request),
      .object([
        "model": .string("future/model"), "prompt": .string(""), "stream": .bool(false),
      ]))
    for stream in [true, NSNull(), "false", 0] as [Any] {
      XCTAssertThrowsError(
        try decode(
          ImageGenerationRequest.self,
          [
            "model": "m", "prompt": "p", "stream": stream,
          ])
      ) { XCTAssertTrue($0 is DecodingError) }
    }
    for fields in [
      ["model": "m", "prompt": "p"],
      ["model": "m", "prompt": "p", "stream": false],
    ] as [[String: Any]] {
      XCTAssertFalse(try decode(ImageGenerationRequest.self, fields).stream)
    }
  }

  func testAllRequestFieldsAndOpenProviderOptions() throws {
    for sort: JSONValue in [.string("future-sort"), .object(["by": .string("price")]), .null] {
      let request = ImageGenerationRequest(
        model: "m", prompt: "p", aspectRatio: "future-ratio", background: "future-background",
        inputReferences: [
          .init(url: "https://example.com/a.png"), .init(url: "http://example.com/b.png"),
          .init(url: "data:image/png;base64,not-decoded"),
        ], n: 99, outputCompression: -1, outputFormat: "future-format",
        provider: .init(
          only: ["future-provider"], ignore: ["ignored"], order: ["ordered"],
          allowFallbacks: false, sort: sort,
          options: ["future-provider": ["unknown": .object(["nested": .array([.bool(true)])])]]),
        quality: "future-quality", resolution: "future-resolution", seed: -7,
        sessionID: "session", size: "123x456",
        trace: [
          "trace_id": .string("id"), "trace_name": .string("name"),
          "span_name": .string("span"), "generation_name": .string("gen"),
          "parent_span_id": .string("parent"), "future": .array([.number(1)]),
        ], user: "u")
      let encoded = try JSONEncoder().encode(request)
      var decoded = try JSONDecoder().decode(ImageGenerationRequest.self, from: encoded)
      // Optional JSON null is semantically nil when decoded by Codable.
      if sort == .null { decoded.provider?.sort = .null }
      XCTAssertEqual(decoded, request)
      let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
      for key in [
        "aspect_ratio", "input_references", "output_compression", "output_format", "session_id",
      ] {
        XCTAssertNotNil(object[key])
      }
      XCTAssertEqual(object.count, 17)
    }
    XCTAssertEqual(try raw(ImageGenerationProviderPreferences()), .object([:]))
  }

  func testReferenceShapeIsStrict() throws {
    let url = "data:image/svg+xml;base64,PHN2Zy8+"
    XCTAssertEqual(
      try raw(ImageGenerationReference(url: url)),
      .object([
        "type": .string("image_url"), "image_url": .object(["url": .string(url)]),
      ]))
    for value: [String: Any] in [
      ["type": "text", "image_url": ["url": "x"]],
      ["type": 1, "image_url": ["url": "x"]],
      ["image_url": ["url": "x"]],
      ["type": "image_url", "image_url": [:]],
      ["type": "image_url", "image_url": ["url": 1]],
      ["type": "image_url", "image_url": "x"],
    ] {
      XCTAssertThrowsError(try decode(ImageGenerationReference.self, value))
    }
  }

  func testResponseRequiredFieldsAndOpaqueImages() throws {
    for text in ["iVBORw0KGgo=", "PHN2Zy8+", "not even base64"] {
      let response = try decode(
        ImageGenerationResponse.self,
        [
          "created": 123, "data": [["b64_json": text]],
        ])
      XCTAssertEqual(response.created, 123)
      XCTAssertEqual(response.data, [.init(b64JSON: text)])
      XCTAssertNil(response.usage)
      // A response has no requested-count constraint, even if the request asks for ten.
      XCTAssertEqual(ImageGenerationRequest(model: "m", prompt: "p", n: 10).n, 10)
      XCTAssertEqual(response.data.count, 1)
    }
    for value: [String: Any] in [
      ["data": []], ["created": "123", "data": []], ["created": 1.5, "data": []],
      ["created": 1], ["created": 1, "data": [["b64_json": 1]]],
      ["created": 1, "data": [["media_type": "image/png"]]],
    ] {
      XCTAssertThrowsError(try decode(ImageGenerationResponse.self, value))
    }
    XCTAssertNil(
      try decode(
        ImageGenerationResponse.self,
        [
          "created": 1, "data": [], "usage": NSNull(),
        ]
      ).usage)
  }

  func testUsageRequiredCountsAndNullableCost() throws {
    let counts: [String: Any] = ["prompt_tokens": 1, "completion_tokens": 2, "total_tokens": 3]
    for cost in [nil, NSNull(), 0.04] as [Any?] {
      var fields = counts
      fields["cost"] = cost
      let usage = try decode(ImageGenerationUsage.self, fields)
      XCTAssertEqual(usage.promptTokens, 1)
      XCTAssertEqual(usage.completionTokens, 2)
      XCTAssertEqual(usage.totalTokens, 3)
      XCTAssertEqual(usage.cost, cost as? Double)
    }
    for key in counts.keys {
      var missing = counts
      missing.removeValue(forKey: key)
      XCTAssertThrowsError(try decode(ImageGenerationUsage.self, missing))
      for invalid in ["1", NSNull(), true, 1.5] as [Any] {
        var fields = counts
        fields[key] = invalid
        XCTAssertThrowsError(try decode(ImageGenerationUsage.self, fields))
      }
    }
  }

  func testRawExtensionsAndEncodingAuthority() throws {
    let fields: [String: Any] = [
      "created": 1, "future": ["root": true],
      "data": [["b64_json": "PHN2Zy8+", "media_type": "image/svg+xml", "future_image": 7]],
      "usage": [
        "prompt_tokens": 1, "completion_tokens": 2, "total_tokens": 3,
        "cost": NSNull(), "cost_details": ["upstream": 0.1], "cache_creation": [:],
        "prompt_tokens_details": ["cached_tokens": 1], "iterations": [],
        "server_tool_use": ["web_search_requests": 2], "is_byok": true,
        "service_tier": "future", "speed": "future", "future_usage": [false],
      ],
    ]
    let expected = try decode(JSONValue.self, fields)
    var response = try decode(ImageGenerationResponse.self, fields)
    XCTAssertEqual(response.rawPayload, expected)
    var usage = try XCTUnwrap(response.usage)
    let usageRaw = usage.rawPayload
    usage.promptTokens = 999
    usage.cost = 100
    XCTAssertEqual(try raw(usage), usageRaw)
    response.created = 999
    response.data[0].b64JSON = "changed"
    response.usage = nil
    XCTAssertEqual(try raw(response), expected)
    XCTAssertEqual(try raw(try decode(ImageGenerationResponse.self, fields)), expected)
  }

  func testPublicConstructorsBuildSemanticPayloads() throws {
    let usage = ImageGenerationUsage(
      promptTokens: 1, completionTokens: 2, totalTokens: 3, cost: 0.04)
    XCTAssertEqual(
      try raw(usage),
      .object([
        "prompt_tokens": .number(1), "completion_tokens": .number(2),
        "total_tokens": .number(3), "cost": .number(0.04),
      ]))
    let response = ImageGenerationResponse(
      created: 42, data: [.init(b64JSON: "opaque", mediaType: "image/future")], usage: usage)
    XCTAssertEqual(
      try raw(response),
      .object([
        "created": .number(42),
        "data": .array([
          .object(["b64_json": .string("opaque"), "media_type": .string("image/future")])
        ]),
        "usage": usage.rawPayload,
      ]))
    XCTAssertEqual(
      try JSONDecoder().decode(
        ImageGenerationResponse.self,
        from: JSONEncoder().encode(response)), response)
    XCTAssertEqual(
      try raw(ImageGenerationResponse(created: 0, data: [], rawPayload: .object([:]))), .object([:])
    )
  }
}
