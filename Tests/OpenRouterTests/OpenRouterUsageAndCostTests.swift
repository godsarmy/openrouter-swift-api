import XCTest

@testable import OpenRouter

final class OpenRouterUsageAndCostTests: XCTestCase {
  func testUsageDecodesCostAndIsByok() throws {
    let json =
      #"{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15,"cost":0.0012,"is_byok":true}"#
      .data(using: .utf8)!
    let usage = try JSONDecoder().decode(Usage.self, from: json)

    XCTAssertEqual(usage.cost, 0.0012)
    XCTAssertEqual(usage.isByok, true)
    XCTAssertEqual(usage.totalTokens, 15)
  }

  func testUsageDecodesCostDetails() throws {
    let json = #"{"cost":0.123,"cost_details":{"upstream_inference_cost":0.111}}"#.data(
      using: .utf8)!
    let usage = try JSONDecoder().decode(Usage.self, from: json)

    XCTAssertEqual(usage.cost, 0.123)
    XCTAssertEqual(usage.costDetails?.upstreamInferenceCost, 0.111)
  }

  func testPromptAndCompletionTokenDetailsDecodeExpandedFields() throws {
    let json =
      #"{"prompt_tokens_details":{"cached_tokens":2,"audio_tokens":3,"cache_write_tokens":4,"video_tokens":5},"completion_tokens_details":{"accepted_prediction_tokens":6,"reasoning_tokens":7,"rejected_prediction_tokens":8}}"#
      .data(using: .utf8)!
    let usage = try JSONDecoder().decode(Usage.self, from: json)

    XCTAssertEqual(usage.promptTokensDetails?.cachedTokens, 2)
    XCTAssertEqual(usage.promptTokensDetails?.audioTokens, 3)
    XCTAssertEqual(usage.promptTokensDetails?.cacheWriteTokens, 4)
    XCTAssertEqual(usage.promptTokensDetails?.videoTokens, 5)
    XCTAssertEqual(usage.completionTokensDetails?.acceptedPredictionTokens, 6)
    XCTAssertEqual(usage.completionTokensDetails?.reasoningTokens, 7)
    XCTAssertEqual(usage.completionTokensDetails?.rejectedPredictionTokens, 8)
  }

  func testUsageEncodingRoundTripPreservesOptionalFields() throws {
    let usage = Usage(
      promptTokens: 1,
      completionTokens: 2,
      totalTokens: 3,
      promptTokensDetails: .init(
        cachedTokens: 4, audioTokens: 5, cacheWriteTokens: 6, videoTokens: 7),
      completionTokensDetails: .init(
        acceptedPredictionTokens: 8,
        reasoningTokens: 9,
        rejectedPredictionTokens: 10
      ),
      cost: 0.002,
      costDetails: .init(upstreamInferenceCost: 0.001),
      isByok: false
    )

    let data = try JSONEncoder().encode(usage)
    let decoded = try JSONDecoder().decode(Usage.self, from: data)

    XCTAssertEqual(decoded, usage)
  }
}
