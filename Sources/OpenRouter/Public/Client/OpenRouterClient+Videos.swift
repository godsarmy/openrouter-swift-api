import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  public func createVideos(
    _ request: VideoRequest,
    options: RequestOptions? = nil
  ) async throws -> VideoResponse {
    try await transport.post(
      path: "videos", requestBody: request, responseType: VideoResponse.self, options: options)
  }

  public func getVideos(jobId: String, options: RequestOptions? = nil) async throws -> VideoResponse
  {
    try await transport.get(
      path: .preEscaped("videos/\(escapePathSegment(jobId))"),
      responseType: VideoResponse.self,
      options: options
    )
  }

  public func listVideosContent(
    _ request: VideoContentRequest,
    options: RequestOptions? = nil
  ) async throws -> VideoContentResponse {
    var queryItems: [URLQueryItem] = []
    if let index = request.index { queryItems.append(.init(name: "index", value: String(index))) }
    let response = try await transport.getData(
      path: .preEscaped("videos/\(escapePathSegment(request.jobID))/content"),
      queryItems: queryItems, accept: "application/octet-stream", options: options)
    return .init(data: response.data, contentType: response.contentType)
  }

  public func listVideosModels(options: RequestOptions? = nil) async throws
    -> VideoModelsListResponse
  {
    try await transport.get(
      path: "videos/models", responseType: VideoModelsListResponse.self, options: options)
  }

  public var videos: VideosResource { VideosResource(client: self) }

  public struct VideosResource: Sendable {
    fileprivate let client: OpenRouterClient

    public func create(_ request: VideoRequest, options: RequestOptions? = nil) async throws
      -> VideoResponse
    {
      try await client.createVideos(request, options: options)
    }

    public func get(jobId: String, options: RequestOptions? = nil) async throws -> VideoResponse {
      try await client.getVideos(jobId: jobId, options: options)
    }

    public func content(
      _ request: VideoContentRequest,
      options: RequestOptions? = nil
    ) async throws -> VideoContentResponse {
      try await client.listVideosContent(request, options: options)
    }

    public var models: ModelsResource { ModelsResource(client: client) }

    public struct ModelsResource: Sendable {
      fileprivate let client: OpenRouterClient

      public func list(options: RequestOptions? = nil) async throws -> VideoModelsListResponse {
        try await client.listVideosModels(options: options)
      }
    }
  }
}
