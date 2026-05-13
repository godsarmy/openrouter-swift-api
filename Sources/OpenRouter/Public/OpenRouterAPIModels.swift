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
  public var annotations: [Annotation]?
  public var images: [GeneratedImage]?
  public var audio: OutputAudio?

  enum CodingKeys: String, CodingKey {
    case role
    case content
    case name
    case toolCalls = "tool_calls"
    case toolCallID = "tool_call_id"
    case annotations
    case images
    case audio
  }

  public init(
    role: Role,
    content: Content,
    name: String? = nil,
    toolCalls: [ToolCall]? = nil,
    toolCallID: String? = nil,
    annotations: [Annotation]? = nil,
    images: [GeneratedImage]? = nil,
    audio: OutputAudio? = nil
  ) {
    self.role = role
    self.content = content
    self.name = name
    self.toolCalls = toolCalls
    self.toolCallID = toolCallID
    self.annotations = annotations
    self.images = images
    self.audio = audio
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
  case textWithCache(text: String, cacheControl: CacheControl)
  case imageURL(String)
  case image(ImageURLContent)
  case fileURL(String)
  case file(FileContent)
  case inputAudio(InputAudio)
  case unknown(type: String, payload: JSONValue)

  private enum CodingKeys: String, CodingKey {
    case type
    case text
    case cacheControl = "cache_control"
    case imageURL = "image_url"
    case file
    case fileURL = "file_url"
    case inputAudio = "input_audio"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)
    switch type {
    case "text":
      let text = try container.decode(String.self, forKey: .text)
      if let cacheControl = try container.decodeIfPresent(CacheControl.self, forKey: .cacheControl)
      {
        self = .textWithCache(text: text, cacheControl: cacheControl)
      } else {
        self = .text(text)
      }
    case "image_url":
      if let image = try? container.decode(ImageURLContent.self, forKey: .imageURL) {
        self = .image(image)
      } else {
        self = .imageURL(try container.decode(String.self, forKey: .imageURL))
      }
    case "file":
      self = .file(try container.decode(FileContent.self, forKey: .file))
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
    case .textWithCache(let text, let cacheControl):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode("text", forKey: .type)
      try container.encode(text, forKey: .text)
      try container.encode(cacheControl, forKey: .cacheControl)
    case .imageURL(let url):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode("image_url", forKey: .type)
      try container.encode(url, forKey: .imageURL)
    case .image(let image):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode("image_url", forKey: .type)
      try container.encode(image, forKey: .imageURL)
    case .fileURL(let url):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode("file_url", forKey: .type)
      try container.encode(url, forKey: .fileURL)
    case .file(let file):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode("file", forKey: .type)
      try container.encode(file, forKey: .file)
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

public struct ImageURLContent: Codable, Sendable, Equatable {
  public var url: String
  public var detail: String?

  public init(url: String, detail: String? = nil) {
    self.url = url
    self.detail = detail
  }
}

public struct FileContent: Codable, Sendable, Equatable {
  public var filename: String
  public var fileData: String

  enum CodingKeys: String, CodingKey {
    case filename
    case fileData = "file_data"
  }

  public init(filename: String, fileData: String) {
    self.filename = filename
    self.fileData = fileData
  }
}

public struct Annotation: Codable, Sendable, Equatable {
  public var type: String
  public var urlCitation: URLCitation?

  enum CodingKeys: String, CodingKey {
    case type
    case urlCitation = "url_citation"
  }

  public init(type: String, urlCitation: URLCitation? = nil) {
    self.type = type
    self.urlCitation = urlCitation
  }
}

public struct URLCitation: Codable, Sendable, Equatable {
  public var startIndex: Int?
  public var endIndex: Int?
  public var title: String?
  public var content: String?
  public var url: String?

  enum CodingKeys: String, CodingKey {
    case startIndex = "start_index"
    case endIndex = "end_index"
    case title
    case content
    case url
  }

  public init(
    startIndex: Int? = nil,
    endIndex: Int? = nil,
    title: String? = nil,
    content: String? = nil,
    url: String? = nil
  ) {
    self.startIndex = startIndex
    self.endIndex = endIndex
    self.title = title
    self.content = content
    self.url = url
  }
}

public struct GeneratedImage: Codable, Sendable, Equatable {
  public var index: Int?
  public var type: String?
  public var imageURL: ImageURLContent?

  enum CodingKeys: String, CodingKey {
    case index
    case type
    case imageURL = "image_url"
  }

  public init(index: Int? = nil, type: String? = nil, imageURL: ImageURLContent? = nil) {
    self.index = index
    self.type = type
    self.imageURL = imageURL
  }
}

public struct OutputAudio: Codable, Sendable, Equatable {
  public var data: String?
  public var transcript: String?

  public init(data: String? = nil, transcript: String? = nil) {
    self.data = data
    self.transcript = transcript
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
  public var responseCache: ResponseCacheConfig?

  enum CodingKeys: String, CodingKey {
    case model
    case input
  }

  public init(model: String, input: EmbeddingInput, responseCache: ResponseCacheConfig? = nil) {
    self.model = model
    self.input = input
    self.responseCache = responseCache
  }
}

public struct EmbeddingResponse: Codable, Sendable, Equatable {
  public var model: String?
  public var data: [EmbeddingData]
  public var usage: Usage?
  public var responseCache: ResponseCacheMetadata?

  enum CodingKeys: String, CodingKey {
    case model
    case data
    case usage
  }

  public init(
    model: String? = nil,
    data: [EmbeddingData],
    usage: Usage? = nil,
    responseCache: ResponseCacheMetadata? = nil
  ) {
    self.model = model
    self.data = data
    self.usage = usage
    self.responseCache = responseCache
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
  public var responseCache: ResponseCacheConfig?

  enum CodingKeys: String, CodingKey {
    case model
    case prompt
    case maxTokens = "max_tokens"
  }

  public init(
    model: String,
    prompt: String,
    maxTokens: Int? = nil,
    responseCache: ResponseCacheConfig? = nil
  ) {
    self.model = model
    self.prompt = prompt
    self.maxTokens = maxTokens
    self.responseCache = responseCache
  }
}

public struct CompletionResponse: Codable, Sendable, Equatable {
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
  public var promptTokensDetails: PromptTokenDetails?
  public var completionTokensDetails: CompletionTokenDetails?
  public var cost: Double?
  public var costDetails: UsageCostDetails?
  public var isByok: Bool?

  enum CodingKeys: String, CodingKey {
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case totalTokens = "total_tokens"
    case promptTokensDetails = "prompt_tokens_details"
    case completionTokensDetails = "completion_tokens_details"
    case cost
    case costDetails = "cost_details"
    case isByok = "is_byok"
  }

  public init(
    promptTokens: Int? = nil,
    completionTokens: Int? = nil,
    totalTokens: Int? = nil,
    promptTokensDetails: PromptTokenDetails? = nil,
    completionTokensDetails: CompletionTokenDetails? = nil,
    cost: Double? = nil,
    costDetails: UsageCostDetails? = nil,
    isByok: Bool? = nil
  ) {
    self.promptTokens = promptTokens
    self.completionTokens = completionTokens
    self.totalTokens = totalTokens
    self.promptTokensDetails = promptTokensDetails
    self.completionTokensDetails = completionTokensDetails
    self.cost = cost
    self.costDetails = costDetails
    self.isByok = isByok
  }
}

public struct UsageCostDetails: Codable, Sendable, Equatable {
  public var upstreamInferenceCost: Double?

  enum CodingKeys: String, CodingKey {
    case upstreamInferenceCost = "upstream_inference_cost"
  }

  public init(upstreamInferenceCost: Double? = nil) {
    self.upstreamInferenceCost = upstreamInferenceCost
  }
}

public struct ChatCompletionReasoning: Codable, Sendable, Equatable {
  public var effort: String?
  public var maxTokens: Int?
  public var exclude: Bool?
  public var enabled: Bool?

  enum CodingKeys: String, CodingKey {
    case effort
    case maxTokens = "max_tokens"
    case exclude
    case enabled
  }

  public init(
    effort: String? = nil, maxTokens: Int? = nil, exclude: Bool? = nil, enabled: Bool? = nil
  ) {
    self.effort = effort
    self.maxTokens = maxTokens
    self.exclude = exclude
    self.enabled = enabled
  }
}

public struct WebSearchOptions: Codable, Sendable, Equatable {
  public var searchContextSize: String

  enum CodingKeys: String, CodingKey {
    case searchContextSize = "search_context_size"
  }

  public init(searchContextSize: String) {
    self.searchContextSize = searchContextSize
  }
}

public struct CacheControl: Codable, Sendable, Equatable {
  public var type: String
  public var ttl: String?

  public init(type: String = "ephemeral", ttl: String? = nil) {
    self.type = type
    self.ttl = ttl
  }
}

public struct ResponseCacheConfig: Sendable, Equatable {
  public var enabled: Bool?
  public var ttlSeconds: Int?
  public var clear: Bool?

  public init(enabled: Bool? = nil, ttlSeconds: Int? = nil, clear: Bool? = nil) {
    self.enabled = enabled
    self.ttlSeconds = ttlSeconds
    self.clear = clear
  }
}

public struct ResponseCacheMetadata: Codable, Sendable, Equatable {
  public var status: String?
  public var ageSeconds: Int?
  public var ttlSeconds: Int?
  public var generationID: String?

  public init(
    status: String? = nil, ageSeconds: Int? = nil, ttlSeconds: Int? = nil,
    generationID: String? = nil
  ) {
    self.status = status
    self.ageSeconds = ageSeconds
    self.ttlSeconds = ttlSeconds
    self.generationID = generationID
  }
}

public struct TokenDetails: Codable, Sendable, Equatable {
  public var cachedTokens: Int?
  public var audioTokens: Int?
  public var cacheWriteTokens: Int?
  public var videoTokens: Int?
  public var acceptedPredictionTokens: Int?
  public var reasoningTokens: Int?
  public var rejectedPredictionTokens: Int?

  enum CodingKeys: String, CodingKey {
    case cachedTokens = "cached_tokens"
    case audioTokens = "audio_tokens"
    case cacheWriteTokens = "cache_write_tokens"
    case videoTokens = "video_tokens"
    case acceptedPredictionTokens = "accepted_prediction_tokens"
    case reasoningTokens = "reasoning_tokens"
    case rejectedPredictionTokens = "rejected_prediction_tokens"
  }

  public init(
    cachedTokens: Int? = nil,
    audioTokens: Int? = nil,
    cacheWriteTokens: Int? = nil,
    videoTokens: Int? = nil,
    acceptedPredictionTokens: Int? = nil,
    reasoningTokens: Int? = nil,
    rejectedPredictionTokens: Int? = nil
  ) {
    self.cachedTokens = cachedTokens
    self.audioTokens = audioTokens
    self.cacheWriteTokens = cacheWriteTokens
    self.videoTokens = videoTokens
    self.acceptedPredictionTokens = acceptedPredictionTokens
    self.reasoningTokens = reasoningTokens
    self.rejectedPredictionTokens = rejectedPredictionTokens
  }
}

public typealias PromptTokenDetails = TokenDetails
public typealias CompletionTokenDetails = TokenDetails

public struct ProviderPreferences: Codable, Sendable, Equatable {
  public var allowFallbacks: Bool?
  public var order: [String]?
  public var only: [String]?
  public var ignore: [String]?
  public var requireParameters: Bool?
  public var sort: String?
  public var zdr: Bool?

  enum CodingKeys: String, CodingKey {
    case allowFallbacks = "allow_fallbacks"
    case order
    case only
    case ignore
    case requireParameters = "require_parameters"
    case sort
    case zdr
  }

  public init(
    allowFallbacks: Bool? = nil,
    order: [String]? = nil,
    only: [String]? = nil,
    ignore: [String]? = nil,
    requireParameters: Bool? = nil,
    sort: String? = nil,
    zdr: Bool? = nil
  ) {
    self.allowFallbacks = allowFallbacks
    self.order = order
    self.only = only
    self.ignore = ignore
    self.requireParameters = requireParameters
    self.sort = sort
    self.zdr = zdr
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

public struct ReasoningDetail: Codable, Sendable, Equatable {
  public var id: String?
  public var index: Int?
  public var type: String?
  public var text: String?
  public var summary: String?
  public var data: String?
  public var format: String?

  public init(
    id: String? = nil,
    index: Int? = nil,
    type: String? = nil,
    text: String? = nil,
    summary: String? = nil,
    data: String? = nil,
    format: String? = nil
  ) {
    self.id = id
    self.index = index
    self.type = type
    self.text = text
    self.summary = summary
    self.data = data
    self.format = format
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

public struct GenerationResponse: Codable, Sendable, Equatable {
  public var data: Generation?

  public init(data: Generation? = nil) {
    self.data = data
  }
}

public struct Generation: Codable, Sendable, Equatable {
  public var id: String?
  public var model: String?
  public var providerName: String?
  public var createdAt: String?
  public var updatedAt: String?
  public var status: String?
  public var totalCost: Double?
  public var usage: Usage?
  public var nativeFinishReason: String?
  public var finishReason: String?
  public var tokensPrompt: Int?
  public var tokensCompletion: Int?
  public var metadata: JSONValue?

  enum CodingKeys: String, CodingKey {
    case id
    case model
    case providerName = "provider_name"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case status
    case totalCost = "total_cost"
    case usage
    case nativeFinishReason = "native_finish_reason"
    case finishReason = "finish_reason"
    case tokensPrompt = "tokens_prompt"
    case tokensCompletion = "tokens_completion"
    case metadata
  }
}

public struct GenerationContentResponse: Codable, Sendable, Equatable {
  public var data: GenerationContent?

  public init(data: GenerationContent? = nil) {
    self.data = data
  }
}

public struct GenerationContent: Codable, Sendable, Equatable {
  public var id: String?
  public var input: JSONValue?
  public var output: JSONValue?
  public var prompt: JSONValue?
  public var completion: JSONValue?
  public var messages: JSONValue?
  public var rawContent: JSONValue?

  enum CodingKeys: String, CodingKey {
    case id
    case input
    case output
    case prompt
    case completion
    case messages
    case rawContent = "raw_content"
  }
}

public struct ModelsResponse: Codable, Sendable, Equatable {
  public var data: [OpenRouterModel]

  public init(data: [OpenRouterModel]) {
    self.data = data
  }
}

public struct OpenRouterModel: Codable, Sendable, Equatable {
  public var id: String
  public var name: String?
  public var description: String?
  public var contextLength: Int?
  public var architecture: JSONValue?
  public var pricing: ModelPricing?
  public var topProvider: JSONValue?
  public var perRequestLimits: JSONValue?
  public var supportedParameters: [String]?

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case description
    case contextLength = "context_length"
    case architecture
    case pricing
    case topProvider = "top_provider"
    case perRequestLimits = "per_request_limits"
    case supportedParameters = "supported_parameters"
  }
}

public struct ModelPricing: Codable, Sendable, Equatable {
  public var prompt: String?
  public var completion: String?
  public var image: String?
  public var request: String?
  public var inputCacheRead: String?
  public var inputCacheWrite: String?
  public var webSearch: String?
  public var internalReasoning: String?

  enum CodingKeys: String, CodingKey {
    case prompt
    case completion
    case image
    case request
    case inputCacheRead = "input_cache_read"
    case inputCacheWrite = "input_cache_write"
    case webSearch = "web_search"
    case internalReasoning = "internal_reasoning"
  }
}

public struct CreditsResponse: Codable, Sendable, Equatable {
  public var data: Credits?
  public var totalCredits: Double?
  public var totalUsage: Double?

  enum CodingKeys: String, CodingKey {
    case data
    case totalCredits = "total_credits"
    case totalUsage = "total_usage"
  }

  public init(data: Credits? = nil, totalCredits: Double? = nil, totalUsage: Double? = nil) {
    self.data = data
    self.totalCredits = totalCredits
    self.totalUsage = totalUsage
  }
}

public struct Credits: Codable, Sendable, Equatable {
  public var totalCredits: Double?
  public var totalUsage: Double?

  enum CodingKeys: String, CodingKey {
    case totalCredits = "total_credits"
    case totalUsage = "total_usage"
  }

  public init(totalCredits: Double? = nil, totalUsage: Double? = nil) {
    self.totalCredits = totalCredits
    self.totalUsage = totalUsage
  }
}

public struct ProvidersResponse: Codable, Sendable, Equatable {
  public var data: [OpenRouterProvider]

  public init(data: [OpenRouterProvider]) {
    self.data = data
  }
}

public struct OpenRouterProvider: Codable, Sendable, Equatable {
  public var name: String
  public var slug: String
  public var privacyPolicyURL: String?
  public var statusPageURL: String?
  public var termsOfServiceURL: String?
  public var datacenters: JSONValue?
  public var headquarters: JSONValue?

  enum CodingKeys: String, CodingKey {
    case name
    case slug
    case privacyPolicyURL = "privacy_policy_url"
    case statusPageURL = "status_page_url"
    case termsOfServiceURL = "terms_of_service_url"
    case datacenters
    case headquarters
  }

  public init(
    name: String,
    slug: String,
    privacyPolicyURL: String? = nil,
    statusPageURL: String? = nil,
    termsOfServiceURL: String? = nil,
    datacenters: JSONValue? = nil,
    headquarters: JSONValue? = nil
  ) {
    self.name = name
    self.slug = slug
    self.privacyPolicyURL = privacyPolicyURL
    self.statusPageURL = statusPageURL
    self.termsOfServiceURL = termsOfServiceURL
    self.datacenters = datacenters
    self.headquarters = headquarters
  }
}

public struct ModelEndpointsResponse: Codable, Sendable, Equatable {
  public var data: ModelEndpoints

  public init(data: ModelEndpoints) {
    self.data = data
  }
}

public struct ZDREndpointsResponse: Codable, Sendable, Equatable {
  public var data: [PublicEndpoint]

  public init(data: [PublicEndpoint]) {
    self.data = data
  }
}

public struct ModelEndpoints: Codable, Sendable, Equatable {
  public var id: String?
  public var name: String?
  public var description: String?
  public var created: Int?
  public var architecture: JSONValue?
  public var endpoints: [PublicEndpoint]

  public init(
    id: String? = nil,
    name: String? = nil,
    description: String? = nil,
    created: Int? = nil,
    architecture: JSONValue? = nil,
    endpoints: [PublicEndpoint] = []
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.created = created
    self.architecture = architecture
    self.endpoints = endpoints
  }
}

public struct PublicEndpoint: Codable, Sendable, Equatable {
  public var name: String?
  public var providerName: String?
  public var contextLength: Int?
  public var maxCompletionTokens: Int?
  public var pricing: ModelPricing?
  public var supportedParameters: [String]?
  public var extra: JSONValue?

  enum CodingKeys: String, CodingKey {
    case name
    case providerName = "provider_name"
    case contextLength = "context_length"
    case maxCompletionTokens = "max_completion_tokens"
    case pricing
    case supportedParameters = "supported_parameters"
    case extra
  }

  public init(
    name: String? = nil,
    providerName: String? = nil,
    contextLength: Int? = nil,
    maxCompletionTokens: Int? = nil,
    pricing: ModelPricing? = nil,
    supportedParameters: [String]? = nil,
    extra: JSONValue? = nil
  ) {
    self.name = name
    self.providerName = providerName
    self.contextLength = contextLength
    self.maxCompletionTokens = maxCompletionTokens
    self.pricing = pricing
    self.supportedParameters = supportedParameters
    self.extra = extra
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
