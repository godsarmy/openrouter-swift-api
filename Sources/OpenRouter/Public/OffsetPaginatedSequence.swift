/// Fetches offset-based pages on demand, buffering only the current page.
/// Each iterator starts independently. Membership changes during iteration can
/// cause duplicates or omissions because offset pagination is not a snapshot.
public struct OffsetPaginatedSequence<Element: Sendable>: AsyncSequence, Sendable {
  private let offset: Int
  private let fetch: @Sendable (Int) async throws -> (data: [Element], totalCount: Int)

  internal init(
    offset: Int,
    fetch: @escaping @Sendable (Int) async throws -> (data: [Element], totalCount: Int)
  ) {
    self.offset = offset
    self.fetch = fetch
  }

  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(offset: offset, fetch: fetch)
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    private var offset: Int
    private let fetch: @Sendable (Int) async throws -> (data: [Element], totalCount: Int)
    private var page: [Element] = []
    private var index = 0
    private var finished = false

    fileprivate init(
      offset: Int,
      fetch: @escaping @Sendable (Int) async throws -> (data: [Element], totalCount: Int)
    ) {
      self.offset = offset
      self.fetch = fetch
    }

    public mutating func next() async throws -> Element? {
      do {
        try Task.checkCancellation()
        if index == page.count {
          page = []
          index = 0
          guard !finished else { return nil }
          let result = try await fetch(offset)
          try Task.checkCancellation()
          page = result.data
          // Compare before adding so the next offset cannot overflow.
          if page.isEmpty || result.totalCount <= offset
            || offset < 0 || page.count >= result.totalCount - offset
          {
            finished = true
          } else {
            offset += page.count
          }
          guard !page.isEmpty else { return nil }
        }
        let element = page[index]
        index += 1
        return element
      } catch {
        finished = true
        page = []
        index = 0
        throw error
      }
    }
  }
}
