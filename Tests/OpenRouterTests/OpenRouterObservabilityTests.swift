import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
final class OpenRouterObservabilityTests: XCTestCase {
  private let fixture =
    #"{"api_key_hashes":null,"broadcast_generation_cost":false,"broadcast_generation_cost_allocation":false,"broadcast_generation_identity":false,"broadcast_generation_request_context":false,"config":{"secret":"CONFIG_SECRET","future":{"key":true}},"created_at":"timestamp","enabled":true,"filter_rules":null,"id":"id","name":null,"privacy_mode":false,"regions":["global"],"sampling_rate":1,"type":"future","updated_at":"timestamp","workspace_id":"workspace"}"#

  func testAllTypesNullablePresenceRoundtripAndObjectConfigs() throws {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    let object = try json(fixture)
    for type in [
      "arize", "braintrust", "clickhouse", "datadog", "grafana", "langfuse", "langsmith",
      "newrelic", "opik", "otel-collector", "posthog", "ramp", "s3", "sentry", "snowflake", "weave",
      "webhook", "future",
    ] {
      var value = object
      value["type"] = type
      let data = try JSONSerialization.data(withJSONObject: value)
      let destination = try decoder.decode(ObservabilityDestination.self, from: data)
      XCTAssertEqual(destination.type, type)
      XCTAssertEqual(
        try decoder.decode(ObservabilityDestination.self, from: encoder.encode(destination)),
        destination)
      let encoded =
        try JSONSerialization.jsonObject(with: encoder.encode(destination)) as! [String: Any]
      for key in ["name", "api_key_hashes", "filter_rules"] {
        XCTAssertTrue(encoded[key] is NSNull, key)
      }
      // Create and update responses are aliases of this same envelope.
      let response = try decoder.decode(
        GetObservabilityDestinationResponse.self,
        from: JSONSerialization.data(withJSONObject: ["data": value]))
      XCTAssertEqual(response.data, destination)
      XCTAssertEqual(
        try decoder.decode(
          GetObservabilityDestinationResponse.self, from: encoder.encode(response)), response)
      let list = try decoder.decode(
        ListObservabilityDestinationsResponse.self,
        from: JSONSerialization.data(withJSONObject: ["data": [value], "total_count": 1]))
      XCTAssertEqual(list.data, [destination])
      XCTAssertEqual(
        try decoder.decode(ListObservabilityDestinationsResponse.self, from: encoder.encode(list)),
        list)
    }
    for key in object.keys {
      var missing = object
      missing.removeValue(forKey: key)
      XCTAssertThrowsError(
        try decoder.decode(
          ObservabilityDestination.self, from: JSONSerialization.data(withJSONObject: missing)), key
      )
    }
    for bad: Any in [[], "secret", 1, true, NSNull()] {
      var value = object
      value["config"] = bad
      XCTAssertThrowsError(
        try decoder.decode(
          ObservabilityDestination.self, from: JSONSerialization.data(withJSONObject: value)))
      XCTAssertThrowsError(
        try decoder.decode(
          CreateObservabilityDestinationRequest.self,
          from: JSONSerialization.data(withJSONObject: [
            "type": "future", "name": "n", "config": bad,
          ])))
      XCTAssertThrowsError(
        try decoder.decode(
          UpdateObservabilityDestinationRequest.self,
          from: JSONSerialization.data(withJSONObject: ["config": bad])))
    }
    for invalid in [#"{}"#, #"{"deleted":false}"#, #"{"deleted":null}"#] {
      XCTAssertThrowsError(
        try decoder.decode(DeleteObservabilityDestinationResponse.self, from: Data(invalid.utf8)))
    }
  }

