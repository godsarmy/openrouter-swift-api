import Foundation

/// A provider error. `rawPayload` is the nested error object, not the event envelope.
/// Encoding uses the authoritative raw payload rather than the typed snapshots.
public struct ImageGenerationProviderError: Codable, Sendable, Equatable {
  public var message: String
  public var code: String?
  public var param: String?
  public var type: String?
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey { case message, code, param, type }

  public init(
    message: String, code: String? = nil, param: String? = nil, type: String? = nil,
    rawPayload: JSONValue? = nil
  ) {
    self.message = message
    self.code = code
    self.param = param
    self.type = type
    var fields: [String: JSONValue] = ["message": .string(message)]
    if let code { fields["code"] = .string(code) }
    if let param { fields["param"] = .string(param) }
    if let type { fields["type"] = .string(type) }
    self.rawPayload = rawPayload ?? .object(fields)
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    message = try c.decode(String.self, forKey: .message)
    code = try c.decodeIfPresent(String.self, forKey: .code)
    param = try c.decodeIfPresent(String.self, forKey: .param)
    type = try c.decodeIfPresent(String.self, forKey: .type)
    rawPayload = try JSONValue(from: decoder)
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}

public enum ImageGenerationStreamError: Error, Sendable, Equatable {
  case provider(ImageGenerationProviderError)
  case incompleteStream
}

/// An opaque image/text snapshot; fragments are never concatenated or rendered.
/// `rawPayload` retains the full root envelope and is authoritative for encoding.
/// Typed fields are snapshots; `eventName` is SSE metadata only and is never serialized.
public struct ImageGenerationStreamEvent: Codable, Sendable, Equatable {
  public var type: String
  public var eventName: String?
  public var partialImageIndex: Int?
  public var b64JSON: String?
  public var text: String?
  public var phase: String?
  public var created: Int?
  public var mediaType: String?
  public var usage: ImageGenerationUsage?
  public var error: ImageGenerationProviderError?
  public var bufferedResponse: ImageGenerationResponse?
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey {
    case data, type, text, phase, created, usage, error
    case partialImageIndex = "partial_image_index"
    case b64JSON = "b64_json"
    case mediaType = "media_type"
  }

  public init(rawPayload: JSONValue, eventName: String? = nil) throws {
    self = try JSONDecoder().decode(Self.self, from: JSONEncoder().encode(rawPayload))
    self.eventName = eventName
  }

  /// Normalizes an HTTP JSON response without inventing an SSE wire envelope.
  public init(bufferedResponse: ImageGenerationResponse) {
    type = "image_generation.buffered_response"
    self.bufferedResponse = bufferedResponse
    created = bufferedResponse.created
    usage = bufferedResponse.usage
    rawPayload = bufferedResponse.rawPayload
  }

  public init(from decoder: Decoder) throws {
    let root = try decoder.container(keyedBy: CodingKeys.self)
    let payloadDecoder = try root.superDecoder(forKey: .data)
    if (try? payloadDecoder.unkeyedContainer()) != nil {
      self = Self(bufferedResponse: try ImageGenerationResponse(from: decoder))
      return
    }
    let c = try payloadDecoder.container(keyedBy: CodingKeys.self)
    type = try c.decode(String.self, forKey: .type)
    switch type {
    case "image_generation.partial_image":
      partialImageIndex = try c.decode(Int.self, forKey: .partialImageIndex)
      b64JSON = try c.decode(String.self, forKey: .b64JSON)
    case "image_generation.text_chunk":
      text = try c.decode(String.self, forKey: .text)
      phase = try c.decode(String.self, forKey: .phase)
    case "image_generation.completed":
      b64JSON = try c.decode(String.self, forKey: .b64JSON)
      created = try c.decode(Int.self, forKey: .created)
      mediaType = try c.decodeIfPresent(String.self, forKey: .mediaType)
      usage = try c.decodeIfPresent(ImageGenerationUsage.self, forKey: .usage)
    case "error":
      error = try c.decode(ImageGenerationProviderError.self, forKey: .error)
    default:
      break
    }
    rawPayload = try JSONValue(from: decoder)
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}
