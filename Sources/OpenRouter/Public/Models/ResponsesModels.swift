import Foundation

public struct ResponsesRequest: Codable, Sendable, Equatable {
  public var model: String
  public var input: ResponsesInput
  public var stream: Bool?
  public var maxOutputTokens: Int?
  public var temperature: Double?
  public var topP: Double?
  public var reasoning: ResponsesReasoning?
  public var metadata: JSONValue?
  public var user: String?
  public var sessionID: String?
  public var instructions: String?
  public var previousResponseID: String?
  public var serviceTier: String?
  public var tools: [ResponsesFunctionTool]?
  public var toolChoice: ResponsesToolChoice?
  public var parallelToolCalls: Bool?
  public var include: [String]?

  enum CodingKeys: String, CodingKey {
    case model
    case input
    case stream
    case maxOutputTokens = "max_output_tokens"
    case temperature
    case topP = "top_p"
    case reasoning
    case metadata
    case user
    case sessionID = "session_id"
    case instructions
    case previousResponseID = "previous_response_id"
    case serviceTier = "service_tier"
    case tools
    case toolChoice = "tool_choice"
    case parallelToolCalls = "parallel_tool_calls"
    case include
  }

  public init(
    model: String,
    input: ResponsesInput,
    stream: Bool? = nil,
    maxOutputTokens: Int? = nil,
    temperature: Double? = nil,
    topP: Double? = nil,
    reasoning: ResponsesReasoning? = nil,
    metadata: JSONValue? = nil,
    user: String? = nil,
    sessionID: String? = nil,
    instructions: String? = nil,
    previousResponseID: String? = nil,
    serviceTier: String? = nil,
    tools: [ResponsesFunctionTool]? = nil,
    toolChoice: ResponsesToolChoice? = nil,
    parallelToolCalls: Bool? = nil,
    include: [String]? = nil
  ) {
    self.model = model
    self.input = input
    self.stream = stream
    self.maxOutputTokens = maxOutputTokens
    self.temperature = temperature
    self.topP = topP
    self.reasoning = reasoning
    self.metadata = metadata
    self.user = user
    self.sessionID = sessionID
    self.instructions = instructions
    self.previousResponseID = previousResponseID
    self.serviceTier = serviceTier
    self.tools = tools
    self.toolChoice = toolChoice
    self.parallelToolCalls = parallelToolCalls
    self.include = include
  }
}

/// A forward-compatible Server-Sent Event emitted by the beta Responses API.
/// `rawPayload` preserves fields not yet modeled by this SDK.
public struct ResponsesStreamEvent: Codable, Sendable, Equatable {
  public var type: String
  public var delta: String?
  public var responseID: String?
  public var itemID: String?
  public var outputIndex: Int?
  public var contentIndex: Int?
  public var sequenceNumber: Int?
  public var response: ResponsesResponse?
  public var item: ResponsesOutput?
  public var arguments: String?
  public var rawPayload: JSONValue

  enum CodingKeys: String, CodingKey {
    case type
    case delta
    case responseID = "response_id"
    case itemID = "item_id"
    case outputIndex = "output_index"
    case contentIndex = "content_index"
    case sequenceNumber = "sequence_number"
    case response
    case item
    case arguments
  }

  public init(
    type: String,
    delta: String? = nil,
    responseID: String? = nil,
    itemID: String? = nil,
    outputIndex: Int? = nil,
    contentIndex: Int? = nil,
    sequenceNumber: Int? = nil,
    response: ResponsesResponse? = nil,
    item: ResponsesOutput? = nil,
    arguments: String? = nil,
    rawPayload: JSONValue? = nil
  ) {
    self.type = type
    self.delta = delta
    self.responseID = responseID
    self.itemID = itemID
    self.outputIndex = outputIndex
    self.contentIndex = contentIndex
    self.sequenceNumber = sequenceNumber
    self.response = response
    self.item = item
    self.arguments = arguments
    self.rawPayload = rawPayload ?? .object(["type": .string(type)])
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    type = try container.decode(String.self, forKey: .type)
    delta = try container.decodeIfPresent(String.self, forKey: .delta)
    responseID = try container.decodeIfPresent(String.self, forKey: .responseID)
    itemID = try container.decodeIfPresent(String.self, forKey: .itemID)
    outputIndex = try container.decodeIfPresent(Int.self, forKey: .outputIndex)
    contentIndex = try container.decodeIfPresent(Int.self, forKey: .contentIndex)
    sequenceNumber = try container.decodeIfPresent(Int.self, forKey: .sequenceNumber)
    response = try? container.decodeIfPresent(ResponsesResponse.self, forKey: .response)
    item = try? container.decodeIfPresent(ResponsesOutput.self, forKey: .item)
    arguments = try container.decodeIfPresent(String.self, forKey: .arguments)
  }

