import Foundation

/// Confirms terminal batch artifact purge, not cancellation; billing and audit records remain.
/// Provider deletion is described separately by `deletion.upstream`, not implied by this response.
/// Encoding uses authoritative `rawPayload`, preserving unknown nested extensions.
/// Mutating typed fields does not rewrite that payload.
public struct BatchDeleteResponse: Codable, Sendable, Equatable {
  public var id: String
  public var object: String
  public var deletion: BatchDeletionTargets
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey {
    case id, object, deletion
  }

  public init(
    id: String, object: String = "batch", deletion: BatchDeletionTargets,
    rawPayload: JSONValue? = nil
  ) {
    self.id = id
    self.object = object
    self.deletion = deletion
    self.rawPayload =
      rawPayload
      ?? .object([
        "id": .string(id), "object": .string(object), "deletion": deletion.payload,
      ])
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    object = try container.decode(String.self, forKey: .object)
    guard object == "batch" else {
      throw DecodingError.dataCorruptedError(
        forKey: .object, in: container, debugDescription: "Expected batch object marker")
    }
    deletion = try container.decode(BatchDeletionTargets.self, forKey: .deletion)
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}

/// OpenRouter cleanup and the upstream outcome, omitted when no provider was assigned.
public struct BatchDeletionTargets: Codable, Sendable, Equatable {
  public var openRouter: String
  public var upstream: BatchUpstreamDeletion?

  private enum CodingKeys: String, CodingKey {
    case openRouter = "openrouter"
    case upstream
  }

  public init(openRouter: String = "deleted", upstream: BatchUpstreamDeletion? = nil) {
    self.openRouter = openRouter
    self.upstream = upstream
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    openRouter = try container.decode(String.self, forKey: .openRouter)
    guard openRouter == "deleted" else {
      throw DecodingError.dataCorruptedError(
        forKey: .openRouter, in: container, debugDescription: "Expected deleted cleanup marker")
    }
    upstream =
      container.contains(.upstream)
      ? try container.decode(BatchUpstreamDeletion.self, forKey: .upstream) : nil
  }

  fileprivate var payload: JSONValue {
    var fields: [String: JSONValue] = ["openrouter": .string(openRouter)]
    if let upstream {
      fields["upstream"] = .object([
        "provider": .string(upstream.provider), "status": .string(upstream.status),
      ])
    }
    return .object(fields)
  }
}

/// A provider's deletion outcome. Status is open-ended, including future server values.
public struct BatchUpstreamDeletion: Codable, Sendable, Equatable {
  public var provider: String
  public var status: String

  private enum CodingKeys: String, CodingKey {
    case provider, status
  }

  public init(provider: String, status: String) {
    self.provider = provider
    self.status = status
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    provider = try container.decode(String.self, forKey: .provider)
    guard !provider.isEmpty else {
      throw DecodingError.dataCorruptedError(
        forKey: .provider, in: container, debugDescription: "Expected nonempty provider name")
    }
    status = try container.decode(String.self, forKey: .status)
  }
}
