import Foundation
import XCTest

@testable import OpenRouter

final class OpenRouterIntegrationTests: XCTestCase {
  func testIntegrationChatCompletion() async throws {
    guard let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !apiKey.isEmpty
    else {
      throw XCTSkip("OPENROUTER_API_KEY not set")
    }

    let client = OpenRouterClient(apiKey: apiKey)
    let request = ChatCompletionRequest(
      model: "openai/gpt-4o-mini",
      messages: [.user("Reply with the single word: ok")]
    )
    let response = try await client.createChatCompletion(request)
    XCTAssertFalse(response.choices.isEmpty)
  }

  func testIntegrationEmbeddings() async throws {
    guard let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !apiKey.isEmpty
    else {
      throw XCTSkip("OPENROUTER_API_KEY not set")
    }

    let client = OpenRouterClient(apiKey: apiKey)
    let request = EmbeddingRequest(model: "text-embedding-3-small", input: .string("hello"))
    let response = try await client.createEmbeddings(request)
    XCTAssertFalse(response.data.isEmpty)
  }

  func testIntegrationStreamingChatCompletion() async throws {
    guard let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !apiKey.isEmpty
    else {
      throw XCTSkip("OPENROUTER_API_KEY not set")
    }

    let client = OpenRouterClient(apiKey: apiKey)
    let request = ChatCompletionRequest(
      model: "openai/gpt-4o-mini",
      messages: [.user("Reply with one short sentence")],
      stream: true
    )

    var receivedAnyChunk = false
    for try await _ in client.createChatCompletionStream(request) {
      receivedAnyChunk = true
      break
    }

    XCTAssertTrue(receivedAnyChunk)
  }
}
