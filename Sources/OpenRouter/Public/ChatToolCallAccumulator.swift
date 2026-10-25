import Foundation

public struct ToolCallDelta: Codable, Sendable, Equatable {
  public var index: Int?
  public var id: String?
  public var type: String?
  public var function: ToolFunctionCallDelta?

  public init(
    index: Int? = nil, id: String? = nil, type: String? = nil,
    function: ToolFunctionCallDelta? = nil
  ) {
    self.index = index
    self.id = id
    self.type = type
    self.function = function
  }
}

public struct ToolFunctionCallDelta: Codable, Sendable, Equatable {
  public var name: String?
  public var arguments: String?

  public init(name: String? = nil, arguments: String? = nil) {
    self.name = name
    self.arguments = arguments
  }
}

public enum ChatToolCallAccumulatorError: Error, Sendable, Equatable {
  case invalidState
  case streamError(ChatStreamError)
  case invalidChoiceIndex
  case invalidToolIndex(choice: Int)
  case conflictingMetadata(choice: Int, tool: Int, field: String)
  case unsupportedToolType(choice: Int, tool: Int)
  case missingMetadata(choice: Int, tool: Int, field: String)
  case invalidArguments(choice: Int, tool: Int)
  case incompleteChoice(choice: Int)
  case emptyToolCalls(choice: Int)
  case choiceAlreadyFinished(choice: Int)
}

/// Manually collects tool calls without executing tools or exposing partial results.
/// Call `finish()` only after normal stream exhaustion, never after transport failure or cancellation.
/// This collector cannot prove receipt of `[DONE]`; each tool choice's finish reason is its gate.
/// Any failure poisons the collector. Successful finalization also prevents further use.
public struct ChatToolCallAccumulator: Sendable {
  private struct Tool: Sendable {
    var id: String?
    var type: String?
    var name: String?
    var arguments = ""
  }

  private struct Choice: Sendable {
    var tools: [Int: Tool] = [:]
    var finishReason: String?
  }

  private var choices: [Int: Choice] = [:]
  private var closed = false

  public init() {}

  public mutating func append(_ chunk: ChatCompletionChunk) throws {
    guard !closed else { throw ChatToolCallAccumulatorError.invalidState }
    do {
      if let error = chunk.error { throw ChatToolCallAccumulatorError.streamError(error) }
      for incoming in chunk.choices {
        let deltas = incoming.delta?.toolCalls ?? []
        let relevant = !deltas.isEmpty || incoming.finishReason == "tool_calls"
        guard let index = incoming.index, index >= 0 else {
          if relevant { throw ChatToolCallAccumulatorError.invalidChoiceIndex }
          continue
        }
        var choice = choices[index] ?? Choice()
        if choice.finishReason != nil && (!deltas.isEmpty || incoming.finishReason != nil) {
          throw ChatToolCallAccumulatorError.choiceAlreadyFinished(choice: index)
        }
        for delta in deltas {
          guard let toolIndex = delta.index, toolIndex >= 0 else {
            throw ChatToolCallAccumulatorError.invalidToolIndex(choice: index)
          }
          var tool = choice.tools[toolIndex] ?? Tool()
          try Self.merge(delta.id, into: &tool.id, choice: index, tool: toolIndex, field: "id")
          try Self.merge(
            delta.type, into: &tool.type, choice: index, tool: toolIndex, field: "type")
          if let type = tool.type, type != "function" {
            throw ChatToolCallAccumulatorError.unsupportedToolType(choice: index, tool: toolIndex)
          }
          try Self.merge(
            delta.function?.name, into: &tool.name, choice: index, tool: toolIndex, field: "name")
          tool.arguments += delta.function?.arguments ?? ""
          choice.tools[toolIndex] = tool
        }
        if let reason = incoming.finishReason {
          if reason == "tool_calls" && choice.tools.isEmpty {
            throw ChatToolCallAccumulatorError.emptyToolCalls(choice: index)
          }
          if reason != "tool_calls" && !choice.tools.isEmpty {
            throw ChatToolCallAccumulatorError.incompleteChoice(choice: index)
          }
          choice.finishReason = reason
        }
        choices[index] = choice
      }
    } catch {
      closed = true
      choices.removeAll()
      throw error
    }
  }

  /// Returns complete calls in ascending tool-index order for each choice, then locks the collector.
  public mutating func finish() throws -> [Int: [ToolCall]] {
    guard !closed else { throw ChatToolCallAccumulatorError.invalidState }
    closed = true
    defer { choices.removeAll() }
    var result: [Int: [ToolCall]] = [:]
    for (index, choice) in choices where !choice.tools.isEmpty {
      guard choice.finishReason == "tool_calls" else {
        throw ChatToolCallAccumulatorError.incompleteChoice(choice: index)
      }
      result[index] = try choice.tools.keys.sorted().map { toolIndex in
        let tool = choice.tools[toolIndex]!
        guard let id = tool.id, !id.isEmpty else {
          throw ChatToolCallAccumulatorError.missingMetadata(
            choice: index, tool: toolIndex, field: "id")
        }
        guard let name = tool.name, !name.isEmpty else {
          throw ChatToolCallAccumulatorError.missingMetadata(
            choice: index, tool: toolIndex, field: "name")
        }
        guard
          let object = try? JSONSerialization.jsonObject(with: Data(tool.arguments.utf8)),
          object is [String: Any]
        else {
          throw ChatToolCallAccumulatorError.invalidArguments(choice: index, tool: toolIndex)
        }
        return ToolCall(
          id: id, type: tool.type ?? "function",
          function: ToolFunctionCall(name: name, arguments: tool.arguments))
      }
    }
    return result
  }

  private static func merge(
    _ value: String?, into stored: inout String?, choice: Int, tool: Int, field: String
  ) throws {
    guard let value else { return }
    if let stored, stored != value {
      throw ChatToolCallAccumulatorError.conflictingMetadata(
        choice: choice, tool: tool, field: field)
    }
    stored = value
  }
}
