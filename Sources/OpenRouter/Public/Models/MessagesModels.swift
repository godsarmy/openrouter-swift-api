import Foundation

// MARK: - Anthropic Messages API

public struct MessagesRequest: Codable, Sendable, Equatable {
  public var model: String
  public var models: [String]?
  public var messages: [MessagesMessage]
  public var maxTokens: Int
  public var system: MessagesSystemPrompt?
  public var stream: Bool?
  public var temperature: Double?
  public var topP: Double?
  public var topK: Int?
  public var stopSequences: [String]?
  public var thinking: MessagesThinking?
  public var tools: [MessagesTool]?
  public var toolChoice: MessagesToolChoice?
  public var cacheControl: CacheControl?
  public var provider: ProviderPreferences?
  public var sessionID: String?
  public var serviceTier: String?
  public var metadata: JSONValue?
  public var user: String?
  enum CodingKeys: String, CodingKey {
    case model, models, messages
    case maxTokens = "max_tokens"
    case system, stream, temperature
    case topP = "top_p"
    case topK = "top_k"
    case stopSequences = "stop_sequences"
    case thinking, tools
    case toolChoice = "tool_choice"
    case cacheControl = "cache_control"
    case provider
    case sessionID = "session_id"
    case serviceTier = "service_tier"
    case metadata, user
  }
  public init(
    model: String, models: [String]? = nil, messages: [MessagesMessage], maxTokens: Int,
    system: MessagesSystemPrompt? = nil, stream: Bool? = nil, temperature: Double? = nil,
    topP: Double? = nil, topK: Int? = nil, stopSequences: [String]? = nil,
    thinking: MessagesThinking? = nil, tools: [MessagesTool]? = nil,
    toolChoice: MessagesToolChoice? = nil, cacheControl: CacheControl? = nil,
    provider: ProviderPreferences? = nil, sessionID: String? = nil, serviceTier: String? = nil,
    metadata: JSONValue? = nil, user: String? = nil
  ) {
    self.model = model
    self.models = models
    self.messages = messages
    self.maxTokens = maxTokens
    self.system = system
    self.stream = stream
    self.temperature = temperature
    self.topP = topP
    self.topK = topK
    self.stopSequences = stopSequences
    self.thinking = thinking
    self.tools = tools
    self.toolChoice = toolChoice
    self.cacheControl = cacheControl
    self.provider = provider
    self.sessionID = sessionID
    self.serviceTier = serviceTier
    self.metadata = metadata
    self.user = user
  }
}

public struct MessagesMessage: Codable, Sendable, Equatable {
  public var role: Role
  public var content: MessagesContent
  public init(role: Role, content: MessagesContent) {
    self.role = role
    self.content = content
  }
  public enum Role: String, Codable, Sendable { case user, assistant }
}
public enum MessagesContent: Codable, Sendable, Equatable {
  case text(String)
  case blocks([MessagesContentBlock])
  public init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if let text = try? c.decode(String.self) {
      self = .text(text)
    } else {
      self = .blocks(try c.decode([MessagesContentBlock].self))
    }
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .text(let v): try c.encode(v)
    case .blocks(let v): try c.encode(v)
    }
  }
}

public enum MessagesSystemPrompt: Codable, Sendable, Equatable {
  case text(String)
  case blocks([MessagesSystemTextBlock])
  public init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if let text = try? c.decode(String.self) {
      self = .text(text)
    } else {
      self = .blocks(try c.decode([MessagesSystemTextBlock].self))
    }
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .text(let value): try c.encode(value)
    case .blocks(let value): try c.encode(value)
    }
  }
}
public struct MessagesSystemTextBlock: Codable, Sendable, Equatable {
  public var text: String
  public var rawPayload: JSONValue?
  enum CodingKeys: String, CodingKey { case type, text }
  public init(text: String) {
    self.text = text
    rawPayload = nil
  }
  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    guard try c.decode(String.self, forKey: .type) == "text" else {
      throw DecodingError.dataCorruptedError(
        forKey: .type, in: c, debugDescription: "System blocks must be text")
    }
    text = try c.decode(String.self, forKey: .text)
  }
  public func encode(to encoder: Encoder) throws {
    if let rawPayload {
      try rawPayload.encode(to: encoder)
    } else {
      var c = encoder.container(keyedBy: CodingKeys.self)
      try c.encode("text", forKey: .type)
      try c.encode(text, forKey: .text)
    }
  }
}

