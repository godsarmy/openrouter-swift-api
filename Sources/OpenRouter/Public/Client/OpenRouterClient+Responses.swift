import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  public func createResponse(
    _ request: ResponsesRequest,
    options: RequestOptions? = nil
  ) async throws -> ResponsesResponse {
    try await transport.post(
      path: "responses",
      requestBody: request,
      responseType: ResponsesResponse.self,
      options: options
    )
  }

  public func createResponseStream(
    _ request: ResponsesRequest
  ) -> AsyncThrowingStream<ResponsesStreamEvent, Error> {
    let transport = self.transport
    return makeResponsesIncrementalStream(transport: transport, request: request)
  }

  private func makeResponsesIncrementalStream(
    transport: HTTPTransport,
    request: ResponsesRequest
  ) -> AsyncThrowingStream<ResponsesStreamEvent, Error> {
    return makeIncrementalStream(
      transport: transport, path: "responses", request: request, prepare: { $0.stream = true },
      decode: { data, _ in
        let event = try JSONDecoder().decode(ResponsesStreamEvent.self, from: data)
        if ["response.failed", "response.error", "error"].contains(event.type) {
          throw OpenRouterError.streamEventError(from: event)
        }
        return event
      })
  }

  public var responses: ResponsesResource { ResponsesResource(client: self) }

  public struct ResponsesResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func create(
      _ request: ResponsesRequest,
      options: RequestOptions? = nil
    ) async throws -> ResponsesResponse {
      try await client.createResponse(request, options: options)
    }

    public func stream(
      _ request: ResponsesRequest
    ) -> AsyncThrowingStream<ResponsesStreamEvent, Error> {
      client.createResponseStream(request)
    }
  }
}
