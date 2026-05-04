import Foundation

public struct ChatCompletionRequest: Codable, Sendable, Equatable {
  public var model: String
  public var messages: [ChatMessage]
  public var stream: Bool?
  public var tools: [ChatTool]?
  public var toolChoice: ToolChoice?
  public var responseFormat: ChatResponseFormat?

  enum CodingKeys: String, CodingKey {
    case model
    case messages
    case stream
    case tools
    case toolChoice = "tool_choice"
    case responseFormat = "response_format"
  }

  public init(
    model: String,
    messages: [ChatMessage],
    stream: Bool? = nil,
    tools: [ChatTool]? = nil,
    toolChoice: ToolChoice? = nil,
    responseFormat: ChatResponseFormat? = nil
  ) {
    self.model = model
    self.messages = messages
    self.stream = stream
    self.tools = tools
    self.toolChoice = toolChoice
    self.responseFormat = responseFormat
  }
}

public struct ChatCompletionResponse: Codable, Sendable, Equatable {
  public var id: String?
  public var model: String?
  public var choices: [Choice]
  public var usage: Usage?

  public init(id: String? = nil, model: String? = nil, choices: [Choice], usage: Usage? = nil) {
    self.id = id
    self.model = model
    self.choices = choices
    self.usage = usage
  }

  public struct Choice: Codable, Sendable, Equatable {
    public var index: Int?
    public var message: ChatMessage
    public var finishReason: String?

    enum CodingKeys: String, CodingKey {
      case index
      case message
      case finishReason = "finish_reason"
    }

    public init(index: Int? = nil, message: ChatMessage, finishReason: String? = nil) {
      self.index = index
      self.message = message
      self.finishReason = finishReason
    }
  }
}

public struct ChatCompletionChunk: Codable, Sendable, Equatable {
  public var id: String?
  public var model: String?
  public var choices: [Choice]

  public init(id: String? = nil, model: String? = nil, choices: [Choice]) {
    self.id = id
    self.model = model
    self.choices = choices
  }

  public struct Choice: Codable, Sendable, Equatable {
    public var index: Int?
    public var delta: Delta?
    public var finishReason: String?

    enum CodingKeys: String, CodingKey {
      case index
      case delta
      case finishReason = "finish_reason"
    }

    public init(index: Int? = nil, delta: Delta? = nil, finishReason: String? = nil) {
      self.index = index
      self.delta = delta
      self.finishReason = finishReason
    }
  }

  public struct Delta: Codable, Sendable, Equatable {
    public var role: ChatMessage.Role?
    public var content: String?

    public init(role: ChatMessage.Role? = nil, content: String? = nil) {
      self.role = role
      self.content = content
    }
  }
}

public struct ChatMessage: Codable, Sendable, Equatable {
  public enum Role: String, Codable, Sendable {
    case system
    case user
    case assistant
    case tool
  }

  public var role: Role
  public var content: Content
  public var name: String?
  public var toolCalls: [ToolCall]?
  public var toolCallID: String?

  enum CodingKeys: String, CodingKey {
    case role
    case content
    case name
    case toolCalls = "tool_calls"
    case toolCallID = "tool_call_id"
  }

  public init(
    role: Role,
    content: Content,
    name: String? = nil,
    toolCalls: [ToolCall]? = nil,
    toolCallID: String? = nil
  ) {
    self.role = role
    self.content = content
    self.name = name
    self.toolCalls = toolCalls
    self.toolCallID = toolCallID
  }

  public static func user(_ text: String) -> Self {
    Self(role: .user, content: .text(text))
  }

  public static func system(_ text: String) -> Self {
    Self(role: .system, content: .text(text))
  }
}

public enum Content: Codable, Sendable, Equatable {
  case text(String)
  case parts([ContentPart])

  public init(from decoder: Decoder) throws {
    let single = try decoder.singleValueContainer()
    if let value = try? single.decode(String.self) {
      self = .text(value)
      return
    }
    if let value = try? single.decode([ContentPart].self) {
      self = .parts(value)
      return
    }
    throw DecodingError.typeMismatch(
      Content.self,
      .init(codingPath: decoder.codingPath, debugDescription: "Expected string or array content")
    )
  }

  public func encode(to encoder: Encoder) throws {
    var single = encoder.singleValueContainer()
    switch self {
    case .text(let value):
      try single.encode(value)
    case .parts(let parts):
      try single.encode(parts)
    }
  }
}

public enum ContentPart: Codable, Sendable, Equatable {
  case text(String)
  case imageURL(String)
  case fileURL(String)
  case inputAudio(InputAudio)
  case unknown(type: String, payload: JSONValue)

