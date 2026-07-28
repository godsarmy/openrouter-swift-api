import Foundation
import XCTest

@testable import OpenRouter

final class OpenRouterIntegrationTests: XCTestCase {
  private func requireIntegrationOptInAndAPIKey() throws -> String {
    let env = ProcessInfo.processInfo.environment
    let runIntegration = env["OPENROUTER_RUN_INTEGRATION"]?.lowercased()
    guard runIntegration == "1" || runIntegration == "true" || runIntegration == "yes" else {
      throw XCTSkip("Set OPENROUTER_RUN_INTEGRATION=true to run live integration tests")
    }

    guard let apiKey = env["OPENROUTER_API_KEY"], !apiKey.isEmpty else {
      throw XCTSkip("OPENROUTER_API_KEY not set")
    }
    return apiKey
  }

  func testIntegrationChatCompletion() async throws {
    let apiKey = try requireIntegrationOptInAndAPIKey()

    let client = OpenRouterClient(apiKey: apiKey)
    let request = ChatCompletionRequest(
      model: "openai/gpt-4o-mini",
      messages: [.user("Reply with the single word: ok")]
    )
    let response = try await client.createChatCompletion(request)
    XCTAssertFalse(response.choices.isEmpty)
  }

  func testIntegrationEmbeddings() async throws {
    let apiKey = try requireIntegrationOptInAndAPIKey()

    let client = OpenRouterClient(apiKey: apiKey)
    let request = EmbeddingRequest(model: "text-embedding-3-small", input: .string("hello"))
    let response = try await client.createEmbeddings(request)
    XCTAssertFalse(response.data.isEmpty)
  }

  func testIntegrationStreamingChatCompletion() async throws {
    let apiKey = try requireIntegrationOptInAndAPIKey()

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

  func testIntegrationVideoWorkflow() async throws {
    let apiKey = try requireIntegrationOptInAndAPIKey()
    let env = ProcessInfo.processInfo.environment
    guard let runVideo = env["OPENROUTER_RUN_VIDEO_INTEGRATION"]?.lowercased(),
      ["1", "true", "yes"].contains(runVideo)
    else {
      throw XCTSkip(
        "Set OPENROUTER_RUN_VIDEO_INTEGRATION=true to run the live video integration test")
    }
    guard let model = env["OPENROUTER_VIDEO_MODEL"], !model.isEmpty else {
      throw XCTSkip("Set OPENROUTER_VIDEO_MODEL to a supported video model")
    }
    guard let downloadContent = env["OPENROUTER_RUN_VIDEO_CONTENT_DOWNLOAD"]?.lowercased(),
      ["1", "true", "yes"].contains(downloadContent)
    else {
      throw XCTSkip(
        "Set OPENROUTER_RUN_VIDEO_CONTENT_DOWNLOAD=true to validate the full video workflow")
    }

    let client = OpenRouterClient(apiKey: apiKey)
    let models = try await client.videos.models.list()
    XCTAssertTrue(
      models.data.contains(where: { $0.id == model }), "Configured video model is unavailable")

    let created = try await client.videos.create(
      .init(model: model, prompt: "A five-second shot of a calm ocean horizon"))
    let deadline = ContinuousClock.now.advanced(by: .seconds(600))
    var job = created

    while job.status != .completed, ContinuousClock.now < deadline {
      switch job.status {
      case .pending, .inProgress:
        try await Task.sleep(nanoseconds: 5_000_000_000)
        job = try await client.videos.get(jobId: job.id)
      case .failed, .cancelled, .expired:
        XCTFail("Video job ended as \(job.status.rawValue): \(job.error ?? "no server error")")
        return
      case .completed:
        break
      }
    }

    XCTAssertEqual(job.status, .completed, "Video job did not complete within 10 minutes")
    guard job.status == .completed else { return }
    let content = try await client.videos.content(.init(jobID: job.id, index: 0))
    XCTAssertFalse(content.data.isEmpty)
    if let contentType = content.contentType {
      XCTAssertTrue(contentType.lowercased().hasPrefix("video/"))
    }
  }
}
