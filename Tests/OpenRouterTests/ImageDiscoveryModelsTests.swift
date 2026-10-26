import Foundation
import OpenRouter
import XCTest

final class ImageDiscoveryModelsTests: XCTestCase {
  private var capabilities: [String: Any] {
    [
      "resolution": ["type": "enum", "values": ["1K", "2K", "4K"]],
      "output_compression": ["type": "range", "min": 0, "max": 100],
      "seed": ["type": "boolean"],
      "future/key": ["type": "future", "extension": ["nested": [true, false]]],
    ]
  }

  private var model: [String: Any] {
    [
      "id": "bytedance-seed/seedream-4.5", "name": "Seedream 4.5",
      "description": "A text-to-image model.", "created": 1_692_901_234,
      "architecture": ["input_modalities": ["text", "image"], "output_modalities": ["image"]],
      "supported_parameters": capabilities, "supports_streaming": false,
      "endpoints": "/api/v1/images/models/bytedance-seed/seedream-4.5/endpoints",
    ]
  }

  private var endpoint: [String: Any] {
    [
      "provider_name": "Bytedance", "provider_slug": "bytedance", "provider_tag": "bytedance",
      "supported_parameters": capabilities, "allowed_passthrough_parameters": [],
      "supports_streaming": false,
      "pricing": [["billable": "output_image", "cost_usd": 0.05, "unit": "image"]],
    ]
  }

  private func decode<T: Decodable>(_ type: T.Type, _ value: [String: Any]) throws -> T {
    try JSONDecoder().decode(type, from: JSONSerialization.data(withJSONObject: value))
  }

