import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension OpenRouterClient {
  public func uploadFile(
    _ file: FileUpload,
    workspaceID: UUID? = nil,
    options: RequestOptions? = nil
  ) async throws -> FileMetadata {
    let boundary = "OpenRouterBoundary-\(UUID().uuidString)"
    let queryItems =
      workspaceID.map {
        [URLQueryItem(name: "workspace_id", value: $0.uuidString)]
      } ?? []
    return try await transport.postMultipart(
      path: "files",
      body: makeFileUploadMultipartBody(file, boundary: boundary),
      boundary: boundary,
      queryItems: queryItems,
      responseType: FileMetadata.self,
      options: options
    )
  }

  /// Lists files. The server validates limit (1...1000); cursors and provider filters are opaque.
  public func listFiles(
    limit: Int? = nil, cursor: String? = nil, workspaceID: UUID? = nil,
    provider: String? = nil, after: String? = nil, afterID: String? = nil,
    beforeID: String? = nil, order: String? = nil, options: RequestOptions? = nil
  ) async throws -> FileListResponse {
    var queryItems: [URLQueryItem] = []
    if let limit { queryItems.append(.init(name: "limit", value: String(limit))) }
    if let cursor { queryItems.append(.init(name: "cursor", value: cursor)) }
    if let workspaceID {
      queryItems.append(.init(name: "workspace_id", value: workspaceID.uuidString))
    }
    if let provider { queryItems.append(.init(name: "provider", value: provider)) }
    if let after { queryItems.append(.init(name: "after", value: after)) }
    if let afterID { queryItems.append(.init(name: "after_id", value: afterID)) }
    if let beforeID { queryItems.append(.init(name: "before_id", value: beforeID)) }
    if let order { queryItems.append(.init(name: "order", value: order)) }
    return try await transport.get(
      path: "files", queryItems: queryItems, responseType: FileListResponse.self, options: options)
  }

  /// Retrieves metadata. The server validates IDs (1...256 word characters or hyphens).
  public func getFile(
    id: String, workspaceID: UUID? = nil, provider: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> FileResponse {
    var queryItems: [URLQueryItem] = []
    if let workspaceID {
      queryItems.append(.init(name: "workspace_id", value: workspaceID.uuidString))
    }
    if let provider { queryItems.append(.init(name: "provider", value: provider)) }
    return try await transport.get(
      path: .preEscaped("files/\(escapePathSegment(id))"), queryItems: queryItems,
      responseType: FileResponse.self, options: options)
  }

  /// Irreversibly deletes a file; callers must obtain explicit authorization before calling.
  /// Uploaded/downloadable status does not determine deletion eligibility.
  /// The server validates IDs against `^[\w-]+$` with length 1...256; IDs are passed through safely escaped.
  public func deleteFile(
    id: String, workspaceID: UUID? = nil, provider: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> FileDeleteResponse {
    var queryItems: [URLQueryItem] = []
    if let workspaceID {
      queryItems.append(.init(name: "workspace_id", value: workspaceID.uuidString))
    }
    if let provider { queryItems.append(.init(name: "provider", value: provider)) }
    return try await transport.delete(
      path: .preEscaped("files/\(escapePathSegment(id))"), queryItems: queryItems,
      responseType: FileDeleteResponse.self, options: options)
  }

  /// Buffers downloadable file bytes. Uploaded files are not downloadable (server returns 400).
  /// The server validates IDs (1...256 word characters or hyphens).
  public func downloadFileContent(
    id: String, workspaceID: UUID? = nil, provider: String? = nil,
    options: RequestOptions? = nil
  ) async throws -> FileContentDownload {
    var queryItems: [URLQueryItem] = []
    if let workspaceID {
      queryItems.append(.init(name: "workspace_id", value: workspaceID.uuidString))
    }
    if let provider { queryItems.append(.init(name: "provider", value: provider)) }
    let response = try await transport.getData(
      path: .preEscaped("files/\(escapePathSegment(id))/content"), queryItems: queryItems,
      accept: "application/octet-stream", options: options)
    return .init(data: response.data, contentType: response.contentType)
  }

  public var files: FilesResource { FilesResource(client: self) }

  public struct FilesResource: Sendable {
    fileprivate let client: OpenRouterClient

    /// Irreversibly deletes a file. Explicit caller authorization is required.
    /// Uploaded/downloadable status is irrelevant to deletion.
    public func delete(
      id: String, workspaceID: UUID? = nil, provider: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> FileDeleteResponse {
      try await client.deleteFile(
        id: id, workspaceID: workspaceID, provider: provider, options: options)
    }

    public func list(
      limit: Int? = nil, cursor: String? = nil, workspaceID: UUID? = nil,
      provider: String? = nil, after: String? = nil, afterID: String? = nil,
      beforeID: String? = nil, order: String? = nil, options: RequestOptions? = nil
    ) async throws -> FileListResponse {
      try await client.listFiles(
        limit: limit, cursor: cursor, workspaceID: workspaceID, provider: provider,
        after: after, afterID: afterID, beforeID: beforeID, order: order, options: options)
    }

    public func get(
      id: String, workspaceID: UUID? = nil, provider: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> FileResponse {
      try await client.getFile(
        id: id, workspaceID: workspaceID, provider: provider, options: options)
    }

    public func content(
      id: String, workspaceID: UUID? = nil, provider: String? = nil,
      options: RequestOptions? = nil
    ) async throws -> FileContentDownload {
      try await client.downloadFileContent(
        id: id, workspaceID: workspaceID, provider: provider, options: options)
    }

    public func upload(
      _ file: FileUpload,
      workspaceID: UUID? = nil,
      options: RequestOptions? = nil
    ) async throws -> FileMetadata {
      try await client.uploadFile(file, workspaceID: workspaceID, options: options)
    }
  }
}
