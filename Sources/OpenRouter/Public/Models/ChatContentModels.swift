import Foundation

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
  case null
  case text(String)
  case parts([ContentPart])

  public init(from decoder: Decoder) throws {
    let single = try decoder.singleValueContainer()
    if single.decodeNil() {
      self = .null
      return
    }
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
      .init(
        codingPath: decoder.codingPath, debugDescription: "Expected null, string or array content")
    )
  }

  public func encode(to encoder: Encoder) throws {
    var single = encoder.singleValueContainer()
    switch self {
    case .null:
      try single.encodeNil()
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
