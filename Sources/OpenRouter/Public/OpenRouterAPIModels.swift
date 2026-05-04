import Foundation

public struct ChatCompletionRequest: Codable, Sendable, Equatable {
  public var model: String
  public var messages: [ChatMessage]

  public init(model: String, messages: [ChatMessage]) {
    self.model = model
    self.messages = messages
  }
}

public struct ChatCompletionResponse: Codable, Sendable, Equatable {
  public init() {}
}

public struct ChatCompletionChunk: Codable, Sendable, Equatable {
  public init() {}
}

public struct ChatMessage: Codable, Sendable, Equatable {
  public enum Role: String, Codable, Sendable {
    case system
    case user
    case assistant
    case tool
  }

  public var role: Role
  public var content: String

  public init(role: Role, content: String) {
    self.role = role
    self.content = content
  }
}

public struct EmbeddingRequest: Codable, Sendable, Equatable {
  public var model: String
  public var input: [String]

  public init(model: String, input: [String]) {
    self.model = model
    self.input = input
  }
}

public struct EmbeddingResponse: Codable, Sendable, Equatable {
  public init() {}
}

public struct CompletionRequest: Codable, Sendable, Equatable {
  public var model: String
  public var prompt: String

  public init(model: String, prompt: String) {
    self.model = model
    self.prompt = prompt
  }
}

public struct CompletionResponse: Codable, Sendable, Equatable {
  public init() {}
}
