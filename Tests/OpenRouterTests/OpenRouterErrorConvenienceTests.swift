import XCTest

@testable import OpenRouter

final class OpenRouterErrorConvenienceTests: XCTestCase {
  func testStatusConvenienceFlags() {
    let unauthorized = OpenRouterError.apiError(
      statusCode: 401, code: nil, message: nil, rawBody: nil)
    XCTAssertTrue(unauthorized.isUnauthorized)
    XCTAssertFalse(unauthorized.isRateLimited)

    let payment = OpenRouterError.apiError(statusCode: 402, code: nil, message: nil, rawBody: nil)
    XCTAssertTrue(payment.isPaymentRequired)

    let rateLimited = OpenRouterError.apiError(
      statusCode: 429, code: nil, message: nil, rawBody: nil)
    XCTAssertTrue(rateLimited.isRateLimited)

    let server = OpenRouterError.apiError(statusCode: 503, code: nil, message: nil, rawBody: nil)
    XCTAssertTrue(server.isServerError)
    XCTAssertEqual(server.statusCode, 503)
  }

  func testRetryAfterParsesFromRawBody() {
    let error = OpenRouterError.apiError(
      statusCode: 429,
      code: 429,
      message: "rate limited",
      rawBody: #"{"retry_after":2.5}"#
    )
    XCTAssertEqual(error.retryAfter, 2.5)
  }
}