public enum MessagesContentBlock: Codable, Sendable, Equatable {
  case text(String)
  case image(JSONValue)
  case document(JSONValue)
  case toolUse(id: String, name: String, input: JSONValue)
  case toolResult(toolUseID: String, content: MessagesContent? = nil, isError: Bool? = nil)
  case thinking(thinking: String, signature: String?)
  case redactedThinking(String)
  case raw(JSONValue)
  case unknown(type: String, rawPayload: JSONValue)
  private enum Keys: String, CodingKey {
    case type
    case text
    case source
    case id
    case name
    case input
    case toolUseID = "tool_use_id"
    case content
    case thinking
    case signature
    case data
    case isError = "is_error"
  }
  public init(from decoder: Decoder) throws {
    let raw = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: Keys.self)
    let type = try c.decode(String.self, forKey: .type)
    switch type {
    case "text": self = .text(try c.decode(String.self, forKey: .text))
    case "image": self = .image(try c.decode(JSONValue.self, forKey: .source))
    case "document": self = .document(try c.decode(JSONValue.self, forKey: .source))
    case "tool_use":
      self = .toolUse(
        id: try c.decode(String.self, forKey: .id), name: try c.decode(String.self, forKey: .name),
        input: try c.decode(JSONValue.self, forKey: .input))
    case "tool_result":
      self = .toolResult(
        toolUseID: try c.decode(String.self, forKey: .toolUseID),
        content: try c.decodeIfPresent(MessagesContent.self, forKey: .content),
        isError: try c.decodeIfPresent(Bool.self, forKey: .isError))
    case "thinking":
      self = .thinking(
        thinking: try c.decode(String.self, forKey: .thinking),
        signature: try c.decodeIfPresent(String.self, forKey: .signature))
    case "redacted_thinking": self = .redactedThinking(try c.decode(String.self, forKey: .data))
    default: self = .unknown(type: type, rawPayload: raw)
    }
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: Keys.self)
    switch self {
    case .text(let v):
      try c.encode("text", forKey: .type)
      try c.encode(v, forKey: .text)
    case .image(let v):
      try c.encode("image", forKey: .type)
      try c.encode(v, forKey: .source)
    case .document(let v):
      try c.encode("document", forKey: .type)
      try c.encode(v, forKey: .source)
    case .toolUse(let id, let name, let input):
      try c.encode("tool_use", forKey: .type)
      try c.encode(id, forKey: .id)
      try c.encode(name, forKey: .name)
      try c.encode(input, forKey: .input)
    case .toolResult(let id, let content, let isError):
      try c.encode("tool_result", forKey: .type)
      try c.encode(id, forKey: .toolUseID)
      try c.encodeIfPresent(content, forKey: .content)
      try c.encodeIfPresent(isError, forKey: .isError)
    case .thinking(let text, let signature):
      try c.encode("thinking", forKey: .type)
      try c.encode(text, forKey: .thinking)
      try c.encodeIfPresent(signature, forKey: .signature)
    case .redactedThinking(let data):
      try c.encode("redacted_thinking", forKey: .type)
      try c.encode(data, forKey: .data)
    case .unknown(_, let raw): try raw.encode(to: encoder)
    case .raw(let raw): try raw.encode(to: encoder)
    }
  }
}

