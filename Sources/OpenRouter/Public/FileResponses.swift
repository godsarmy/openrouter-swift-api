import Foundation

/// A retrieved file in its negotiated wire shape.
public enum FileResponse: Codable, Sendable, Equatable {
  case openRouter(FileMetadata)
  case anthropic(FileMetadata)
  case openAI(OpenAIFileMetadata)
  case unknown(JSONValue)

  private enum CodingKeys: String, CodingKey {
    case shape = "_shape"
    case object
    case createdAt = "created_at"
  }

  public var id: String? {
    switch self {
    case .openRouter(let file), .anthropic(let file): return file.id
    case .openAI(let file): return file.id
    case .unknown: return nil
    }
  }

  public var filename: String? {
    switch self {
    case .openRouter(let file), .anthropic(let file): return file.filename
    case .openAI(let file): return file.filename
    case .unknown: return nil
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.shape) {
      switch try container.decode(String.self, forKey: .shape) {
      case "openrouter": self = .openRouter(try FileMetadata(from: decoder))
      case "anthropic": self = .anthropic(try FileMetadata(from: decoder))
      case "openai": self = .openAI(try OpenAIFileMetadata(from: decoder))
      default: self = .unknown(try JSONValue(from: decoder))
      }
    } else if (try? container.decode(String.self, forKey: .object)) == "file"
      || (try? container.decode(Int.self, forKey: .createdAt)) != nil
    {
      self = .openAI(try OpenAIFileMetadata(from: decoder))
    } else {
      self = .openRouter(try FileMetadata(from: decoder))
    }
  }

  public func encode(to encoder: Encoder) throws {
    try wirePayload.encode(to: encoder)
  }

  fileprivate var wirePayload: JSONValue {
    let payload: JSONValue
    let shape: String
    switch self {
    case .openRouter(let file): (payload, shape) = (file.rawPayload, "openrouter")
    case .anthropic(let file): (payload, shape) = (file.rawPayload, "anthropic")
    case .openAI(let file): (payload, shape) = (file.rawPayload, "openai")
    case .unknown(let raw): return raw
    }
    var fields: [String: JSONValue] = [:]
    if case .object(let object) = payload { fields = object }
    fields["_shape"] = .string(shape)
    return .object(fields)
  }
}

/// OpenAI-shaped metadata. Encoding uses `rawPayload` verbatim, as with `FileMetadata`.
/// The initializer builds that payload from its fields unless one is supplied.
public struct OpenAIFileMetadata: Codable, Sendable, Equatable {
  public var id: String
  public var object: String
  public var filename: String
  public var purpose: String
  public var status: String
  public var bytes: Int
  public var createdAt: Int
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey {
    case id, object, filename, purpose, status, bytes
    case createdAt = "created_at"
  }

  public init(
    id: String, object: String, filename: String, purpose: String, status: String,
    bytes: Int, createdAt: Int, rawPayload: JSONValue? = nil
  ) {
    self.id = id
    self.object = object
    self.filename = filename
    self.purpose = purpose
    self.status = status
    self.bytes = bytes
    self.createdAt = createdAt
    self.rawPayload =
      rawPayload
      ?? .object([
        "id": .string(id), "object": .string(object), "filename": .string(filename),
        "purpose": .string(purpose), "status": .string(status),
        "bytes": .number(Double(bytes)), "created_at": .number(Double(createdAt)),
      ])
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    object = try container.decode(String.self, forKey: .object)
    filename = try container.decode(String.self, forKey: .filename)
    purpose = try container.decode(String.self, forKey: .purpose)
    status = try container.decode(String.self, forKey: .status)
    bytes = try container.decode(Int.self, forKey: .bytes)
    createdAt = try container.decode(Int.self, forKey: .createdAt)
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}

/// A file page. Encoding uses `rawPayload` verbatim; later field mutations do not rebuild it.
public struct FileListResponse: Codable, Sendable, Equatable {
  public var data: [FileResponse]
  public var hasMore: Bool
  public var shape: String?
  public var firstID: String?
  public var lastID: String?
  public var cursor: String?
  public var object: String?
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey {
    case data, cursor, object
    case shape = "_shape"
    case hasMore = "has_more"
    case firstID = "first_id"
    case lastID = "last_id"
  }

  /// Nonthrowing; builds a wire payload from the supplied fields unless `rawPayload` is supplied.
  public init(
    data: [FileResponse], hasMore: Bool, shape: String? = nil, firstID: String? = nil,
    lastID: String? = nil, cursor: String? = nil, object: String? = nil,
    rawPayload: JSONValue? = nil
  ) {
    self.data = data
    self.hasMore = hasMore
    self.shape = shape
    self.firstID = firstID
    self.lastID = lastID
    self.cursor = cursor
    self.object = object
    var fields: [String: JSONValue] = [
      "data": .array(data.map(\.wirePayload)), "has_more": .bool(hasMore),
      "first_id": firstID.map(JSONValue.string) ?? .null,
      "last_id": lastID.map(JSONValue.string) ?? .null,
      "cursor": cursor.map(JSONValue.string) ?? .null,
    ]
    if let shape { fields["_shape"] = .string(shape) }
    if let object { fields["object"] = .string(object) }
    self.rawPayload = rawPayload ?? .object(fields)
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    data = try container.decode([FileResponse].self, forKey: .data)
    hasMore = try container.decode(Bool.self, forKey: .hasMore)
    shape = container.contains(.shape) ? try container.decode(String.self, forKey: .shape) : nil
    firstID = try container.decodeIfPresent(String.self, forKey: .firstID)
    lastID = try container.decodeIfPresent(String.self, forKey: .lastID)
    cursor = try container.decodeIfPresent(String.self, forKey: .cursor)
    object = try container.decodeIfPresent(String.self, forKey: .object)
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}

/// Downloaded file bytes and the response's optional content type.
public struct FileContentDownload: Sendable, Equatable {
  public var data: Data
  public var contentType: String?

  public init(data: Data, contentType: String? = nil) {
    self.data = data
    self.contentType = contentType
  }
}
