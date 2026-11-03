import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  func makeIncrementalStream<Request: Encodable, Element: Sendable>(
    transport: HTTPTransport,
    path: String,
    request: Request,
    prepare: @escaping @Sendable (inout Request) -> Void,
    metadataBox: StreamMetadataBox? = nil,
    options: RequestOptions? = nil,
    accept: String? = nil,
    decodeBufferedJSON: (@Sendable (Data) throws -> Element)? = nil,
    validateFinish: (@Sendable (Bool) throws -> Void)? = nil,
    decode: @escaping @Sendable (Data, String?) throws -> Element
  ) -> AsyncThrowingStream<Element, Error> {
    let stream = AsyncThrowingStream<Element, Error> { continuation in
      do {
        var streamRequest = request
        prepare(&streamRequest)
        let urlRequest = try transport.buildRequest(
          path: path, body: streamRequest, accept: accept ?? "application/json", options: options)

        let delegate = IncrementalSSEDelegate(
          transport: transport,
          onMetadata: { metadata in
            metadataBox?.resume(with: .success(metadata))
          },
          decode: decode,
          decodeBufferedJSON: decodeBufferedJSON,
          onElement: { element in
            continuation.yield(element)
          },
          onError: { error in
            metadataBox?.resume(with: .failure(error))
            continuation.finish(throwing: error)
          },
          onDone: { done in
            do {
              try validateFinish?(done)
              continuation.finish()
            } catch {
              continuation.finish(throwing: error)
            }
          }
        )
        let runtime = IncrementalStreamRuntime(
          request: urlRequest,
          delegate: delegate,
          protocolClasses: transport.session.configuration.protocolClasses
        )

        continuation.onTermination = { _ in
          runtime.cancel()
          metadataBox?.resume(with: .failure(OpenRouterError.streamCancelled))
        }

        runtime.start()
      } catch {
        metadataBox?.resume(with: .failure(error))
        continuation.finish(throwing: error)
      }
    }

    return stream
  }

  private static func decodeStreamChunks(from data: Data) throws -> [ChatCompletionChunk] {
    let raw = String(decoding: data, as: UTF8.self)
    var chunks: [ChatCompletionChunk] = []
    for line in raw.split(separator: "\n").map(String.init) {
      guard let event = SSEParser.parse(line: line) else { continue }
      switch event {
      case .done:
        return chunks
      case .data(let payload):
        let payloadData = Data(payload.utf8)
        let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: payloadData)
        chunks.append(chunk)
      }
    }
    return chunks
  }
}

final class StreamMetadataBox: @unchecked Sendable {
  private let lock = NSLock()
  private var continuation: CheckedContinuation<ResponseCacheMetadata?, Error>?
  private var pendingResult: Result<ResponseCacheMetadata?, Error>?
  private var didResume = false

  func makeTask() -> Task<ResponseCacheMetadata?, Error> {
    Task {
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<ResponseCacheMetadata?, Error>) in
        setContinuation(continuation)
      }
    }
  }

  private func setContinuation(_ continuation: CheckedContinuation<ResponseCacheMetadata?, Error>) {
    lock.lock()
    if let pendingResult {
      self.pendingResult = nil
      self.continuation = nil
      lock.unlock()
      resume(continuation, with: pendingResult)
      return
    }
    self.continuation = continuation
    lock.unlock()
  }

  func resume(with result: Result<ResponseCacheMetadata?, Error>) {
    lock.lock()
    guard !didResume else {
      lock.unlock()
      return
    }
    didResume = true
    guard let continuation else {
      pendingResult = result
      lock.unlock()
      return
    }
    self.continuation = nil
    switch result {
    case .success(let metadata):
      lock.unlock()
      continuation.resume(returning: metadata)
    case .failure(let error):
      lock.unlock()
      continuation.resume(throwing: error)
    }
  }

  private func resume(
    _ continuation: CheckedContinuation<ResponseCacheMetadata?, Error>,
    with result: Result<ResponseCacheMetadata?, Error>
  ) {
    switch result {
    case .success(let metadata): continuation.resume(returning: metadata)
    case .failure(let error): continuation.resume(throwing: error)
    }
  }
}

private final class IncrementalStreamRuntime<Element: Sendable>: @unchecked Sendable {
  private let session: URLSession
  private let task: URLSessionDataTask
  private let delegate: IncrementalSSEDelegate<Element>

  init(
    request: URLRequest,
    delegate: IncrementalSSEDelegate<Element>,
    protocolClasses: [AnyClass]?
  ) {
    self.delegate = delegate
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = protocolClasses
    session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    task = session.dataTask(with: request)
  }

  func start() {
    task.resume()
  }

  func cancel() {
    task.cancel()
    session.invalidateAndCancel()
    _ = delegate
  }
}