public struct MessagesTool: Codable, Sendable, Equatable {
  public var name: String
  public var description: String?
  public var inputSchema: JSONValue?
  public var rawDefinition: JSONValue?
  enum CodingKeys: String, CodingKey {
    case name, description
    case inputSchema = "input_schema"
  }
  public init(name: String, description: String? = nil, inputSchema: JSONValue) {
    self.name = name
    self.description = description
    self.inputSchema = inputSchema
    rawDefinition = nil
  }
  public init(rawDefinition: JSONValue) {
    self.name = ""
    self.description = nil
    self.inputSchema = nil
    self.rawDefinition = rawDefinition
  }
  public init(from decoder: Decoder) throws {
    let raw = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
    description = try c.decodeIfPresent(String.self, forKey: .description)
    inputSchema = try c.decodeIfPresent(JSONValue.self, forKey: .inputSchema)
    rawDefinition = raw
  }
  public func encode(to encoder: Encoder) throws {
    if let rawDefinition {
      try rawDefinition.encode(to: encoder)
    } else {
      var c = encoder.container(keyedBy: CodingKeys.self)
      try c.encode(name, forKey: .name)
      try c.encodeIfPresent(description, forKey: .description)
      try c.encodeIfPresent(inputSchema, forKey: .inputSchema)
    }
  }
}
public enum MessagesToolChoice: Codable, Sendable, Equatable {
  case auto(disableParallelToolUse: Bool? = nil)
  case any(disableParallelToolUse: Bool? = nil)
  case none
  case tool(name: String, disableParallelToolUse: Bool? = nil)
  case unknown(JSONValue)
  private struct Payload: Codable {
    var type: String
    var name: String?
    var disableParallelToolUse: Bool?
    enum CodingKeys: String, CodingKey {
      case type, name
      case disableParallelToolUse = "disable_parallel_tool_use"
    }
  }
  public init(from decoder: Decoder) throws {
    let raw = try JSONValue(from: decoder)
    let p = try? Payload(from: decoder)
    switch p?.type {
    case "auto": self = .auto(disableParallelToolUse: p?.disableParallelToolUse)
    case "any": self = .any(disableParallelToolUse: p?.disableParallelToolUse)
    case "none": self = .none
    case "tool":
      if let n = p?.name {
        self = .tool(name: n, disableParallelToolUse: p?.disableParallelToolUse)
      } else {
        self = .unknown(raw)
      }
    default: self = .unknown(raw)
    }
  }
  public func encode(to encoder: Encoder) throws {
    switch self {
    case .auto(let d):
      try Payload(type: "auto", name: nil, disableParallelToolUse: d).encode(to: encoder)
    case .any(let d):
      try Payload(type: "any", name: nil, disableParallelToolUse: d).encode(to: encoder)
    case .none:
      try Payload(type: "none", name: nil, disableParallelToolUse: nil).encode(to: encoder)
    case .tool(let n, let d):
      try Payload(type: "tool", name: n, disableParallelToolUse: d).encode(to: encoder)
    case .unknown(let raw): try raw.encode(to: encoder)
    }
  }
}
public enum MessagesThinking: Codable, Sendable, Equatable {
  case enabled(budgetTokens: Int, display: String? = nil)
  case disabled
  case adaptive(display: String? = nil)
  case unknown(JSONValue)
  private struct Payload: Codable {
    var type: String
    var budgetTokens: Int?
    var display: String?
    enum CodingKeys: String, CodingKey {
      case type, display
      case budgetTokens = "budget_tokens"
    }
  }
  public init(from decoder: Decoder) throws {
    let raw = try JSONValue(from: decoder)
    let p = try Payload(from: decoder)
    switch p.type {
    case "enabled":
      if let b = p.budgetTokens {
        self = .enabled(budgetTokens: b, display: p.display)
      } else {
        self = .unknown(raw)
      }
    case "disabled": self = .disabled
    case "adaptive": self = .adaptive(display: p.display)
    default: self = .unknown(raw)
    }
  }
  public func encode(to encoder: Encoder) throws {
    switch self {
    case .enabled(let b, let d):
      try Payload(type: "enabled", budgetTokens: b, display: d).encode(to: encoder)
    case .disabled:
      try Payload(type: "disabled", budgetTokens: nil, display: nil).encode(to: encoder)
    case .adaptive(let d):
      try Payload(type: "adaptive", budgetTokens: nil, display: d).encode(to: encoder)
    case .unknown(let raw): try raw.encode(to: encoder)
    }
  }
}

