import XCTest

@testable import OpenRouter

final class OpenRouterFallbackTests: XCTestCase {
  func testShouldFallbackWhenStatusCodeMatchesDefaultPolicy() {
    let policy = ChatCompletionFallbackPolicy(
      models: ["fallback/model"],
      errorCodes: ChatCompletionFallbackPolicy.defaultErrorCodes
    )

    let error = OpenRouterError.apiError(
      statusCode: 429,
      code: nil,
      message: "rate limit",
      rawBody: nil
    )

    XCTAssertTrue(OpenRouterClient.shouldFallback(for: error, policy: policy))
  }

  func testShouldFallbackWhenBodyCodeMatchesPolicy() {
    let policy = ChatCompletionFallbackPolicy(models: ["fallback/model"], errorCodes: [524])
    let error = OpenRouterError.apiError(
      statusCode: 200,
      code: 524,
      message: "infra timeout",
      rawBody: nil
    )

    XCTAssertTrue(OpenRouterClient.shouldFallback(for: error, policy: policy))
  }

  func testDoesNotFallbackForNonMatchingCodes() {
    let policy = ChatCompletionFallbackPolicy(models: ["fallback/model"], errorCodes: [429])
    let error = OpenRouterError.apiError(
      statusCode: 400,
      code: 400,
      message: "bad request",
      rawBody: nil
    )

    XCTAssertFalse(OpenRouterClient.shouldFallback(for: error, policy: policy))
  }
}
