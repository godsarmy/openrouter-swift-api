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
    XCTAssertTrue(server.isRetryable)
    XCTAssertEqual(server.statusCode, 503)

    let forbidden = OpenRouterError.apiError(statusCode: 403, code: nil, message: nil, rawBody: nil)
    XCTAssertTrue(forbidden.isForbidden)

    let notFound = OpenRouterError.apiError(statusCode: 404, code: nil, message: nil, rawBody: nil)
    XCTAssertTrue(notFound.isNotFound)
  }

  func testAPICodeConvenience() {
    let error = OpenRouterError.apiError(statusCode: 400, code: 1234, message: nil, rawBody: nil)
    XCTAssertTrue(error.isBadRequest)
    XCTAssertEqual(error.apiCode, 1234)
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