  public func encode(to encoder: Encoder) throws {
    try rawPayload.encode(to: encoder)
  }
}

public enum ResponsesInput: Codable, Sendable, Equatable {
  case text(String)
  case messages([ResponsesInputMessage])
  case items([ResponsesInputItem])

  public init(from decoder: Decoder) throws {
    let single = try decoder.singleValueContainer()
    if let value = try? single.decode(String.self) {
      self = .text(value)
      return
    }
    if let value = try? single.decode([ResponsesInputMessage].self) {
      self = .messages(value)
      return
    }
    if let value = try? single.decode([ResponsesInputItem].self) {
      self = .items(value)
      return
    }
    throw DecodingError.typeMismatch(
      ResponsesInput.self,
      .init(
        codingPath: decoder.codingPath,
        debugDescription: "Expected string or response input messages")
    )
  }

  public func encode(to encoder: Encoder) throws {
    var single = encoder.singleValueContainer()
    switch self {
    case .text(let value):
      try single.encode(value)
    case .messages(let value):
      try single.encode(value)
    case .items(let value):
      try single.encode(value)
    }
  }
}

public struct ResponsesFunctionTool: Codable, Sendable, Equatable {
  public var name: String
  public var description: String?
  public var parameters: JSONValue?
  public var strict: Bool?

  enum CodingKeys: String, CodingKey { case type, name, description, parameters, strict }

  public init(
    name: String,
    description: String? = nil,
    parameters: JSONValue? = nil,
    strict: Bool? = nil
  ) {
    self.name = name
    self.description = description
    self.parameters = parameters
    self.strict = strict
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    guard try container.decode(String.self, forKey: .type) == "function" else {
      throw DecodingError.dataCorruptedError(
        forKey: .type, in: container, debugDescription: "Expected function tool")
    }
    name = try container.decode(String.self, forKey: .name)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    parameters = try container.decodeIfPresent(JSONValue.self, forKey: .parameters)
    strict = try container.decodeIfPresent(Bool.self, forKey: .strict)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode("function", forKey: .type)
    try container.encode(name, forKey: .name)
    try container.encodeIfPresent(description, forKey: .description)
    try container.encodeIfPresent(parameters, forKey: .parameters)
    try container.encodeIfPresent(strict, forKey: .strict)
  }
}

public enum ResponsesToolChoice: Codable, Sendable, Equatable {
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
          in: single, debugDescription: "Unsupported tool_choice: \(value)")
      }
      return
    }
    let choice = try single.decode(ResponsesToolChoiceFunction.self)
    guard choice.type == "function" else {
      throw DecodingError.dataCorruptedError(
        in: single, debugDescription: "Expected function tool_choice")
    }
    self = .function(name: choice.name)
  }

  public func encode(to encoder: Encoder) throws {
    var single = encoder.singleValueContainer()
    switch self {
    case .auto: try single.encode("auto")
    case .none: try single.encode("none")
    case .required: try single.encode("required")
    case .function(let name): try single.encode(ResponsesToolChoiceFunction(name: name))
    }
  }
}

private struct ResponsesToolChoiceFunction: Codable, Sendable, Equatable {
  var type = "function"
  var name: String
}

public struct ResponsesInputMessage: Codable, Sendable, Equatable {
  public var type: String?
  public var role: String
  public var content: [ResponsesInputContent]

  public init(type: String? = "message", role: String, content: [ResponsesInputContent]) {
    self.type = type
    self.role = role
    self.content = content
  }
}

public struct ResponsesInputContent: Codable, Sendable, Equatable {
  public var type: String
  public var text: String

  public init(type: String = "input_text", text: String) {
    self.type = type
    self.text = text
  }
}

