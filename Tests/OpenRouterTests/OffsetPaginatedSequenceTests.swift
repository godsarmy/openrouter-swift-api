import XCTest

@testable import OpenRouter

final class OffsetPaginatedSequenceTests: XCTestCase {
  func testLazyPagesAndIndependentIterators() async throws {
    let source = PageSource(pages: [[1, 2], [3], [1, 2]], total: 3)
    let sequence = sequence(source)
    var first = sequence.makeAsyncIterator()
    var second = sequence.makeAsyncIterator()
    let initial = await source.offsets
    XCTAssertEqual(initial, [])
    let one = try await first.next()
    let two = try await first.next()
    XCTAssertEqual([one, two], [1, 2])
    let buffered = await source.offsets
    XCTAssertEqual(buffered, [0])
    let three = try await first.next()
    let end = try await first.next()
    let repeatedEnd = try await first.next()
    XCTAssertEqual(three, 3)
    XCTAssertNil(end)
    XCTAssertNil(repeatedEnd)
    let restart = try await second.next()
    XCTAssertEqual(restart, 1)
    let offsets = await source.offsets
    XCTAssertEqual(offsets, [0, 2, 0])
  }

  func testShortPageContinuesAndEmptyPageStopsDespiteTotal() async throws {
    let source = PageSource(pages: [[1], [2], []], total: 100)
    var values: [Int] = []
    for try await value in sequence(source) { values.append(value) }
    XCTAssertEqual(values, [1, 2])
    let offsets = await source.offsets
    XCTAssertEqual(offsets, [0, 1, 2])
  }

  func testStartingOffsetAndShrinkingTotal() async throws {
    let source = PageSource(pages: [[1, 2]], total: 5)
    var values: [Int] = []
    for try await value in sequence(source, offset: 10) { values.append(value) }
    XCTAssertEqual(values, [1, 2])
    let offsets = await source.offsets
    XCTAssertEqual(offsets, [10])
  }

  func testOffsetNearIntegerMaximumDoesNotOverflow() async throws {
    let source = PageSource(pages: [[1, 2]], total: Int.max)
    var values: [Int] = []
    for try await value in sequence(source, offset: Int.max - 1) { values.append(value) }
    XCTAssertEqual(values, [1, 2])
  }

  func testFetchErrorTerminatesIterator() async throws {
    let source = PageSource(pages: [[1]], total: 3)
    var iterator = sequence(source).makeAsyncIterator()
    _ = try await iterator.next()
    do {
      _ = try await iterator.next()
      XCTFail("Expected fetch failure")
    } catch FetchError.failed {}
    let end = try await iterator.next()
    XCTAssertNil(end)
    let offsets = await source.offsets
    XCTAssertEqual(offsets, [0, 1])
  }

  func testCancellationBeforeFetchAndBeforeBufferedElement() async throws {
    for buffered in [false, true] {
      let source = PageSource(pages: [[1, 2]], total: 2)
      let sequence = sequence(source)
      let task = Task {
        var iterator = sequence.makeAsyncIterator()
        if buffered { _ = try await iterator.next() }
        withUnsafeCurrentTask { $0?.cancel() }
        do {
          _ = try await iterator.next()
          XCTFail("Expected cancellation")
        } catch is CancellationError {}
      }
      try await task.value
      let offsets = await source.offsets
      XCTAssertEqual(offsets, buffered ? [0] : [])
    }
  }

  func testCancellationAfterFetchDoesNotYieldResult() async throws {
    let sequence = OffsetPaginatedSequence<Int>(offset: 0) { _ in
      withUnsafeCurrentTask { $0?.cancel() }
      return ([1], 1)
    }
    let task = Task {
      var iterator = sequence.makeAsyncIterator()
      do {
        _ = try await iterator.next()
        XCTFail("Expected cancellation")
      } catch is CancellationError {}
    }
    try await task.value
  }

  private func sequence(_ source: PageSource, offset: Int = 0) -> OffsetPaginatedSequence<Int> {
    OffsetPaginatedSequence(offset: offset) { try await source.fetch($0) }
  }
}

private enum FetchError: Error { case failed }

private actor PageSource {
  var offsets: [Int] = []
  private let pages: [[Int]]
  private let total: Int
  private var index = 0

  init(pages: [[Int]], total: Int) {
    self.pages = pages
    self.total = total
  }

  func fetch(_ offset: Int) throws -> (data: [Int], totalCount: Int) {
    offsets.append(offset)
    guard index < pages.count else { throw FetchError.failed }
    let page = pages[index]
    index += 1
    return (page, total)
  }
}
