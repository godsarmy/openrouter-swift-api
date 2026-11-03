import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  /// Starts provider work and may incur image-generation costs. Requires a normal API key
  /// with the server-required authorization scope. Only nonstreaming responses are supported.
  /// `n` is an upper bound: providers may return fewer images. A seed does not guarantee determinism.
  public func createImage(
    _ request: ImageGenerationRequest,
    options: RequestOptions? = nil
  ) async throws -> ImageGenerationResponse {
    try await transport.post(
      path: "images", requestBody: request,
      responseType: ImageGenerationResponse.self, options: options)
  }

  /// Streams image generation without retrying or resubmitting provider work.
  public func createImageStream(
    _ request: ImageGenerationRequest, options: RequestOptions? = nil
  ) -> AsyncThrowingStream<ImageGenerationStreamEvent, Error> {
    let state = ImageStreamState()
    return makeIncrementalStream(
      transport: transport, path: "images", request: StreamingImageRequest(request: request),
      prepare: { _ in }, options: options, accept: "text/event-stream, application/json",
      decodeBufferedJSON: { data in
        let response = try JSONDecoder().decode(ImageGenerationResponse.self, from: data)
        state.buffered = true
        return ImageGenerationStreamEvent(bufferedResponse: response)
      },
      validateFinish: { done in
        guard state.buffered || (state.completed && done) else {
          throw ImageGenerationStreamError.incompleteStream
        }
      },
      decode: { data, name in
        var event = try JSONDecoder().decode(ImageGenerationStreamEvent.self, from: data)
        guard event.bufferedResponse == nil else {
          throw DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "Buffered response in SSE"))
        }
        event.eventName = name
        if let error = event.error { throw ImageGenerationStreamError.provider(error) }
        if event.type == "image_generation.completed" { state.completed = true }
        return event
      })
  }

  public func listImageModels(options: RequestOptions? = nil) async throws
    -> ImageModelsListResponse
  {
    try await transport.get(
      path: "images/models", responseType: ImageModelsListResponse.self, options: options)
  }

  public func listImageModelEndpoints(
    author: String, slug: String, options: RequestOptions? = nil
  ) async throws -> ImageModelEndpointsResponse {
    try await transport.get(
      path: .preEscaped(
        "images/models/\(escapePathSegment(author))/\(escapePathSegment(slug))/endpoints"),
      responseType: ImageModelEndpointsResponse.self,
      options: options
    )
  }

  public var images: ImagesResource { ImagesResource(client: self) }

  public struct ImagesResource: Sendable {
    fileprivate let client: OpenRouterClient

    /// Starts provider work and may incur costs; requires a normal API key with the
    /// server-required authorization scope. Nonstreaming only. `n` is an upper bound,
    /// and a seed does not guarantee deterministic output.
    public func create(
      _ request: ImageGenerationRequest, options: RequestOptions? = nil
    ) async throws -> ImageGenerationResponse {
      try await client.createImage(request, options: options)
    }

    public func stream(
      _ request: ImageGenerationRequest, options: RequestOptions? = nil
    ) -> AsyncThrowingStream<ImageGenerationStreamEvent, Error> {
      client.createImageStream(request, options: options)
    }

    public var models: ModelsResource { ModelsResource(client: client) }

    public struct ModelsResource: Sendable {
      fileprivate let client: OpenRouterClient

      public func list(options: RequestOptions? = nil) async throws -> ImageModelsListResponse {
        try await client.listImageModels(options: options)
      }

      public func endpoints(
        author: String, slug: String, options: RequestOptions? = nil
      ) async throws -> ImageModelEndpointsResponse {
        try await client.listImageModelEndpoints(author: author, slug: slug, options: options)
      }
    }
  }
}

private struct StreamingImageRequest: Encodable {
  let request: ImageGenerationRequest

  func encode(to encoder: Encoder) throws {
    try request.encode(to: encoder, stream: true)
  }
}

/// Accessed only by the serialized URLSession delegate callbacks for one invocation.
private final class ImageStreamState: @unchecked Sendable {
  var completed = false
  var buffered = false
}