public struct MessagesResponse: Codable, Sendable, Equatable {
  public var id: String?
  public var type: String?
  public var role: MessagesMessage.Role?
  public var content: [MessagesContentBlock]
  public var model: String?
  public var stopReason: String?
  public var stopSequence: String?
  public var stopDetails: JSONValue?
  public var usage: MessagesUsage?
  public var provider: JSONValue?
  public var openRouterMetadata: JSONValue?
  public var rawPayload: JSONValue
  enum CodingKeys: String, CodingKey {
    case id, type, role, content, model, usage, provider
    case stopReason = "stop_reason"
    case stopSequence = "stop_sequence"
    case stopDetails = "stop_details"
    case openRouterMetadata = "openrouter_metadata"
  }
  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decodeIfPresent(String.self, forKey: .id)
    type = try c.decodeIfPresent(String.self, forKey: .type)
    role = try c.decodeIfPresent(MessagesMessage.Role.self, forKey: .role)
    content = try c.decodeIfPresent([MessagesContentBlock].self, forKey: .content) ?? []
    model = try c.decodeIfPresent(String.self, forKey: .model)
    stopReason = try c.decodeIfPresent(String.self, forKey: .stopReason)
    stopSequence = try c.decodeIfPresent(String.self, forKey: .stopSequence)
    stopDetails = try c.decodeIfPresent(JSONValue.self, forKey: .stopDetails)
    usage = try c.decodeIfPresent(MessagesUsage.self, forKey: .usage)
    provider = try c.decodeIfPresent(JSONValue.self, forKey: .provider)
    openRouterMetadata = try c.decodeIfPresent(JSONValue.self, forKey: .openRouterMetadata)
  }
  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
  public var assistantMessage: MessagesMessage {
    if case .object(let object) = rawPayload, case .array(let blocks)? = object["content"] {
      return .init(role: .assistant, content: .blocks(blocks.map(MessagesContentBlock.raw)))
    }
    return .init(role: .assistant, content: .blocks(content))
  }
}
public struct MessagesUsage: Codable, Sendable, Equatable {
  public var inputTokens: Int?
  public var outputTokens: Int?
  public var cacheCreationInputTokens: Int?
  public var cacheReadInputTokens: Int?
  public var cost: Double?
  public var rawPayload: JSONValue
  enum CodingKeys: String, CodingKey {
    case inputTokens = "input_tokens"
    case outputTokens = "output_tokens"
    case cacheCreationInputTokens = "cache_creation_input_tokens"
    case cacheReadInputTokens = "cache_read_input_tokens"
    case cost
  }
  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    inputTokens = try c.decodeIfPresent(Int.self, forKey: .inputTokens)
    outputTokens = try c.decodeIfPresent(Int.self, forKey: .outputTokens)
    cacheCreationInputTokens = try c.decodeIfPresent(Int.self, forKey: .cacheCreationInputTokens)
    cacheReadInputTokens = try c.decodeIfPresent(Int.self, forKey: .cacheReadInputTokens)
    cost = try c.decodeIfPresent(Double.self, forKey: .cost)
  }
  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}
public struct MessagesStreamEvent: Codable, Sendable, Equatable {
  public var type: String
  public var eventName: String?
  public var message: MessagesResponse?
  public var index: Int?
  public var contentBlock: MessagesContentBlock?
  public var delta: JSONValue?
  public var textDelta: String?
  public var inputJSONDelta: String?
  public var thinkingDelta: String?
  public var signatureDelta: String?
  public var messageDelta: JSONValue?
  public var usage: MessagesUsage?
  public var error: JSONValue?
  public var rawPayload: JSONValue
  enum CodingKeys: String, CodingKey {
    case type, message, index, delta, usage, error
    case contentBlock = "content_block"
    case messageDelta = "message_delta"
  }
  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    type = try c.decode(String.self, forKey: .type)
    eventName = nil
    message = try? c.decodeIfPresent(MessagesResponse.self, forKey: .message)
    index = try c.decodeIfPresent(Int.self, forKey: .index)
    contentBlock = try? c.decodeIfPresent(MessagesContentBlock.self, forKey: .contentBlock)
    delta = try c.decodeIfPresent(JSONValue.self, forKey: .delta)
    if case .object(let delta)? = delta {
      if case .string(let value)? = delta["text"] { textDelta = value } else { textDelta = nil }
      if case .string(let value)? = delta["partial_json"] {
        inputJSONDelta = value
      } else {
        inputJSONDelta = nil
      }
      if case .string(let value)? = delta["thinking"] {
        thinkingDelta = value
      } else {
        thinkingDelta = nil
      }
      if case .string(let value)? = delta["signature"] {
        signatureDelta = value
      } else {
        signatureDelta = nil
      }
    } else {
      textDelta = nil
      inputJSONDelta = nil
      thinkingDelta = nil
      signatureDelta = nil
    }
    messageDelta = try c.decodeIfPresent(JSONValue.self, forKey: .messageDelta)
    usage = try? c.decodeIfPresent(MessagesUsage.self, forKey: .usage)
    error = try c.decodeIfPresent(JSONValue.self, forKey: .error)
  }
  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
  func withEventName(_ name: String?) -> Self {
    var copy = self
    copy.eventName = name
    return copy
  }
}