  private enum CodingKeys: String, CodingKey {
    case type
    case text
    case imageURL = "image_url"
    case fileURL = "file_url"
    case inputAudio = "input_audio"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)
    switch type {
    case "text":
      self = .text(try container.decode(String.self, forKey: .text))
    case "image_url":
      self = .imageURL(try container.decode(String.self, forKey: .imageURL))
    case "file_url":
      self = .fileURL(try container.decode(String.self, forKey: .fileURL))
    case "input_audio":
      self = .inputAudio(try container.decode(InputAudio.self, forKey: .inputAudio))
    default:
      let value = try JSONValue(from: decoder)
      self = .unknown(type: type, payload: value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .text(let text):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode("text", forKey: .type)
      try container.encode(text, forKey: .text)
    case .imageURL(let url):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode("image_url", forKey: .type)
      try container.encode(url, forKey: .imageURL)
    case .fileURL(let url):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode("file_url", forKey: .type)
      try container.encode(url, forKey: .fileURL)
    case .inputAudio(let audio):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode("input_audio", forKey: .type)
      try container.encode(audio, forKey: .inputAudio)
    case .unknown(_, let payload):
      try payload.encode(to: encoder)
    }
  }
}

public struct InputAudio: Codable, Sendable, Equatable {
  public var data: String
  public var format: String

  public init(data: String, format: String) {
    self.data = data
    self.format = format
  }
}

public struct ToolCall: Codable, Sendable, Equatable {
  public var id: String?
  public var type: String
  public var function: ToolFunctionCall

  public init(id: String? = nil, type: String = "function", function: ToolFunctionCall) {
    self.id = id
    self.type = type
    self.function = function
  }
}

public struct ToolFunctionCall: Codable, Sendable, Equatable {
  public var name: String
  public var arguments: String

  public init(name: String, arguments: String) {
    self.name = name
    self.arguments = arguments
  }
}

public struct EmbeddingRequest: Codable, Sendable, Equatable {
  public var model: String
  public var input: EmbeddingInput

  public init(model: String, input: EmbeddingInput) {
    self.model = model
    self.input = input
  }
}

public struct EmbeddingResponse: Codable, Sendable, Equatable {
  public var model: String?
  public var data: [EmbeddingData]
  public var usage: Usage?

  public init(model: String? = nil, data: [EmbeddingData], usage: Usage? = nil) {
    self.model = model
    self.data = data
    self.usage = usage
  }
}

public struct EmbeddingData: Codable, Sendable, Equatable {
  public var index: Int
  public var embedding: [Double]

  public init(index: Int, embedding: [Double]) {
    self.index = index
    self.embedding = embedding
  }
}

public struct CompletionRequest: Codable, Sendable, Equatable {
  public var model: String
  public var prompt: String
  public var maxTokens: Int?

  enum CodingKeys: String, CodingKey {
    case model
    case prompt
    case maxTokens = "max_tokens"
  }

  public init(model: String, prompt: String, maxTokens: Int? = nil) {
    self.model = model
    self.prompt = prompt
    self.maxTokens = maxTokens
  }
}

public struct CompletionResponse: Codable, Sendable, Equatable {
  public var id: String?
  public var model: String?
  public var choices: [Choice]
  public var usage: Usage?

  public init(id: String? = nil, model: String? = nil, choices: [Choice], usage: Usage? = nil) {
    self.id = id
    self.model = model
    self.choices = choices
    self.usage = usage
  }

  public struct Choice: Codable, Sendable, Equatable {
    public var index: Int?
    public var text: String
    public var finishReason: String?

    enum CodingKeys: String, CodingKey {
      case index
      case text
      case finishReason = "finish_reason"
    }

    public init(index: Int? = nil, text: String, finishReason: String? = nil) {
      self.index = index
      self.text = text
      self.finishReason = finishReason
    }
  }
}

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

public struct Usage: Codable, Sendable, Equatable {
  public var promptTokens: Int?
  public var completionTokens: Int?
  public var totalTokens: Int?

  enum CodingKeys: String, CodingKey {
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case totalTokens = "total_tokens"
  }

  public init(promptTokens: Int? = nil, completionTokens: Int? = nil, totalTokens: Int? = nil) {
    self.promptTokens = promptTokens
    self.completionTokens = completionTokens
    self.totalTokens = totalTokens
  }
}

public enum EmbeddingInput: Codable, Sendable, Equatable {
  case string(String)
  case strings([String])

  public init(from decoder: Decoder) throws {
    let single = try decoder.singleValueContainer()
    if let value = try? single.decode(String.self) {
      self = .string(value)
      return
    }
    if let value = try? single.decode([String].self) {
      self = .strings(value)
      return
    }
    throw DecodingError.typeMismatch(
      EmbeddingInput.self,
      .init(codingPath: decoder.codingPath, debugDescription: "Expected string or array of strings")
    )
  }

  public func encode(to encoder: Encoder) throws {
    var single = encoder.singleValueContainer()
    switch self {
    case .string(let value):
      try single.encode(value)
    case .strings(let value):
      try single.encode(value)
    }
  }
}

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
