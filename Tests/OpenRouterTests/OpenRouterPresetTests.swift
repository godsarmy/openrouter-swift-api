import Foundation
import OpenRouter
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
final class OpenRouterPresetTests: XCTestCase {
  private let preset =
    #"{"created_at":"2026-04-20T10:00:00Z","creator_user_id":"user_2dHFtVWx2n56w6HkM0000000000","description":null,"designated_version_id":"550e8400-e29b-41d4-a716-446655440000","id":"650e8400-e29b-41d4-a716-446655440001","name":"my-preset","slug":"my-preset","status":"active","status_updated_at":null,"updated_at":"2026-04-20T10:00:00Z","workspace_id":"750e8400-e29b-41d4-a716-446655440002"}"#
  private let version =
    #"{"config":{"model":"openai/gpt-4o","temperature":0.7},"created_at":"2026-04-20T10:00:00Z","creator_id":"user_2dHFtVWx2n56w6HkM0000000000","id":"550e8400-e29b-41d4-a716-446655440000","preset_id":"650e8400-e29b-41d4-a716-446655440001","system_prompt":"You are a helpful assistant.","updated_at":"2026-04-20T10:00:00Z","version":1}"#
  private let detail =
    #"{"created_at":"2026-04-20T10:00:00Z","creator_user_id":"user_2dHFtVWx2n56w6HkM0000000000","description":null,"designated_version":{"config":{"model":"openai/gpt-4o","temperature":0.7},"created_at":"2026-04-20T10:00:00Z","creator_id":"user_2dHFtVWx2n56w6HkM0000000000","id":"550e8400-e29b-41d4-a716-446655440000","preset_id":"650e8400-e29b-41d4-a716-446655440001","system_prompt":"You are a helpful assistant.","updated_at":"2026-04-20T10:00:00Z","version":1},"designated_version_id":"550e8400-e29b-41d4-a716-446655440000","id":"650e8400-e29b-41d4-a716-446655440001","name":"my-preset","slug":"my-preset","status":"active","status_updated_at":null,"updated_at":"2026-04-20T10:00:00Z","workspace_id":"750e8400-e29b-41d4-a716-446655440002"}"#
  private func client(key: String? = "management-key") -> OpenRouterClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [PresetOfflineProtocol.self]
    let session = URLSession(configuration: config)
    return key.map { OpenRouterClient(apiKey: $0, session: session) }
      ?? OpenRouterClient(session: session)
  }
  private func options(
    _ method: String, _ path: String, _ response: String, query: String = "{}", body: String = "{}"
  ) -> RequestOptions {
    RequestOptions(extraHeaders: [
      "X-Method": method, "X-Path": "/api/v1/" + path, "X-Query": query, "X-Body": body,
      "X-Response": response,
    ])
  }
  func testReadOperationsAndAliases() async throws {
    let slug = "a/b 雪"
    let path = "presets/a%2Fb%20%E9%9B%AA"
    for alias in [false, true] {
      for paged in [false, true] {
        let offset: Int? = paged ? 0 : nil
        let limit: Int? = paged ? 100 : nil
        let query = paged ? #"{"offset":"0","limit":"100"}"# : "{}"
        let o = options("GET", "presets", "{\"data\":[\(preset)],\"total_count\":17}", query: query)
        let list =
          try await alias
          ? client().listPresets(offset: offset, limit: limit, options: o)
          : client().presets.list(offset: offset, limit: limit, options: o)
        XCTAssertEqual(list.totalCount, 17)
        XCTAssertEqual(list.data.count, 1)
        let v = options(
          "GET", path + "/versions", "{\"data\":[null,\(version)],\"total_count\":9}", query: query)
        let versions =
          try await alias
          ? client().listPresetVersions(slug: slug, offset: offset, limit: limit, options: v)
          : client().presets.listVersions(slug: slug, offset: offset, limit: limit, options: v)
        XCTAssertEqual(versions.totalCount, 9)
        XCTAssertNil(versions.data[0])
        XCTAssertEqual(versions.data[1]?.version, 1)
      }
      let o = options("GET", path, "{\"data\":\(detail)}")
      let got =
        try await alias
        ? client().getPreset(slug: slug, options: o) : client().presets.get(slug: slug, options: o)
      XCTAssertEqual(got.data.designatedVersion?.id, got.data.preset.designatedVersionID)
      for null in [false, true] {
        let v = options(
          "GET", path + "/versions/v%2F%20%E9%9B%AA", "{\"data\":\(null ? "null" : version)}")
        let got =
          try await alias
          ? client().getPresetVersion(slug: slug, version: "v/ 雪", options: v)
          : client().presets.getVersion(slug: slug, version: "v/ 雪", options: v)
        XCTAssertEqual(got.data == nil, null)
      }
    }
  }
  func testPostBodiesAndAliases() async throws {
    let slug = "a/b 雪"
    let prefix = "presets/a%2Fb%20%E9%9B%AA/"
    for alias in [false, true] {
      do {
        let text = #"{"model":"m","messages":[{"role":"assistant","content":null}],"stream":true}"#
        let request = try JSONDecoder().decode(ChatCompletionRequest.self, from: Data(text.utf8))
        let o = options("POST", prefix + "chat/completions", "{\"data\":\(detail)}", body: text)
        let got =
          try await alias
          ? client().createPresetsChatCompletions(slug: slug, request, options: o)
          : client().presets.createFromChatCompletions(slug: slug, request, options: o)
        XCTAssertEqual(got.data.designatedVersion?.version, 1)
        for stream in ["true", "null"] {
          let raw =
            "{\"stream\":\(stream),\"messages\":[{\"role\":\"assistant\",\"content\":null}],\"prompt\":null,\"future_config\":{\"nested\":[1,true,null]}}"
          let body = try JSONDecoder().decode([String: JSONValue].self, from: Data(raw.utf8))
          let o = options("POST", prefix + "chat/completions", "{\"data\":\(detail)}", body: raw)
          _ =
            try await alias
            ? client().createPresetsChatCompletions(slug: slug, body: body, options: o)
            : client().presets.createFromChatCompletions(slug: slug, body: body, options: o)
        }
      }
      do {
        let text =
          #"{"model":"m","messages":[{"role":"user","content":"hi"}],"max_tokens":7,"stream":true}"#
        let request = try JSONDecoder().decode(MessagesRequest.self, from: Data(text.utf8))
        let o = options("POST", prefix + "messages", "{\"data\":\(detail)}", body: text)
        let got =
          try await alias
          ? client().createPresetsMessages(slug: slug, request, options: o)
          : client().presets.createFromMessages(slug: slug, request, options: o)
        XCTAssertEqual(got.data.designatedVersion?.version, 1)
        for stream in ["true", "null"] {
          let raw =
            "{\"stream\":\(stream),\"messages\":[{\"role\":\"assistant\",\"content\":null}],\"prompt\":null,\"future_config\":{\"nested\":[1,true,null]}}"
          let body = try JSONDecoder().decode([String: JSONValue].self, from: Data(raw.utf8))
          let o = options("POST", prefix + "messages", "{\"data\":\(detail)}", body: raw)
          _ =
            try await alias
            ? client().createPresetsMessages(slug: slug, body: body, options: o)
            : client().presets.createFromMessages(slug: slug, body: body, options: o)
        }
      }
      do {
        let text = #"{"model":"m","input":"hi","stream":true}"#
        let request = try JSONDecoder().decode(ResponsesRequest.self, from: Data(text.utf8))
        let o = options("POST", prefix + "responses", "{\"data\":\(detail)}", body: text)
        let got =
          try await alias
          ? client().createPresetsResponses(slug: slug, request, options: o)
          : client().presets.createFromResponses(slug: slug, request, options: o)
        XCTAssertEqual(got.data.designatedVersion?.version, 1)
        for stream in ["true", "null"] {
          let raw =
            "{\"stream\":\(stream),\"messages\":[{\"role\":\"assistant\",\"content\":null}],\"prompt\":null,\"future_config\":{\"nested\":[1,true,null]}}"
          let body = try JSONDecoder().decode([String: JSONValue].self, from: Data(raw.utf8))
          let o = options("POST", prefix + "responses", "{\"data\":\(detail)}", body: raw)
          _ =
            try await alias
            ? client().createPresetsResponses(slug: slug, body: body, options: o)
            : client().presets.createFromResponses(slug: slug, body: body, options: o)
        }
      }
    }
  }
  private func roundtrip<T: Codable & Equatable>(_ type: T.Type, _ text: String) throws {
    let value = try JSONDecoder().decode(type, from: Data(text.utf8))
    let encoded = try JSONEncoder().encode(value)
    XCTAssertEqual(try JSONDecoder().decode(type, from: encoded), value)
    XCTAssertEqual(
      try JSONSerialization.jsonObject(with: encoded) as! NSDictionary,
      try JSONSerialization.jsonObject(with: Data(text.utf8)) as! NSDictionary)
  }
  func testModelsStrictRequiredNullableAndOpenConfig() throws {
    try roundtrip(Preset.self, preset)
    try roundtrip(GetPresetResponse.self, "{\"data\":\(detail)}")
    try roundtrip(CreatePresetFromInferenceResponse.self, "{\"data\":\(detail)}")
    XCTAssertThrowsError(
      try JSONDecoder().decode(ListPresetsResponse.self, from: Data(#"{"data":[]}"#.utf8)))
    XCTAssertThrowsError(
      try JSONDecoder().decode(ListPresetVersionsResponse.self, from: Data(#"{"data":[]}"#.utf8)))
    var p = try JSONSerialization.jsonObject(with: Data(preset.utf8)) as! [String: Any]
    let nullable = [
      "creator_user_id", "workspace_id", "description", "designated_version_id",
      "status_updated_at",
    ]
    for key in nullable { p[key] = NSNull() }
    for status in ["active", "disabled", "archived", "future-status"] {
      p["status"] = status
      let data = try JSONSerialization.data(withJSONObject: p)
      try roundtrip(Preset.self, String(decoding: data, as: UTF8.self))
    }
    for key in nullable {
      var missing = p
      missing.removeValue(forKey: key)
      XCTAssertThrowsError(
        try JSONDecoder().decode(Preset.self, from: JSONSerialization.data(withJSONObject: missing))
      )
    }
    p["designated_version"] = NSNull()
    try roundtrip(
      PresetWithDesignatedVersion.self,
      String(decoding: JSONSerialization.data(withJSONObject: p), as: UTF8.self))
    p.removeValue(forKey: "designated_version")
    XCTAssertThrowsError(
      try JSONDecoder().decode(
        PresetWithDesignatedVersion.self, from: JSONSerialization.data(withJSONObject: p)))
    try roundtrip(PresetWithDesignatedVersion.self, detail)
    var v = try JSONSerialization.jsonObject(with: Data(version.utf8)) as! [String: Any]
    v["system_prompt"] = NSNull()
    v["config"] = ["future": ["arbitrary": [1, true, NSNull(), "text"]], "null": NSNull()]
    try roundtrip(
      PresetVersion.self, String(decoding: JSONSerialization.data(withJSONObject: v), as: UTF8.self)
    )
    for bad in [NSNull(), [], "text", 4] as [Any] {
      var invalid = v
      invalid["config"] = bad
      XCTAssertThrowsError(
        try JSONDecoder().decode(
          PresetVersion.self, from: JSONSerialization.data(withJSONObject: invalid)))
    }
    for key in ["system_prompt", "config"] {
      var missing = v
      missing.removeValue(forKey: key)
      XCTAssertThrowsError(
        try JSONDecoder().decode(
          PresetVersion.self, from: JSONSerialization.data(withJSONObject: missing)))
    }
    try roundtrip(GetPresetVersionResponse.self, #"{"data":null}"#)
    XCTAssertThrowsError(
      try JSONDecoder().decode(GetPresetVersionResponse.self, from: Data("{}".utf8)))
    try roundtrip(ListPresetVersionsResponse.self, #"{"data":[null],"total_count":1}"#)
  }
  func testErrorsAndPaginationBoundsAreServerValidated() async throws {
    for status in [400, 401, 403, 404, 409, 500, 503] {
      do {
        _ = try await client().presets.get(
          slug: "id", options: RequestOptions(extraHeaders: ["X-Status": String(status)]))
        XCTFail("Expected error")
      } catch let error as OpenRouterError {
        guard case .apiError(let actual, _, _, _) = error else {
          return XCTFail("Unexpected error")
        }
        XCTAssertEqual(actual, status)
      }
      do {
        _ = try await client().presets.createFromMessages(
          slug: "id", body: ["stream": .bool(true)],
          options: RequestOptions(extraHeaders: ["X-Status": String(status)]))
        XCTFail("Expected mutation error")
      } catch let error as OpenRouterError {
        guard case .apiError(let actual, _, _, _) = error else {
          return XCTFail("Unexpected error")
        }
        XCTAssertEqual(actual, status)
      }
    }
    for bounds in [(-1, 1), (0, 0), (0, 101)] {
      var o = options(
        "GET", "presets", "{}", query: "{\"offset\":\"\(bounds.0)\",\"limit\":\"\(bounds.1)\"}")
      o.extraHeaders["X-Status"] = "400"
      do {
        _ = try await client().presets.list(offset: bounds.0, limit: bounds.1, options: o)
        XCTFail("Expected server validation")
      } catch let error as OpenRouterError {
        guard case .apiError(let status, _, _, _) = error else {
          return XCTFail("Unexpected error")
        }
        XCTAssertEqual(status, 400)
      }
      o.extraHeaders["X-Path"] = "/api/v1/presets/id/versions"
      do {
        _ = try await client().presets.listVersions(
          slug: "id", offset: bounds.0, limit: bounds.1, options: o)
        XCTFail("Expected server validation")
      } catch let error as OpenRouterError {
        guard case .apiError(let status, _, _, _) = error else {
          return XCTFail("Unexpected error")
        }
        XCTAssertEqual(status, 400)
      }
    }
    do {
      _ = try await client(key: nil).presets.list()
      XCTFail("Expected missing key")
    } catch let error as OpenRouterError {
      guard case .missingAPIKey = error else { return XCTFail("Unexpected error") }
    }
  }
}
private final class PresetOfflineProtocol: URLProtocol {
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
        ? "{\"error\":{\"code\":\(status),\"message\":\"preset failure\"}}"
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