  private func raw<T: Encodable>(_ value: T) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
  }

  func testOfficialExamplesAndSnakeCase() throws {
    let listing = try decode(ImageModelsListResponse.self, ["data": [model]])
    let item = try XCTUnwrap(listing.data.first)
    XCTAssertEqual(item.id, "bytedance-seed/seedream-4.5")
    XCTAssertEqual(item.created, 1_692_901_234)
    XCTAssertFalse(item.supportsStreaming)
    XCTAssertEqual(item.architecture.inputModalities, ["text", "image"])
    XCTAssertEqual(item.endpoints, model["endpoints"] as? String)
    XCTAssertEqual(try raw(item), try decode(JSONValue.self, model))
    XCTAssertEqual(.object(item.supportedParameters), try decode(JSONValue.self, capabilities))
    let response = try decode(
      ImageModelEndpointsResponse.self, ["id": item.id, "endpoints": [endpoint]])
    let provider = try XCTUnwrap(response.endpoints.first)
    XCTAssertEqual(provider.providerName, "Bytedance")
    XCTAssertEqual(provider.providerSlug, "bytedance")
    XCTAssertEqual(provider.providerTag, "bytedance")
    XCTAssertFalse(provider.supportsStreaming)
    XCTAssertEqual(
      provider.pricing, [.init(billable: "output_image", unit: "image", costUSD: 0.05)])
    XCTAssertEqual(try raw(provider), try decode(JSONValue.self, endpoint))
  }

  func testEveryNonnullableFieldIsRequired() throws {
    for key in model.keys {
      var value = model
      value.removeValue(forKey: key)
      XCTAssertThrowsError(try decode(ImageModelListItem.self, value), key)
      value[key] = NSNull()
      XCTAssertThrowsError(try decode(ImageModelListItem.self, value), key)
    }
    for key in endpoint.keys where key != "provider_tag" {
      var value = endpoint
      value.removeValue(forKey: key)
      XCTAssertThrowsError(try decode(ImageEndpoint.self, value), key)
      value[key] = NSNull()
      XCTAssertThrowsError(try decode(ImageEndpoint.self, value), key)
    }
    for key in ["input_modalities", "output_modalities"] {
      var value: [String: Any] = ["input_modalities": [], "output_modalities": []]
      value.removeValue(forKey: key)
      XCTAssertThrowsError(try decode(ImageModelArchitecture.self, value))
    }
    XCTAssertThrowsError(try decode(ImageModelsListResponse.self, [:]))
    XCTAssertThrowsError(try decode(ImageModelEndpointsResponse.self, ["id": "m"]))
    XCTAssertThrowsError(try decode(ImageModelEndpointsResponse.self, ["endpoints": []]))
  }

  func testEmptyCollectionsAndFutureModalities() throws {
    let architecture = ImageModelArchitecture(inputModalities: [], outputModalities: ["future"])
    let item = ImageModelListItem(
      id: "m", name: "M", description: "", created: 0, architecture: architecture,
      supportedParameters: [:], supportsStreaming: false, endpoints: "new-relative-location")
    XCTAssertEqual(
      try JSONDecoder().decode(ImageModelListItem.self, from: JSONEncoder().encode(item)), item)
    let provider = ImageEndpoint(
      providerName: "P", providerSlug: "p", supportedParameters: [:],
      allowedPassthroughParameters: [], supportsStreaming: false, pricing: [])
    XCTAssertEqual(
      try JSONDecoder().decode(ImageEndpoint.self, from: JSONEncoder().encode(provider)), provider)
    XCTAssertEqual(try decode(ImageModelsListResponse.self, ["data": []]).data, [])
    XCTAssertEqual(
      try decode(ImageModelEndpointsResponse.self, ["id": "m", "endpoints": []]).endpoints, [])
    var nullable = endpoint
    nullable["provider_tag"] = NSNull()
    XCTAssertNil(try decode(ImageEndpoint.self, nullable).providerTag)
    nullable.removeValue(forKey: "provider_tag")
    XCTAssertNil(try decode(ImageEndpoint.self, nullable).providerTag)
  }

  func testPricingRequiredNumericAndOpenStrings() throws {
    let value: [String: Any] = ["billable": "future", "unit": "future-unit", "cost_usd": 2]
    let price = try decode(ImagePricingEntry.self, value)
    XCTAssertEqual(price, .init(billable: "future", unit: "future-unit", costUSD: 2))
    XCTAssertEqual(try raw(price), try decode(JSONValue.self, value))
    for key in value.keys {
      var missing = value
      missing.removeValue(forKey: key)
      XCTAssertThrowsError(try decode(ImagePricingEntry.self, missing))
    }
    var changed = value
    changed["cost_usd"] = "2"
    XCTAssertThrowsError(try decode(ImagePricingEntry.self, changed))
    changed = value
    changed["variant"] = NSNull()
    XCTAssertNil(try decode(ImagePricingEntry.self, changed).variant)
    changed["variant"] = "future-variant"
    XCTAssertEqual(try decode(ImagePricingEntry.self, changed).variant, "future-variant")
  }

  func testMalformedKnownFieldsFail() throws {
    for (key, wrong): (String, Any) in [
      ("created", "1692901234"), ("created", 1.5), ("supports_streaming", "false"),
      ("supported_parameters", []), ("architecture", []), ("endpoints", ["url"]),
    ] {
      var value = model
      value[key] = wrong
      XCTAssertThrowsError(try decode(ImageModelListItem.self, value), key)
    }
    for (key, wrong): (String, Any) in [
      ("pricing", [:]), ("allowed_passthrough_parameters", [:]),
      ("allowed_passthrough_parameters", [1]), ("supported_parameters", []),
      ("supports_streaming", 0), ("provider_tag", 1),
    ] {
      var value = endpoint
      value[key] = wrong
      XCTAssertThrowsError(try decode(ImageEndpoint.self, value), key)
    }
    XCTAssertThrowsError(try decode(ImageModelsListResponse.self, ["data": [:]]))
    XCTAssertThrowsError(
      try decode(ImageModelEndpointsResponse.self, ["id": "m", "endpoints": [:]]))
    XCTAssertThrowsError(
      try decode(ImageModelArchitecture.self, ["input_modalities": [1], "output_modalities": []]))
  }

  func testRawPayloadPreservesNestedExtensionsAndIsAuthoritative() throws {
    var extendedModel = model
    extendedModel["future"] = ["enabled": true]
    extendedModel["architecture"] = ["input_modalities": [], "output_modalities": [], "future": 42]
    let listPayload: [String: Any] = ["data": [extendedModel], "next": "future-page"]
    var list = try decode(ImageModelsListResponse.self, listPayload)
    XCTAssertEqual(try raw(list), try decode(JSONValue.self, listPayload))
    list.data = []
    XCTAssertEqual(try raw(list), list.rawPayload)
    var extendedEndpoint = endpoint
    extendedEndpoint["future"] = ["arbitrary": NSNull()]
    extendedEndpoint["pricing"] = [
      ["billable": "new", "unit": "new", "cost_usd": 1, "future": true]
    ]
    let payload: [String: Any] = ["id": "m", "endpoints": [extendedEndpoint], "future": [1, 2]]
    var response = try decode(ImageModelEndpointsResponse.self, payload)
    XCTAssertEqual(try raw(response), try decode(JSONValue.self, payload))
    response.id = "changed"
    response.endpoints = []
    XCTAssertEqual(try raw(response), response.rawPayload)
    response.rawPayload = .object(["replacement": .bool(true)])
    XCTAssertEqual(try raw(response), response.rawPayload)
  }

  func testConstructorsBuildSemanticRootsAndHonorExplicitRawPayload() throws {
    let item = try decode(ImageModelListItem.self, model)
    let provider = try decode(ImageEndpoint.self, endpoint)
    XCTAssertEqual(
      try raw(ImageModelsListResponse(data: [item])), try decode(JSONValue.self, ["data": [model]]))
    XCTAssertEqual(
      try raw(ImageModelEndpointsResponse(id: item.id, endpoints: [provider])),
      try decode(JSONValue.self, ["id": item.id, "endpoints": [endpoint]]))
    let authoritative = JSONValue.object(["extension": .string("only")])
    XCTAssertEqual(
      try raw(ImageModelsListResponse(data: [item], rawPayload: authoritative)), authoritative)
    XCTAssertEqual(
      try raw(
        ImageModelEndpointsResponse(id: "m", endpoints: [provider], rawPayload: authoritative)),
      authoritative)
  }
}
