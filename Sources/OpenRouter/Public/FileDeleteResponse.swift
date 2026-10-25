import Foundation

/// A deletion result in its negotiated wire shape. Unknown shapes never confirm deletion.
public enum FileDeleteResponse: Codable, Sendable, Equatable {
  case openRouter(FileDeleted)
  case anthropic(FileDeleted)
  case openAI(OpenAIFileDeleted)
  case unknown(JSONValue)

  private enum CodingKeys: String, CodingKey {
    case shape = "_shape"
    case object, deleted
  }

  public var id: String? {
    switch self {
    case .openRouter(let file), .anthropic(let file): return file.id
    case .openAI(let file): return file.id
    case .unknown: return nil
    }
  }

  /// Checks both typed fields and the authoritative raw payload. Mutating either can
  /// invalidate confirmation; mutations to typed fields do not rebuild the wire payload.
  public var isConfirmed: Bool {
    switch self {
    case .openRouter(let file), .anthropic(let file):
      guard case .object(let raw) = file.rawPayload else { return false }
      return file.type == "file_deleted" && raw["type"] == .string("file_deleted")
        && raw["id"] == .string(file.id)
    case .openAI(let file):
      guard case .object(let raw) = file.rawPayload else { return false }
      return file.object == "file" && file.deleted && raw["object"] == .string("file")
        && raw["deleted"] == .bool(true) && raw["id"] == .string(file.id)
    case .unknown: return false
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.shape) {
      switch try container.decode(String.self, forKey: .shape) {
      case "openrouter": self = .openRouter(try FileDeleted(from: decoder))
      case "anthropic": self = .anthropic(try FileDeleted(from: decoder))
      case "openai": self = .openAI(try OpenAIFileDeleted(from: decoder))
      default: self = .unknown(try JSONValue(from: decoder))
      }
    } else if container.contains(.object) || container.contains(.deleted) {
      self = .openAI(try OpenAIFileDeleted(from: decoder))
    } else {
      self = .openRouter(try FileDeleted(from: decoder))
    }
  }

  public func encode(to encoder: Encoder) throws {
    let payload: JSONValue
    let shape: String
    switch self {
    case .openRouter(let file): (payload, shape) = (file.rawPayload, "openrouter")
    case .anthropic(let file): (payload, shape) = (file.rawPayload, "anthropic")
    case .openAI(let file): (payload, shape) = (file.rawPayload, "openai")
    case .unknown(let raw): return try raw.encode(to: encoder)
    }
    guard case .object(var fields) = payload else {
      throw EncodingError.invalidValue(
        payload,
        .init(codingPath: encoder.codingPath, debugDescription: "Expected a file deletion object"))
    }
    fields["_shape"] = .string(shape)
    try JSONValue.object(fields).encode(to: encoder)
  }
}

/// Native/Anthropic deletion result. Encoding uses `rawPayload` verbatim, preserving extras.
/// The initializer builds it unless supplied; later field mutations do not rebuild it.
public struct FileDeleted: Codable, Sendable, Equatable {
  public var id: String
  public var type: String
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey { case id, type }

  public init(id: String, type: String = "file_deleted", rawPayload: JSONValue? = nil) {
    self.id = id
    self.type = type
    self.rawPayload = rawPayload ?? .object(["id": .string(id), "type": .string(type)])
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    type = try container.decode(String.self, forKey: .type)
    guard type == "file_deleted" else {
      throw DecodingError.dataCorruptedError(
        forKey: .type, in: container, debugDescription: "Expected file_deleted")
    }
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}

/// OpenAI deletion result. Encoding uses `rawPayload` verbatim, preserving extras.
/// The initializer builds it unless supplied; later field mutations do not rebuild it.
public struct OpenAIFileDeleted: Codable, Sendable, Equatable {
  public var id: String
  public var object: String
  public var deleted: Bool
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey { case id, object, deleted }

  public init(
    id: String, object: String = "file", deleted: Bool, rawPayload: JSONValue? = nil
  ) {
    self.id = id
    self.object = object
    self.deleted = deleted
    self.rawPayload =
      rawPayload
      ?? .object([
        "id": .string(id), "object": .string(object), "deleted": .bool(deleted),
      ])
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    object = try container.decode(String.self, forKey: .object)
    deleted = try container.decode(Bool.self, forKey: .deleted)
    guard object == "file" else {
      throw DecodingError.dataCorruptedError(
        forKey: .object, in: container, debugDescription: "Expected file")
    }
    guard deleted else {
      throw DecodingError.dataCorruptedError(
        forKey: .deleted, in: container, debugDescription: "Expected confirmed deletion")
    }
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}
