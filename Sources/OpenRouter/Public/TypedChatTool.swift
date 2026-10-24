import Foundation

/// Errors validating a call's identity before decoding arguments or encoding a result.
public enum TypedChatToolError: Error, Sendable, Equatable {
  case unsupportedToolType(String)
  case functionNameMismatch(expected: String, actual: String)
  case missingToolCallID
}

/// A typed JSON boundary for a manually declared chat function tool.
///
/// This helper does not validate JSON Schema, generate schemas, execute a handler,
/// run a tool loop, or assemble streaming tool calls. Supply a complete call and
/// a schema appropriate for your argument type.
public struct TypedChatTool<Arguments: Decodable, Result: Encodable>: Sendable {
  /// The raw tool definition to include in a chat completion request.
  public let tool: ChatTool

  /// Creates a function tool using the supplied JSON Schema without validating it.
  public init(name: String, description: String? = nil, parameters: JSONValue) {
    tool = ChatTool(
      function: ChatToolFunction(name: name, description: description, parameters: parameters))
  }

  /// Decodes a complete matching call's arguments, preserving decoder errors.
  /// A tool call ID is not required to decode arguments.
  public func decodeArguments(
    from call: ToolCall, decoder: JSONDecoder = JSONDecoder()
  ) throws -> Arguments {
    try validate(call)
    return try decoder.decode(Arguments.self, from: Data(call.function.arguments.utf8))
  }

  /// Encodes a result as JSON text in a tool message, preserving encoder errors.
  /// The matching call must have a nonempty ID. String results remain JSON-quoted.
  public func resultMessage(
    for call: ToolCall, result: Result, encoder: JSONEncoder = JSONEncoder()
  ) throws -> ChatMessage {
    try validate(call)
    guard let id = call.id, !id.isEmpty else {
      throw TypedChatToolError.missingToolCallID
    }
    let data = try encoder.encode(result)
    return ChatMessage(
      role: .tool, content: .text(String(decoding: data, as: UTF8.self)), toolCallID: id)
  }

  private func validate(_ call: ToolCall) throws {
    guard call.type == "function" else {
      throw TypedChatToolError.unsupportedToolType(call.type)
    }
    guard call.function.name == tool.function.name else {
      throw TypedChatToolError.functionNameMismatch(
        expected: tool.function.name, actual: call.function.name)
    }
  }
}
