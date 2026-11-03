import Foundation

/// Binary content uploaded to the Files API.
public struct FileUpload: Sendable, Equatable {
  public var data: Data
  public var filename: String
  public var mediaType: String?

  public init(data: Data, filename: String, mediaType: String? = nil) {
    self.data = data
    self.filename = filename
    self.mediaType = mediaType
  }
}

/// Metadata returned after a file upload. `rawPayload` retains unmodeled API fields.
public struct FileMetadata: Codable, Sendable, Equatable {
  public var id: String
  public var type: String
  public var filename: String
  public var mimeType: String
  public var sizeBytes: Int
  public var createdAt: String
  public var downloadable: Bool
  public var rawPayload: JSONValue

  enum CodingKeys: String, CodingKey {
    case id, type, filename, downloadable
    case mimeType = "mime_type"
    case sizeBytes = "size_bytes"
    case createdAt = "created_at"
  }

  public init(
    id: String, type: String, filename: String, mimeType: String, sizeBytes: Int, createdAt: String,
    downloadable: Bool, rawPayload: JSONValue? = nil
  ) {
    self.id = id
    self.type = type
    self.filename = filename
    self.mimeType = mimeType
    self.sizeBytes = sizeBytes
    self.createdAt = createdAt
    self.downloadable = downloadable
    self.rawPayload =
      rawPayload
      ?? .object([
        "id": .string(id),
        "type": .string(type),
        "filename": .string(filename),
        "mime_type": .string(mimeType),
        "size_bytes": .number(Double(sizeBytes)),
        "created_at": .string(createdAt),
        "downloadable": .bool(downloadable),
      ])
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    type = try container.decode(String.self, forKey: .type)
    filename = try container.decode(String.self, forKey: .filename)
    mimeType = try container.decode(String.self, forKey: .mimeType)
    sizeBytes = try container.decode(Int.self, forKey: .sizeBytes)
    createdAt = try container.decode(String.self, forKey: .createdAt)
    downloadable = try container.decode(Bool.self, forKey: .downloadable)
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}