private final class IncrementalSSEDelegate<Element: Sendable>: NSObject, URLSessionDataDelegate,
  @unchecked Sendable
{
  private let transport: HTTPTransport
  private let onMetadata: @Sendable (ResponseCacheMetadata?) -> Void
  private let decode: @Sendable (Data, String?) throws -> Element
  private let onElement: @Sendable (Element) -> Void
  private let onError: @Sendable (Error) -> Void
  private let onDone: @Sendable (Bool) -> Void
  private let decodeBufferedJSON: (@Sendable (Data) throws -> Element)?
  private var isBufferedJSON = false
  private var buffer = Data()
  private var frameLines: [String] = []
  private var errorBuffer = Data()
  private var responseStatusCode: Int?
  private var didTerminate = false

  init(
    transport: HTTPTransport,
    onMetadata: @escaping @Sendable (ResponseCacheMetadata?) -> Void,
    decode: @escaping @Sendable (Data, String?) throws -> Element,
    decodeBufferedJSON: (@Sendable (Data) throws -> Element)? = nil,
    onElement: @escaping @Sendable (Element) -> Void,
    onError: @escaping @Sendable (Error) -> Void,
    onDone: @escaping @Sendable (Bool) -> Void
  ) {
    self.transport = transport
    self.onMetadata = onMetadata
    self.decode = decode
    self.decodeBufferedJSON = decodeBufferedJSON
    self.onElement = onElement
    self.onError = onError
    self.onDone = onDone
  }

  func urlSession(
    _ session: URLSession,
    dataTask: URLSessionDataTask,
    didReceive response: URLResponse,
    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
  ) {
    guard let http = response as? HTTPURLResponse else {
      didTerminate = true
      onError(OpenRouterError.invalidResponse)
      completionHandler(.cancel)
      return
    }

    responseStatusCode = http.statusCode

    guard (200..<300).contains(http.statusCode) else {
      completionHandler(.allow)
      return
    }

    onMetadata(transport.parseResponseCacheMetadata(from: http))
    let mediaType = http.value(forHTTPHeaderField: "Content-Type")?
      .split(separator: ";", maxSplits: 1).first?
      .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    isBufferedJSON = decodeBufferedJSON != nil && mediaType == "application/json"
    completionHandler(.allow)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    guard !didTerminate else { return }

    if let responseStatusCode, !(200..<300).contains(responseStatusCode) {
      errorBuffer.append(data)
      return
    }

    buffer.append(data)
    if isBufferedJSON { return }

    while let newlineRange = buffer.range(of: Data([0x0A])) {
      let lineData = buffer.subdata(in: buffer.startIndex..<newlineRange.lowerBound)
      buffer.removeSubrange(buffer.startIndex...newlineRange.lowerBound)
      var line = String(decoding: lineData, as: UTF8.self)
      if line.last == "\r" { line.removeLast() }

      if line.isEmpty {
        if processFrame(session: session) { return }
      } else {
        if line.hasPrefix("data:"), frameContainsCompleteEvent(), processFrame(session: session) {
          return
        }
        frameLines.append(line)
      }
    }
  }

  private func processFrame(session: URLSession?) -> Bool {
    guard !frameLines.isEmpty else { return false }
    let lines = frameLines
    frameLines.removeAll(keepingCapacity: true)
    let frame = SSEParser.parseMetadataFrame(lines: lines)
    guard let event = SSEParser.parseFrame(lines: lines) else { return false }

    switch event {
    case .done:
      didTerminate = true
      onDone(true)
      session?.invalidateAndCancel()
      return true
    case .data(let payload):
      do {
        onElement(try decode(Data(payload.utf8), frame.event))
        return false
      } catch {
        didTerminate = true
        onError(error)
        session?.invalidateAndCancel()
        return true
      }
    }
  }

  /// Accept legacy streams that omit the blank SSE frame delimiter between complete JSON events.
  private func frameContainsCompleteEvent() -> Bool {
    guard let event = SSEParser.parseFrame(lines: frameLines) else { return false }
    switch event {
    case .done:
      return true
    case .data(let payload):
      return (try? JSONSerialization.jsonObject(with: Data(payload.utf8))) != nil
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard !didTerminate else { return }
    if let responseStatusCode, !(200..<300).contains(responseStatusCode) {
      didTerminate = true
      onError(transport.mapAPIError(statusCode: responseStatusCode, data: errorBuffer))
      return
    }

    if let error {
      didTerminate = true
      onError(error)
    } else {
      if isBufferedJSON, let decodeBufferedJSON {
        didTerminate = true
        do {
          onElement(try decodeBufferedJSON(buffer))
          onDone(false)
        } catch {
          onError(error)
        }
        return
      }
      if !buffer.isEmpty {
        var line = String(decoding: buffer, as: UTF8.self)
        if line.last == "\r" { line.removeLast() }
        if !line.isEmpty {
          if line.hasPrefix("data:"), frameContainsCompleteEvent(), processFrame(session: nil) {
            return
          }
          frameLines.append(line)
        }
        buffer.removeAll(keepingCapacity: false)
      }
      if processFrame(session: nil) { return }
      didTerminate = true
      onDone(false)
    }
  }
}
