import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  public func createMessage(_ request: MessagesRequest, options: RequestOptions? = nil) async throws
    -> MessagesResponse
  {
    try await transport.post(
      path: "messages", requestBody: request, responseType: MessagesResponse.self, options: options)
  }

  public func createMessageStream(_ request: MessagesRequest) -> AsyncThrowingStream<
    MessagesStreamEvent, Error
  > {
    makeIncrementalStream(
      transport: transport, path: "messages", request: request, prepare: { $0.stream = true },
      decode: { data, eventName in
        let event = try JSONDecoder().decode(MessagesStreamEvent.self, from: data).withEventName(
          eventName)
        if event.type == "error" { throw OpenRouterError.messageStreamError(from: event) }
        return event
      })
  }

  public var messages: MessagesResource { MessagesResource(client: self) }

  public struct MessagesResource: Sendable {
    fileprivate let client: OpenRouterClient
    public func create(_ request: MessagesRequest, options: RequestOptions? = nil) async throws
      -> MessagesResponse
    { try await client.createMessage(request, options: options) }
    public func stream(_ request: MessagesRequest) -> AsyncThrowingStream<
      MessagesStreamEvent, Error
    > { client.createMessageStream(request) }
  }
}
