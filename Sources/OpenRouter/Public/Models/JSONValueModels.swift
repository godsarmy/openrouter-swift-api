import Foundation

public enum JSONValue: Codable, Sendable, Equatable {
  case string(String)
  case number(Double)
  case bool(Bool)
  case object([String: JSONValue])
  case array([JSONValue])
  case null

  public init(from decoder: Decoder) throws {
    if let container = try? decoder.container(keyedBy: DynamicCodingKey.self) {
      var object: [String: JSONValue] = [:]
      for key in container.allKeys {
        object[key.stringValue] = try container.decode(JSONValue.self, forKey: key)
      }
      self = .object(object)
      return
    }

    if var container = try? decoder.unkeyedContainer() {
      var values: [JSONValue] = []
      while !container.isAtEnd {
        values.append(try container.decode(JSONValue.self))
      }
      self = .array(values)
      return
    }

    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(Double.self) {
      self = .number(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else {
      throw DecodingError.typeMismatch(
        JSONValue.self,
        .init(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value")
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .string(let value):
      var container = encoder.singleValueContainer()
      try container.encode(value)
    case .number(let value):
      var container = encoder.singleValueContainer()
      try container.encode(value)
    case .bool(let value):
      var container = encoder.singleValueContainer()
      try container.encode(value)
    case .object(let value):
      var container = encoder.container(keyedBy: DynamicCodingKey.self)
      for (key, item) in value {
        guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }
        try container.encode(item, forKey: codingKey)
      }
    case .array(let values):
      var container = encoder.unkeyedContainer()
      for value in values {
        try container.encode(value)
      }
    case .null:
      var container = encoder.singleValueContainer()
      try container.encodeNil()
    }
  }
}

private struct DynamicCodingKey: CodingKey {
  var stringValue: String
  var intValue: Int?

  init?(stringValue: String) {
    self.stringValue = stringValue
    intValue = nil
  }

  init?(intValue: Int) {
    self.intValue = intValue
    stringValue = String(intValue)
  }
}