public enum ResponsesInputItem: Codable, Sendable, Equatable {
  case message(ResponsesInputMessage)
  case functionCall(ResponsesFunctionCall)
  case functionCallOutput(ResponsesFunctionCallOutput)
  case reasoning(ResponsesReasoningItem)

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: ResponsesItemCodingKeys.self)
    guard let type = try container.decodeIfPresent(String.self, forKey: .type) else {
      self = .message(try ResponsesInputMessage(from: decoder))
      return
    }
    switch type {
    case "message": self = .message(try ResponsesInputMessage(from: decoder))
    case "function_call": self = .functionCall(try ResponsesFunctionCall(from: decoder))
    case "function_call_output":
      self = .functionCallOutput(try ResponsesFunctionCallOutput(from: decoder))
    case "reasoning": self = .reasoning(try ResponsesReasoningItem(from: decoder))
    default:
      throw DecodingError.dataCorruptedError(
        forKey: .type, in: container, debugDescription: "Unsupported response input item")
    }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .message(let value):
      var container = encoder.container(keyedBy: ResponsesItemCodingKeys.self)
      try container.encode("message", forKey: .type)
      try value.encode(to: encoder)
    case .functionCall(let value): try value.encode(to: encoder)
    case .functionCallOutput(let value): try value.encode(to: encoder)
    case .reasoning(let value): try value.encode(to: encoder)
    }
  }
}

public struct ResponsesFunctionCall: Codable, Sendable, Equatable {
  public var id: String?
  public var callID: String
  public var name: String
  public var arguments: String
  public var status: String?
  public var namespace: String?

  enum CodingKeys: String, CodingKey {
    case type, id
    case callID = "call_id"
    case name, arguments, status, namespace
  }

  public init(
    id: String? = nil, callID: String, name: String, arguments: String, status: String? = nil,
    namespace: String? = nil
  ) {
    self.id = id
    self.callID = callID
    self.name = name
    self.arguments = arguments
    self.status = status
    self.namespace = namespace
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id)
    callID = try container.decode(String.self, forKey: .callID)
    name = try container.decode(String.self, forKey: .name)
    arguments = try container.decode(String.self, forKey: .arguments)
    status = try container.decodeIfPresent(String.self, forKey: .status)
    namespace = try container.decodeIfPresent(String.self, forKey: .namespace)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode("function_call", forKey: .type)
    try container.encodeIfPresent(id, forKey: .id)
    try container.encode(callID, forKey: .callID)
    try container.encode(name, forKey: .name)
    try container.encode(arguments, forKey: .arguments)
    try container.encodeIfPresent(status, forKey: .status)
    try container.encodeIfPresent(namespace, forKey: .namespace)
  }
}

public enum ResponsesFunctionCallOutputValue: Codable, Sendable, Equatable {
  case text(String)
  case parts([JSONValue])

  public init(from decoder: Decoder) throws {
    let single = try decoder.singleValueContainer()
    if let text = try? single.decode(String.self) {
      self = .text(text)
    } else {
      self = .parts(try single.decode([JSONValue].self))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var single = encoder.singleValueContainer()
    switch self {
    case .text(let value): try single.encode(value)
    case .parts(let value): try single.encode(value)
    }
  }
}

public struct ResponsesFunctionCallOutput: Codable, Sendable, Equatable {
  public var id: String?
  public var callID: String
  public var output: ResponsesFunctionCallOutputValue
  public var status: String?

  enum CodingKeys: String, CodingKey {
    case type, id
    case callID = "call_id"
    case output, status
  }

  public init(
    id: String? = nil, callID: String, output: ResponsesFunctionCallOutputValue,
    status: String? = nil
  ) {
    self.id = id
    self.callID = callID
    self.output = output
    self.status = status
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id)
    callID = try container.decode(String.self, forKey: .callID)
    output = try container.decode(ResponsesFunctionCallOutputValue.self, forKey: .output)
    status = try container.decodeIfPresent(String.self, forKey: .status)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode("function_call_output", forKey: .type)
    try container.encodeIfPresent(id, forKey: .id)
    try container.encode(callID, forKey: .callID)
    try container.encode(output, forKey: .output)
    try container.encodeIfPresent(status, forKey: .status)
  }
}

private enum ResponsesItemCodingKeys: String, CodingKey { case type }

public struct ResponsesReasoningItem: Codable, Sendable, Equatable {
  public var id: String
  public var summary: [ResponsesReasoningSummary]
  public var encryptedContent: String?
  public var content: [ResponsesOutputContent]?
  public var status: String?
  public var format: String?
  public var signature: String?

  enum CodingKeys: String, CodingKey {
    case type, id, summary, content, status, format, signature
    case encryptedContent = "encrypted_content"
  }

