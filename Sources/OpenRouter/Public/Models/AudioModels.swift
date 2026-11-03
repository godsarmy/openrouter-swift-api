import Foundation

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
