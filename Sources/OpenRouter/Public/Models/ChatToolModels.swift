import Foundation

public struct ChatTool: Codable, Sendable, Equatable {
  public var type: String
  public var function: ChatToolFunction

  public init(type: String = "function", function: ChatToolFunction) {
    self.type = type
    self.function = function
  }
}

public struct ChatToolFunction: Codable, Sendable, Equatable {
  public var name: String
  public var description: String?
  public var parameters: JSONValue?

  public init(name: String, description: String? = nil, parameters: JSONValue? = nil) {
    self.name = name
    self.description = description
    self.parameters = parameters
  }
}

public enum ToolChoice: Codable, Sendable, Equatable {
  case auto
  case none
  case required
  case function(name: String)

  public init(from decoder: Decoder) throws {
    let single = try decoder.singleValueContainer()
    if let value = try? single.decode(String.self) {
      switch value {
      case "auto": self = .auto
      case "none": self = .none
      case "required": self = .required
      default:
        throw DecodingError.dataCorruptedError(
          in: single, debugDescription: "Unsupported tool_choice string: \(value)"
        )
      }
      return
    }

    let obj = try single.decode(ToolChoiceFunctionPayload.self)
    self = .function(name: obj.function.name)
  }

  public func encode(to encoder: Encoder) throws {
    var single = encoder.singleValueContainer()
    switch self {
    case .auto:
      try single.encode("auto")
    case .none:
      try single.encode("none")
    case .required:
      try single.encode("required")
    case .function(let name):
      try single.encode(ToolChoiceFunctionPayload(function: .init(name: name)))
    }
  }
}

private struct ToolChoiceFunctionPayload: Codable, Sendable, Equatable {
  var type: String = "function"
  var function: FunctionRef
}

private struct FunctionRef: Codable, Sendable, Equatable {
  var name: String
}

public struct ChatResponseFormat: Codable, Sendable, Equatable {
  public var type: String
  public var jsonSchema: JSONSchemaWrapper?

  enum CodingKeys: String, CodingKey {
    case type
    case jsonSchema = "json_schema"
  }

  public init(type: String, jsonSchema: JSONSchemaWrapper? = nil) {
    self.type = type
    self.jsonSchema = jsonSchema
  }
}

public struct JSONSchemaWrapper: Codable, Sendable, Equatable {
  public var name: String
  public var strict: Bool?
  public var schema: JSONValue

  public init(name: String, strict: Bool? = nil, schema: JSONValue) {
    self.name = name
    self.strict = strict
    self.schema = schema
  }
}