  public init(
    id: String,
    summary: [ResponsesReasoningSummary],
    encryptedContent: String? = nil,
    content: [ResponsesOutputContent]? = nil,
    status: String? = nil,
    format: String? = nil,
    signature: String? = nil
  ) {
    self.id = id
    self.summary = summary
    self.encryptedContent = encryptedContent
    self.content = content
    self.status = status
    self.format = format
    self.signature = signature
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    summary = try container.decode([ResponsesReasoningSummary].self, forKey: .summary)
    encryptedContent = try container.decodeIfPresent(String.self, forKey: .encryptedContent)
    content = try container.decodeIfPresent([ResponsesOutputContent].self, forKey: .content)
    status = try container.decodeIfPresent(String.self, forKey: .status)
    format = try container.decodeIfPresent(String.self, forKey: .format)
    signature = try container.decodeIfPresent(String.self, forKey: .signature)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode("reasoning", forKey: .type)
    try container.encode(id, forKey: .id)
    try container.encode(summary, forKey: .summary)
    try container.encodeIfPresent(encryptedContent, forKey: .encryptedContent)
    try container.encodeIfPresent(content, forKey: .content)
    try container.encodeIfPresent(status, forKey: .status)
    try container.encodeIfPresent(format, forKey: .format)
    try container.encodeIfPresent(signature, forKey: .signature)
  }
}

public struct ResponsesReasoning: Codable, Sendable, Equatable {
  public var effort: String?
  public var context: String?

  public init(effort: String? = nil, context: String? = nil) {
    self.effort = effort
    self.context = context
  }
}

public struct ResponsesResponse: Codable, Sendable, Equatable {
  public var id: String
  public var object: String?
  public var createdAt: Int?
  public var model: String?
  public var output: [ResponsesOutput]
  public var usage: ResponsesUsage?
  public var status: String?

  enum CodingKeys: String, CodingKey {
    case id
    case object
    case createdAt = "created_at"
    case model
    case output
    case usage
    case status
  }

  public init(
    id: String,
    object: String? = nil,
    createdAt: Int? = nil,
    model: String? = nil,
    output: [ResponsesOutput],
    usage: ResponsesUsage? = nil,
    status: String? = nil
  ) {
    self.id = id
    self.object = object
    self.createdAt = createdAt
    self.model = model
    self.output = output
    self.usage = usage
    self.status = status
  }
}

public struct ResponsesOutput: Codable, Sendable, Equatable {
  public var id: String?
  public var type: String
  public var status: String?
  public var role: String?
  public var content: [ResponsesOutputContent]?
  public var summary: [ResponsesReasoningSummary]?
  public var encryptedContent: String?
  public var callID: String?
  public var name: String?
  public var arguments: String?
  public var namespace: String?
  public var format: String?
  public var signature: String?

  enum CodingKeys: String, CodingKey {
    case id
    case type
    case status
    case role
    case content
    case summary
    case encryptedContent = "encrypted_content"
    case callID = "call_id"
    case name
    case arguments
    case namespace
    case format
    case signature
  }

  public init(
    id: String? = nil,
    type: String,
    status: String? = nil,
    role: String? = nil,
    content: [ResponsesOutputContent]? = nil,
    summary: [ResponsesReasoningSummary]? = nil,
    encryptedContent: String? = nil,
    callID: String? = nil,
    name: String? = nil,
    arguments: String? = nil,
    namespace: String? = nil,
    format: String? = nil,
    signature: String? = nil
  ) {
    self.id = id
    self.type = type
    self.status = status
    self.role = role
    self.content = content
    self.summary = summary
    self.encryptedContent = encryptedContent
    self.callID = callID
    self.name = name
    self.arguments = arguments
    self.namespace = namespace
    self.format = format
    self.signature = signature
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id)
    type = try container.decode(String.self, forKey: .type)
    status = try container.decodeIfPresent(String.self, forKey: .status)
    role = try container.decodeIfPresent(String.self, forKey: .role)
    content = try container.decodeIfPresent([ResponsesOutputContent].self, forKey: .content)
    summary = try container.decodeIfPresent([ResponsesReasoningSummary].self, forKey: .summary)
    encryptedContent = try container.decodeIfPresent(String.self, forKey: .encryptedContent)
    callID = try container.decodeIfPresent(String.self, forKey: .callID)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    arguments = try container.decodeIfPresent(String.self, forKey: .arguments)
    namespace = try container.decodeIfPresent(String.self, forKey: .namespace)
    format = try container.decodeIfPresent(String.self, forKey: .format)
    signature = try container.decodeIfPresent(String.self, forKey: .signature)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(id, forKey: .id)
    try container.encode(type, forKey: .type)
    try container.encodeIfPresent(status, forKey: .status)
    try container.encodeIfPresent(role, forKey: .role)
    try container.encodeIfPresent(content, forKey: .content)
    try container.encodeIfPresent(summary, forKey: .summary)
    try container.encodeIfPresent(encryptedContent, forKey: .encryptedContent)
    try container.encodeIfPresent(callID, forKey: .callID)
    try container.encodeIfPresent(name, forKey: .name)
    try container.encodeIfPresent(arguments, forKey: .arguments)
    try container.encodeIfPresent(namespace, forKey: .namespace)
    try container.encodeIfPresent(format, forKey: .format)
    try container.encodeIfPresent(signature, forKey: .signature)
  }

  public var functionCall: ResponsesFunctionCall? {
    guard type == "function_call", let callID, let name, let arguments else { return nil }
    return ResponsesFunctionCall(
      id: id, callID: callID, name: name, arguments: arguments, status: status, namespace: namespace
    )
  }

  public var reasoningItem: ResponsesReasoningItem? {
    guard type == "reasoning", let id else { return nil }
    return ResponsesReasoningItem(
      id: id, summary: summary ?? [], encryptedContent: encryptedContent, content: content,
      status: status, format: format, signature: signature)
  }
}

