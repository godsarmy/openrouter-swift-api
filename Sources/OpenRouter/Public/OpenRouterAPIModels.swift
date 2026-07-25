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

public struct AudioSpeechRequest: Codable, Sendable, Equatable {
  public var model: String
  public var input: String
  public var voice: String
  public var responseFormat: AudioSpeechResponseFormat?
  public var speed: Double?
  /// Provider-specific passthrough options, preserved without imposing chat routing semantics.
  public var provider: JSONValue?

  enum CodingKeys: String, CodingKey {
    case model
    case input
    case voice
    case responseFormat = "response_format"
    case speed
    case provider
  }

  public init(
    model: String,
    input: String,
    voice: String,
    responseFormat: AudioSpeechResponseFormat? = nil,
    speed: Double? = nil,
    provider: JSONValue? = nil
  ) {
    self.model = model
    self.input = input
    self.voice = voice
    self.responseFormat = responseFormat
    self.speed = speed
    self.provider = provider
  }
}

public enum AudioSpeechResponseFormat: String, Codable, Sendable, Equatable {
  case mp3
  case pcm
}

public struct AudioTranscriptionFile: Sendable, Equatable {
  public var data: Data
  public var filename: String
  public var mediaType: String?

  public init(data: Data, filename: String, mediaType: String? = nil) {
    self.data = data
    self.filename = filename
    self.mediaType = mediaType
  }
}

public enum AudioTranscriptionResponseFormat: String, Sendable, Equatable {
  case json
  case verboseJSON = "verbose_json"
}

public enum AudioTranscriptionTimestampGranularity: String, Sendable, Equatable {
  case segment
  case word
}

public struct AudioTranscriptionRequest: Sendable, Equatable {
  public var file: AudioTranscriptionFile
  public var model: String
  public var language: String?
  public var temperature: Double?
  public var responseFormat: AudioTranscriptionResponseFormat?
  public var timestampGranularities: [AudioTranscriptionTimestampGranularity]?
  public var prompt: String?

  public init(
    file: AudioTranscriptionFile,
    model: String,
    language: String? = nil,
    temperature: Double? = nil,
    responseFormat: AudioTranscriptionResponseFormat? = nil,
    timestampGranularities: [AudioTranscriptionTimestampGranularity]? = nil,
    prompt: String? = nil
  ) {
    self.file = file
    self.model = model
    self.language = language
    self.temperature = temperature
    self.responseFormat = responseFormat
    self.timestampGranularities = timestampGranularities
    self.prompt = prompt
  }
}

public struct AudioTranscriptionResponse: Codable, Sendable, Equatable {
  public var text: String
  public var usage: Usage?
  public var rawPayload: JSONValue

  private enum CodingKeys: String, CodingKey { case text, usage }

  public init(text: String, usage: Usage? = nil, rawPayload: JSONValue? = nil) {
    self.text = text
    self.usage = usage
    self.rawPayload = rawPayload ?? .object(["text": .string(text)])
  }

  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    text = try container.decode(String.self, forKey: .text)
    usage = try container.decodeIfPresent(Usage.self, forKey: .usage)
  }

  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }

  public struct Usage: Codable, Sendable, Equatable {
    public var seconds: Double?
    public var totalTokens: Int?
    public var inputTokens: Int?
    public var outputTokens: Int?
    public var cost: Double?

    enum CodingKeys: String, CodingKey {
      case seconds
      case totalTokens = "total_tokens"
      case inputTokens = "input_tokens"
      case outputTokens = "output_tokens"
      case cost
    }

    public init(
      seconds: Double? = nil, totalTokens: Int? = nil, inputTokens: Int? = nil,
      outputTokens: Int? = nil, cost: Double? = nil
    ) {
      self.seconds = seconds
      self.totalTokens = totalTokens
      self.inputTokens = inputTokens
      self.outputTokens = outputTokens
      self.cost = cost
    }
  }
}

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

/// A paginated list of embedding-capable models.
public struct EmbeddingsModelsResponse: Codable, Sendable, Equatable {
  public var data: [OpenRouterModel]
  public var links: Links
  public var totalCount: Int

  enum CodingKeys: String, CodingKey {
    case data
    case links
    case totalCount = "total_count"
  }

