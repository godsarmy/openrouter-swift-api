import XCTest

@testable import OpenRouter

final class OpenRouterClientTests: XCTestCase {
  func testClientInitialization() {
    let client = OpenRouterClient(apiKey: "test-key")
    XCTAssertEqual(client.configuration.baseURL.absoluteString, "https://openrouter.ai/api/v1/")
  }
}