public struct ResponsesOutputContent: Codable, Sendable, Equatable {
  public var type: String
  public var text: String?
  public var annotations: [Annotation]?

  public init(type: String, text: String? = nil, annotations: [Annotation]? = nil) {
    self.type = type
    self.text = text
    self.annotations = annotations
  }
}

public struct ResponsesReasoningSummary: Codable, Sendable, Equatable {
  public var type: String?
  public var text: String?
  private var encodingStyle: EncodingStyle

  private enum EncodingStyle: Equatable {
    case object
    case string
  }

  public init(type: String? = nil, text: String? = nil) {
    self.type = type
    self.text = text
    encodingStyle = .object
  }

  public init(from decoder: Decoder) throws {
    let single = try decoder.singleValueContainer()
    if let text = try? single.decode(String.self) {
      self.type = nil
      self.text = text
      encodingStyle = .string
      return
    }

    let container = try decoder.container(keyedBy: CodingKeys.self)
    type = try container.decodeIfPresent(String.self, forKey: .type)
    text = try container.decodeIfPresent(String.self, forKey: .text)
    encodingStyle = .object
  }

  public func encode(to encoder: Encoder) throws {
    switch encodingStyle {
    case .string where type == nil:
      var single = encoder.singleValueContainer()
      try single.encode(text ?? "")
    case .string, .object:
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encodeIfPresent(type, forKey: .type)
      try container.encodeIfPresent(text, forKey: .text)
    }
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.type == rhs.type && lhs.text == rhs.text
  }

  private enum CodingKeys: String, CodingKey { case type, text }
}

public struct ResponsesUsage: Codable, Sendable, Equatable {
  public var inputTokens: Int?
  public var outputTokens: Int?
  public var totalTokens: Int?
  public var inputTokensDetails: ResponsesInputTokenDetails?
  public var outputTokensDetails: ResponsesOutputTokenDetails?

  enum CodingKeys: String, CodingKey {
    case inputTokens = "input_tokens"
    case outputTokens = "output_tokens"
    case totalTokens = "total_tokens"
    case inputTokensDetails = "input_tokens_details"
    case outputTokensDetails = "output_tokens_details"
  }

  public init(
    inputTokens: Int? = nil,
    outputTokens: Int? = nil,
    totalTokens: Int? = nil,
    inputTokensDetails: ResponsesInputTokenDetails? = nil,
    outputTokensDetails: ResponsesOutputTokenDetails? = nil
  ) {
    self.inputTokens = inputTokens
    self.outputTokens = outputTokens
    self.totalTokens = totalTokens
    self.inputTokensDetails = inputTokensDetails
    self.outputTokensDetails = outputTokensDetails
  }
}

public struct ResponsesInputTokenDetails: Codable, Sendable, Equatable {
  public var cachedTokens: Int?

  enum CodingKeys: String, CodingKey {
    case cachedTokens = "cached_tokens"
  }

  public init(cachedTokens: Int? = nil) {
    self.cachedTokens = cachedTokens
  }
}

public struct ResponsesOutputTokenDetails: Codable, Sendable, Equatable {
  public var reasoningTokens: Int?

  enum CodingKeys: String, CodingKey {
    case reasoningTokens = "reasoning_tokens"
  }

  public init(reasoningTokens: Int? = nil) {
    self.reasoningTokens = reasoningTokens
  }
}
