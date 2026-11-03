import Foundation

public struct ChatCompletionRequest: Codable, Sendable, Equatable {
  public var model: String
  public var models: [String]?
  public var messages: [ChatMessage]
  public var stream: Bool?
  public var tools: [ChatTool]?
  public var toolChoice: ToolChoice?
  public var responseFormat: ChatResponseFormat?
  public var reasoning: ChatCompletionReasoning?
  public var webSearchOptions: WebSearchOptions?
  public var responseCache: ResponseCacheConfig?
  public var provider: ProviderPreferences?
  public var streamOptions: StreamOptions?
  public var serviceTier: String?
  public var sessionID: String?
  public var parallelToolCalls: Bool?

  enum CodingKeys: String, CodingKey {
    case model
    case models
    case messages
    case stream
    case tools
    case toolChoice = "tool_choice"
    case responseFormat = "response_format"
    case reasoning
    case webSearchOptions = "web_search_options"
    case provider
    case streamOptions = "stream_options"
    case serviceTier = "service_tier"
    case sessionID = "session_id"
    case parallelToolCalls = "parallel_tool_calls"
  }

  public init(
    model: String,
    models: [String]? = nil,
    messages: [ChatMessage],
    stream: Bool? = nil,
    tools: [ChatTool]? = nil,
    toolChoice: ToolChoice? = nil,
    responseFormat: ChatResponseFormat? = nil,
    reasoning: ChatCompletionReasoning? = nil,
    webSearchOptions: WebSearchOptions? = nil,
    responseCache: ResponseCacheConfig? = nil,
    provider: ProviderPreferences? = nil,
    streamOptions: StreamOptions? = nil,
    serviceTier: String? = nil,
    sessionID: String? = nil,
    parallelToolCalls: Bool? = nil
  ) {
    self.model = model
    self.models = models
    self.messages = messages
    self.stream = stream
    self.tools = tools
    self.toolChoice = toolChoice
    self.responseFormat = responseFormat
    self.reasoning = reasoning
    self.webSearchOptions = webSearchOptions
    self.responseCache = responseCache
    self.provider = provider
    self.streamOptions = streamOptions
    self.serviceTier = serviceTier
    self.sessionID = sessionID
    self.parallelToolCalls = parallelToolCalls
  }
}

public struct ChatCompletionResponse: Codable, Sendable, Equatable {
  public var id: String?
  public var model: String?
  public var choices: [Choice]
  public var usage: Usage?
  public var responseCache: ResponseCacheMetadata?

  enum CodingKeys: String, CodingKey {
    case id
    case model
    case choices
    case usage
  }

  public init(
    id: String? = nil,
    model: String? = nil,
    choices: [Choice],
    usage: Usage? = nil,
    responseCache: ResponseCacheMetadata? = nil
  ) {
    self.id = id
    self.model = model
    self.choices = choices
    self.usage = usage
    self.responseCache = responseCache
  }

  public struct Choice: Codable, Sendable, Equatable {
    public var index: Int?
    public var message: ChatMessage
    public var finishReason: String?
    public var reasoning: String?
    public var reasoningDetails: [ReasoningDetail]?

    enum CodingKeys: String, CodingKey {
      case index
      case message
      case finishReason = "finish_reason"
      case reasoning
      case reasoningDetails = "reasoning_details"
    }

    public init(
      index: Int? = nil,
      message: ChatMessage,
      finishReason: String? = nil,
      reasoning: String? = nil,
      reasoningDetails: [ReasoningDetail]? = nil
    ) {
      self.index = index
      self.message = message
      self.finishReason = finishReason
      self.reasoning = reasoning
      self.reasoningDetails = reasoningDetails
    }
  }
}

public struct ChatCompletionChunk: Codable, Sendable, Equatable {
  public var id: String?
  public var object: String?
  public var created: Int?
  public var model: String?
  public var choices: [Choice]
  public var usage: Usage?
  public var error: ChatStreamError?
  public var serviceTier: String?
  public var systemFingerprint: String?

  enum CodingKeys: String, CodingKey {
    case id
    case object
    case created
    case model
    case choices
    case usage
    case error
    case serviceTier = "service_tier"
    case systemFingerprint = "system_fingerprint"
  }

  public init(
    id: String? = nil,
    object: String? = nil,
    created: Int? = nil,
    model: String? = nil,
    choices: [Choice],
    usage: Usage? = nil,
    error: ChatStreamError? = nil,
    serviceTier: String? = nil,
    systemFingerprint: String? = nil
  ) {
    self.id = id
    self.object = object
    self.created = created
    self.model = model
    self.choices = choices
    self.usage = usage
    self.error = error
    self.serviceTier = serviceTier
    self.systemFingerprint = systemFingerprint
  }

  public struct Choice: Codable, Sendable, Equatable {
    public var index: Int?
    public var delta: Delta?
    public var finishReason: String?
    public var reasoning: String?
    public var reasoningDetails: [ReasoningDetail]?

    enum CodingKeys: String, CodingKey {
      case index
      case delta
      case finishReason = "finish_reason"
      case reasoning
      case reasoningDetails = "reasoning_details"
    }

    public init(
      index: Int? = nil,
      delta: Delta? = nil,
      finishReason: String? = nil,
      reasoning: String? = nil,
      reasoningDetails: [ReasoningDetail]? = nil
    ) {
      self.index = index
      self.delta = delta
      self.finishReason = finishReason
      self.reasoning = reasoning
      self.reasoningDetails = reasoningDetails
    }
  }

  public struct Delta: Codable, Sendable, Equatable {
    public var role: ChatMessage.Role?
    public var content: String?
    public var toolCalls: [ToolCallDelta]?

    enum CodingKeys: String, CodingKey {
      case role
      case content
      case toolCalls = "tool_calls"
    }

    public init(
      role: ChatMessage.Role? = nil,
      content: String? = nil,
      toolCalls: [ToolCallDelta]? = nil
    ) {
      self.role = role
      self.content = content
      self.toolCalls = toolCalls
    }
  }
}

public struct StreamOptions: Codable, Sendable, Equatable {
  public var includeUsage: Bool?

  enum CodingKeys: String, CodingKey {
    case includeUsage = "include_usage"
  }

  public init(includeUsage: Bool? = nil) {
    self.includeUsage = includeUsage
  }
}

public struct ChatStreamError: Codable, Sendable, Equatable {
  public var code: Int?
  public var message: String?

  public init(code: Int? = nil, message: String? = nil) {
    self.code = code
    self.message = message
  }
}