  public init(data: [OpenRouterModel], links: Links, totalCount: Int) {
    self.data = data
    self.links = links
    self.totalCount = totalCount
  }

  public struct Links: Codable, Sendable, Equatable {
    public var next: String?

    public init(next: String? = nil) {
      self.next = next
    }
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
    case type, text, source, id, name, input, toolUseID = "tool_use_id", content, thinking,
      signature, data, isError = "is_error"
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

public struct RerankRequest: Codable, Sendable, Equatable {
  public var model: String
  public var query: String
  public var documents: [RerankDocument]
  public var topN: Int?
  public var provider: ProviderPreferences?
  enum CodingKeys: String, CodingKey {
    case model, query, documents
    case topN = "top_n"
    case provider
  }
  public init(
    model: String, query: String, documents: [RerankDocument], topN: Int? = nil,
    provider: ProviderPreferences? = nil
  ) {
    self.model = model
    self.query = query
    self.documents = documents
    self.topN = topN
    self.provider = provider
  }
}

public enum RerankDocument: Codable, Sendable, Equatable {
  case text(String)
  case object(RerankDocumentObject)
  public init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if let text = try? c.decode(String.self) {
      self = .text(text)
    } else {
      self = .object(try c.decode(RerankDocumentObject.self))
    }
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .text(let value): try c.encode(value)
    case .object(let value): try c.encode(value)
    }
  }
}
public struct RerankDocumentObject: Codable, Sendable, Equatable {
  public var text: String?
  public var image: String?
  public var rawPayload: JSONValue?
  public init(text: String? = nil, image: String? = nil) {
    self.text = text
    self.image = image
    rawPayload = nil
  }
  enum CodingKeys: String, CodingKey { case text, image }
  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    text = try c.decodeIfPresent(String.self, forKey: .text)
    image = try c.decodeIfPresent(String.self, forKey: .image)
  }
  public func encode(to encoder: Encoder) throws {
    if let rawPayload {
      try rawPayload.encode(to: encoder)
    } else {
      var c = encoder.container(keyedBy: CodingKeys.self)
      try c.encodeIfPresent(text, forKey: .text)
      try c.encodeIfPresent(image, forKey: .image)
    }
  }
}
public struct RerankResponse: Codable, Sendable, Equatable {
  public var model: String?
  public var results: [RerankResult]
  public var id: String?
  public var provider: JSONValue?
  public var usage: RerankUsage?
  public var rawPayload: JSONValue
  enum CodingKeys: String, CodingKey { case model, results, id, provider, usage }
  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    model = try c.decodeIfPresent(String.self, forKey: .model)
    results = try c.decode([RerankResult].self, forKey: .results)
    id = try c.decodeIfPresent(String.self, forKey: .id)
    provider = try c.decodeIfPresent(JSONValue.self, forKey: .provider)
    usage = try c.decodeIfPresent(RerankUsage.self, forKey: .usage)
  }
  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}
public struct RerankResult: Codable, Sendable, Equatable {
  public var index: Int
  public var relevanceScore: Double
  public var document: RerankDocumentObject
  public var rawPayload: JSONValue
  enum CodingKeys: String, CodingKey {
    case index, document
    case relevanceScore = "relevance_score"
  }
  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    index = try c.decode(Int.self, forKey: .index)
    relevanceScore = try c.decode(Double.self, forKey: .relevanceScore)
    document = try c.decode(RerankDocumentObject.self, forKey: .document)
  }
  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}
public struct RerankUsage: Codable, Sendable, Equatable {
  public var cost: Double?
  public var searchUnits: Int?
  public var totalTokens: Int?
  public var rawPayload: JSONValue
  enum CodingKeys: String, CodingKey {
    case cost
    case searchUnits = "search_units"
    case totalTokens = "total_tokens"
  }
  public init(from decoder: Decoder) throws {
    rawPayload = try JSONValue(from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    cost = try c.decodeIfPresent(Double.self, forKey: .cost)
    searchUnits = try c.decodeIfPresent(Int.self, forKey: .searchUnits)
    totalTokens = try c.decodeIfPresent(Int.self, forKey: .totalTokens)
  }
  public func encode(to encoder: Encoder) throws { try rawPayload.encode(to: encoder) }
}