  func testPatchTriStateAndAllWireKeys() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    XCTAssertEqual(
      try JSONSerialization.jsonObject(
        with: encoder.encode(UpdateObservabilityDestinationRequest())) as! NSDictionary, [:])
    let full =
      #"{"api_key_hashes":["hash"],"broadcast_generation_cost":false,"broadcast_generation_cost_allocation":false,"broadcast_generation_identity":false,"broadcast_generation_request_context":false,"config":{"masked":"****","secret":"CONFIG_SECRET"},"enabled":false,"filter_rules":{"enabled":false,"groups":[{"logic":"future","rules":[{"field":"input","operator":"future","value":"FILTER_SECRET"},{"field":"total_cost","operator":"gt","value":0.125},{"field":"output","operator":"exists"}]}]},"name":"n","privacy_mode":false,"regions":["eu"],"sampling_rate":-1}"#
    let patch = try decoder.decode(
      UpdateObservabilityDestinationRequest.self, from: Data(full.utf8))
    XCTAssertEqual(
      try JSONSerialization.jsonObject(with: encoder.encode(patch)) as! NSDictionary,
      try json(full) as NSDictionary)
    XCTAssertEqual(
      try decoder.decode(UpdateObservabilityDestinationRequest.self, from: encoder.encode(patch)),
      patch)
    let clear = UpdateObservabilityDestinationRequest(apiKeyHashes: .null, filterRules: .null)
    XCTAssertEqual(
      try JSONSerialization.jsonObject(with: encoder.encode(clear)) as! NSDictionary,
      ["api_key_hashes": NSNull(), "filter_rules": NSNull()])
    XCTAssertEqual(
      try decoder.decode(UpdateObservabilityDestinationRequest.self, from: encoder.encode(clear)),
      clear)
    let create = try decoder.decode(
      CreateObservabilityDestinationRequest.self,
      from: Data((String(full.dropLast()) + #", "type":"future","workspace_id":"workspace"}"#).utf8)
    )
    XCTAssertEqual(
      try decoder.decode(CreateObservabilityDestinationRequest.self, from: encoder.encode(create)),
      create)
    XCTAssertNotNil(
      try JSONSerialization.jsonObject(with: encoder.encode(create)) as? [String: Any])
    for value in ["true", "{}", "[]"] {
      XCTAssertThrowsError(
        try decoder.decode(ObservabilityFilterValue.self, from: Data(value.utf8)))
    }
    XCTAssertEqual(
      try decoder.decode(ObservabilityFilterValue.self, from: Data("0.125".utf8)), .number(0.125))
    XCTAssertThrowsError(
      try decoder.decode(ObservabilityFilterRulesConfig.self, from: Data("{}".utf8)))
    XCTAssertThrowsError(
      try decoder.decode(ObservabilityFilterRuleGroup.self, from: Data("{}".utf8)))
  }

  func testSensitiveDiagnosticsIncludingEnvelopes() throws {
    let decoder = JSONDecoder()
    var object = try json(fixture)
    object["filter_rules"] = [
      "groups": [["rules": [["field": "input", "operator": "equals", "value": "FILTER_SECRET"]]]]
    ]
    let destination = try decoder.decode(
      ObservabilityDestination.self, from: JSONSerialization.data(withJSONObject: object))
    let create = CreateObservabilityDestinationRequest(
      type: "future", name: "n", config: ["secret": .string("CONFIG_SECRET")],
      filterRules: destination.filterRules)
    let patch = UpdateObservabilityDestinationRequest(
      config: create.config, filterRules: .value(destination.filterRules!))
    let values: [Any] = [
      destination, create, patch, GetObservabilityDestinationResponse(data: destination),
      ListObservabilityDestinationsResponse(data: [destination], totalCount: 1),
      destination.filterRules!, destination.filterRules!.groups[0],
      destination.filterRules!.groups[0].rules[0], ObservabilityFilterValue.string("FILTER_SECRET"),
    ]
    for value in values {
      var dumped = ""
      dump(value, to: &dumped)
      for output in [
        String(describing: value), String(reflecting: value), dumped,
        String(describing: Mirror(reflecting: value).children.map { $0.value }),
      ] {
        XCTAssertFalse(output.contains("CONFIG_SECRET"), output)
        XCTAssertFalse(output.contains("FILTER_SECRET"), output)
      }
    }
    XCTAssertTrue(
      String(decoding: try JSONEncoder().encode(destination), as: UTF8.self).contains(
        "CONFIG_SECRET"))
  }

  func testServerErrorsAndBoundsPassThrough() async throws {
    for status in [400, 401, 403, 404, 409, 500] {
      let options = RequestOptions(extraHeaders: ["X-Status": String(status)])
      do {
        _ = try await client().observability.destinations.list(
          offset: -1, limit: 101, options: options)
        XCTFail("Expected server error")
      } catch OpenRouterError.apiError(let statusCode, _, _, _) {
        XCTAssertEqual(statusCode, status)
      } catch { XCTFail("Unexpected error: \(error)") }
    }
    do {
      _ = try await client(key: nil).listObservabilityDestinations()
      XCTFail("Missing authentication should fail locally")
    } catch OpenRouterError.missingAPIKey {
    } catch { XCTFail("Unexpected error: \(error)") }
  }

  func testAllOperationErrorPropagationAndMissingAuth() async throws {
    for operation in 0..<5 {
      for status in [400, 401, 403, 404, 409, 500] {
        let options = RequestOptions(extraHeaders: ["X-Status": String(status)])
        do {
          try await invoke(operation, client: client(), options: options)
          XCTFail("Expected error for operation \(operation), status \(status)")
        } catch OpenRouterError.apiError(let statusCode, _, _, _) {
          XCTAssertEqual(statusCode, status)
        } catch { XCTFail("Unexpected error: \(error)") }
      }
      do {
        try await invoke(operation, client: client(key: nil), options: nil)
        XCTFail("Missing auth must fail for operation \(operation)")
      } catch OpenRouterError.missingAPIKey {
      } catch { XCTFail("Unexpected error: \(error)") }
    }
    // Bounds, empty arrays, aliases and masked provider values remain server decisions.
    let options = RequestOptions(extraHeaders: [
      "X-Status": "400", "X-Method": "PATCH", "X-Path": "/api/v1/observability/destinations/id",
      "X-Query": "{}",
      "X-Body":
        #"{"api_key_hashes":[],"config":{"key":"****"},"regions":["eu"],"sampling_rate":2}"#,
    ])
    do {
      _ = try await client().updateObservabilityDestination(
        id: "id",
        UpdateObservabilityDestinationRequest(
          apiKeyHashes: .value([]), config: ["key": .string("****")], regions: ["eu"],
          samplingRate: 2), options: options)
      XCTFail("Expected mocked server validation")
    } catch OpenRouterError.apiError(let statusCode, _, _, _) {
      XCTAssertEqual(statusCode, 400)
    } catch { XCTFail("Unexpected error: \(error)") }
  }

  private func invoke(_ operation: Int, client: OpenRouterClient, options: RequestOptions?)
    async throws
  {
    switch operation {
    case 0: _ = try await client.listObservabilityDestinations(options: options)
    case 1:
      _ = try await client.createObservabilityDestination(
        CreateObservabilityDestinationRequest(type: "future", name: "n", config: [:]),
        options: options)
    case 2: _ = try await client.getObservabilityDestination(id: "id", options: options)
    case 3:
      _ = try await client.updateObservabilityDestination(
        id: "id", UpdateObservabilityDestinationRequest(), options: options)
    default: _ = try await client.deleteObservabilityDestination(id: "id", options: options)
    }
  }

  private func json(_ text: String) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: Data(text.utf8)) as! [String: Any]
  }
  func testAllOperationsAndAliases() async throws {
    for alias in [false, true] {
      for filtered in [false, true] {
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "GET", "X-Path": "/api/v1/observability/destinations",
            "X-Query": filtered ? #"{"offset":"2","limit":"3","workspace_id":"workspace"}"# : "{}",
            "X-Body": #"{}"#,
            "X-Response":
              #"{"data":[{"api_key_hashes":null,"broadcast_generation_cost":false,"broadcast_generation_cost_allocation":false,"broadcast_generation_identity":false,"broadcast_generation_request_context":false,"config":{"baseUrl":"https://us.cloud.langfuse.com","publicKey":"pk-l...EfGh","secretKey":"sk-l...AbCd"},"created_at":"2025-08-24T10:30:00Z","enabled":true,"filter_rules":null,"id":"99999999-aaaa-bbbb-cccc-dddddddddddd","name":"Production Langfuse","privacy_mode":false,"regions":["global"],"sampling_rate":1,"type":"langfuse","updated_at":"2025-08-24T15:45:00Z","workspace_id":"550e8400-e29b-41d4-a716-446655440000"}],"total_count":1}"#,
            "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().observability.destinations.list(
              offset: filtered ? 2 : nil, limit: filtered ? 3 : nil,
              workspaceID: filtered ? "workspace" : nil, options: options)
            : client().listObservabilityDestinations(
              offset: filtered ? 2 : nil, limit: filtered ? 3 : nil,
              workspaceID: filtered ? "workspace" : nil, options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              ListObservabilityDestinationsResponse.self,
              from: Data(
                #"{"data":[{"api_key_hashes":null,"broadcast_generation_cost":false,"broadcast_generation_cost_allocation":false,"broadcast_generation_identity":false,"broadcast_generation_request_context":false,"config":{"baseUrl":"https://us.cloud.langfuse.com","publicKey":"pk-l...EfGh","secretKey":"sk-l...AbCd"},"created_at":"2025-08-24T10:30:00Z","enabled":true,"filter_rules":null,"id":"99999999-aaaa-bbbb-cccc-dddddddddddd","name":"Production Langfuse","privacy_mode":false,"regions":["global"],"sampling_rate":1,"type":"langfuse","updated_at":"2025-08-24T15:45:00Z","workspace_id":"550e8400-e29b-41d4-a716-446655440000"}],"total_count":1}"#
                  .utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "POST", "X-Path": "/api/v1/observability/destinations",
            "X-Query": filtered ? #"{}"# : "{}",
            "X-Body": #"{"type":"future-value","name":"future-value","config":{}}"#,
            "X-Response":
              #"{"data":{"api_key_hashes":null,"broadcast_generation_cost":false,"broadcast_generation_cost_allocation":false,"broadcast_generation_identity":false,"broadcast_generation_request_context":false,"config":{"baseUrl":"https://us.cloud.langfuse.com","publicKey":"pk-l...EfGh","secretKey":"sk-l...AbCd"},"created_at":"2025-08-24T10:30:00Z","enabled":true,"filter_rules":null,"id":"99999999-aaaa-bbbb-cccc-dddddddddddd","name":"Production Langfuse","privacy_mode":false,"regions":["global"],"sampling_rate":1,"type":"langfuse","updated_at":"2025-08-24T15:45:00Z","workspace_id":"550e8400-e29b-41d4-a716-446655440000"}}"#,
            "X-Success": "201",
          ])
          let a =
            try await alias
            ? client().observability.destinations.create(
              CreateObservabilityDestinationRequest(
                type: "future-value", name: "future-value", config: [:]), options: options)
            : client().createObservabilityDestination(
              CreateObservabilityDestinationRequest(
                type: "future-value", name: "future-value", config: [:]), options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              CreateObservabilityDestinationResponse.self,
              from: Data(
                #"{"data":{"api_key_hashes":null,"broadcast_generation_cost":false,"broadcast_generation_cost_allocation":false,"broadcast_generation_identity":false,"broadcast_generation_request_context":false,"config":{"baseUrl":"https://us.cloud.langfuse.com","publicKey":"pk-l...EfGh","secretKey":"sk-l...AbCd"},"created_at":"2025-08-24T10:30:00Z","enabled":true,"filter_rules":null,"id":"99999999-aaaa-bbbb-cccc-dddddddddddd","name":"Production Langfuse","privacy_mode":false,"regions":["global"],"sampling_rate":1,"type":"langfuse","updated_at":"2025-08-24T15:45:00Z","workspace_id":"550e8400-e29b-41d4-a716-446655440000"}}"#
                  .utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "DELETE",
            "X-Path": "/api/v1/observability/destinations/a%2Fb%3F%23%25%E9%9B%AA",
            "X-Query": filtered ? #"{}"# : "{}", "X-Body": #"{}"#,
            "X-Response": #"{"deleted":true}"#, "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().observability.destinations.delete(id: "a/b?#%雪", options: options)
            : client().deleteObservabilityDestination(id: "a/b?#%雪", options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              DeleteObservabilityDestinationResponse.self, from: Data(#"{"deleted":true}"#.utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "GET",
            "X-Path": "/api/v1/observability/destinations/a%2Fb%3F%23%25%E9%9B%AA",
            "X-Query": filtered ? #"{}"# : "{}", "X-Body": #"{}"#,
            "X-Response":
              #"{"data":{"api_key_hashes":null,"broadcast_generation_cost":false,"broadcast_generation_cost_allocation":false,"broadcast_generation_identity":false,"broadcast_generation_request_context":false,"config":{"baseUrl":"https://us.cloud.langfuse.com","publicKey":"pk-l...EfGh","secretKey":"sk-l...AbCd"},"created_at":"2025-08-24T10:30:00Z","enabled":true,"filter_rules":null,"id":"99999999-aaaa-bbbb-cccc-dddddddddddd","name":"Production Langfuse","privacy_mode":false,"regions":["global"],"sampling_rate":1,"type":"langfuse","updated_at":"2025-08-24T15:45:00Z","workspace_id":"550e8400-e29b-41d4-a716-446655440000"}}"#,
            "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().observability.destinations.get(id: "a/b?#%雪", options: options)
            : client().getObservabilityDestination(id: "a/b?#%雪", options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              GetObservabilityDestinationResponse.self,
              from: Data(
                #"{"data":{"api_key_hashes":null,"broadcast_generation_cost":false,"broadcast_generation_cost_allocation":false,"broadcast_generation_identity":false,"broadcast_generation_request_context":false,"config":{"baseUrl":"https://us.cloud.langfuse.com","publicKey":"pk-l...EfGh","secretKey":"sk-l...AbCd"},"created_at":"2025-08-24T10:30:00Z","enabled":true,"filter_rules":null,"id":"99999999-aaaa-bbbb-cccc-dddddddddddd","name":"Production Langfuse","privacy_mode":false,"regions":["global"],"sampling_rate":1,"type":"langfuse","updated_at":"2025-08-24T15:45:00Z","workspace_id":"550e8400-e29b-41d4-a716-446655440000"}}"#
                  .utf8)))
        }
        do {
          let options = RequestOptions(extraHeaders: [
            "X-Method": "PATCH",
            "X-Path": "/api/v1/observability/destinations/a%2Fb%3F%23%25%E9%9B%AA",
            "X-Query": filtered ? #"{}"# : "{}", "X-Body": #"{}"#,
            "X-Response":
              #"{"data":{"api_key_hashes":null,"broadcast_generation_cost":false,"broadcast_generation_cost_allocation":false,"broadcast_generation_identity":false,"broadcast_generation_request_context":false,"config":{"baseUrl":"https://us.cloud.langfuse.com","publicKey":"pk-l...EfGh","secretKey":"sk-l...AbCd"},"created_at":"2025-08-24T10:30:00Z","enabled":true,"filter_rules":null,"id":"99999999-aaaa-bbbb-cccc-dddddddddddd","name":"Production Langfuse","privacy_mode":false,"regions":["global"],"sampling_rate":1,"type":"langfuse","updated_at":"2025-08-24T15:45:00Z","workspace_id":"550e8400-e29b-41d4-a716-446655440000"}}"#,
            "X-Success": "200",
          ])
          let a =
            try await alias
            ? client().observability.destinations.update(
              id: "a/b?#%雪", UpdateObservabilityDestinationRequest(), options: options)
            : client().updateObservabilityDestination(
              id: "a/b?#%雪", UpdateObservabilityDestinationRequest(), options: options)
          XCTAssertEqual(
            a,
            try JSONDecoder().decode(
              UpdateObservabilityDestinationResponse.self,
              from: Data(
                #"{"data":{"api_key_hashes":null,"broadcast_generation_cost":false,"broadcast_generation_cost_allocation":false,"broadcast_generation_identity":false,"broadcast_generation_request_context":false,"config":{"baseUrl":"https://us.cloud.langfuse.com","publicKey":"pk-l...EfGh","secretKey":"sk-l...AbCd"},"created_at":"2025-08-24T10:30:00Z","enabled":true,"filter_rules":null,"id":"99999999-aaaa-bbbb-cccc-dddddddddddd","name":"Production Langfuse","privacy_mode":false,"regions":["global"],"sampling_rate":1,"type":"langfuse","updated_at":"2025-08-24T15:45:00Z","workspace_id":"550e8400-e29b-41d4-a716-446655440000"}}"#
                  .utf8)))
        }
      }
    }
  }
  private func client(key: String? = "management-key") -> OpenRouterClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [ObservabilityOfflineProtocol.self]
    let session = URLSession(configuration: config)
    return key.map { OpenRouterClient(apiKey: $0, session: session) }
      ?? OpenRouterClient(session: session)
  }
}
private final class ObservabilityOfflineProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let url = try XCTUnwrap(request.url)
      let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer management-key")
      if let method = request.value(forHTTPHeaderField: "X-Method") {
        XCTAssertEqual(request.httpMethod, method)
        XCTAssertEqual(components.percentEncodedPath, request.value(forHTTPHeaderField: "X-Path"))
        let actual = Dictionary(
          uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        let expected =
          try JSONSerialization.jsonObject(
            with: Data(request.value(forHTTPHeaderField: "X-Query")!.utf8)) as! [String: String]
        XCTAssertEqual(actual, expected)
        if method == "POST" || method == "PATCH" {
          var data = request.httpBody ?? Data()
          if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
              let n = stream.read(&buffer, maxLength: buffer.count)
              if n <= 0 { break }
              data.append(contentsOf: buffer.prefix(n))
            }
          }
          let actualBody = try JSONSerialization.jsonObject(with: data) as! NSDictionary
          let expectedBody =
            try JSONSerialization.jsonObject(
              with: Data(request.value(forHTTPHeaderField: "X-Body")!.utf8)) as! NSDictionary
          XCTAssertEqual(actualBody, expectedBody)
        }
      }
      let status = Int(
        request.value(forHTTPHeaderField: "X-Status") ?? request.value(
          forHTTPHeaderField: "X-Success") ?? "200")!
      let json =
        status >= 400
        ? "{\"error\":{\"code\":\(status),\"message\":\"observability failure\"}}"
        : request.value(forHTTPHeaderField: "X-Response") ?? "{\"data\":[],\"total_count\":0}"
      client?.urlProtocol(
        self,
        didReceive: HTTPURLResponse(
          url: url, statusCode: status,
          httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
        cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: Data(json.utf8))
      client?.urlProtocolDidFinishLoading(self)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }
  override func stopLoading() {}
}
