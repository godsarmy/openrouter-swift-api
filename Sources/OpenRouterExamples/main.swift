import Foundation
import OpenRouter

@main
struct OpenRouterExamplesMain {
  static func main() async {
    do {
      let cli = try CLI(arguments: Array(CommandLine.arguments.dropFirst()))
      try await cli.run()
    } catch {
      writeToStderr("error: \(error)\n")
      writeToStderr("\(CLI.usage)\n")
      Foundation.exit(1)
    }
  }

  private static func writeToStderr(_ message: String) {
    if let data = message.data(using: .utf8) {
      FileHandle.standardError.write(data)
    }
  }
}

private struct CLI {
  enum Command: String {
    case chat
    case stream
    case embed
    case complete
  }

  struct ParsedArgs {
    var model: String
    var prompt: String
    var baseURL: URL?
  }

  static let usage = """
    Usage:
      swift run OpenRouterExamples <command> --model <model> --prompt <text> [--base-url <url>]

    Commands:
      chat      Run non-streaming chat completion
      stream    Run streaming chat completion (prints chunks as JSON)
      embed     Run embeddings request for prompt text
      complete  Run legacy completion request

    Environment:
      OPENROUTER_API_KEY  Required API key
    """

  let command: Command
  let args: ParsedArgs

  init(arguments: [String]) throws {
    guard let cmdRaw = arguments.first, let command = Command(rawValue: cmdRaw) else {
      throw CLIError.invalidCommand
    }
    self.command = command
    args = try CLI.parseArgs(Array(arguments.dropFirst()))
  }

  func run() async throws {
    guard let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !apiKey.isEmpty
    else {
      throw CLIError.missingAPIKey
    }

    var config = OpenRouterClient.Configuration()
    if let baseURL = args.baseURL {
      config.baseURL = baseURL
    }
    let client = OpenRouterClient(apiKey: apiKey, configuration: config)

    switch command {
    case .chat:
      let request = ChatCompletionRequest(model: args.model, messages: [.user(args.prompt)])
      let response = try await client.createChatCompletion(request)
      printJSON(response)
    case .stream:
      let request = ChatCompletionRequest(
        model: args.model, messages: [.user(args.prompt)], stream: true)
      for try await chunk in client.createChatCompletionStream(request) {
        printJSON(chunk)
      }
    case .embed:
      let request = EmbeddingRequest(model: args.model, input: .string(args.prompt))
      let response = try await client.createEmbeddings(request)
      printJSON(response)
    case .complete:
      let request = CompletionRequest(model: args.model, prompt: args.prompt)
      let response = try await client.createCompletion(request)
      printJSON(response)
    }
  }

  private static func parseArgs(_ tokens: [String]) throws -> ParsedArgs {
    func value(for key: String) -> String? {
      guard let i = tokens.firstIndex(of: key), i + 1 < tokens.count else { return nil }
      return tokens[i + 1]
    }

    guard let model = value(for: "--model"), !model.isEmpty else { throw CLIError.missingModel }
    guard let prompt = value(for: "--prompt"), !prompt.isEmpty else {
      throw CLIError.missingPrompt
    }

    let baseURL: URL?
    if let raw = value(for: "--base-url") {
      guard let url = URL(string: raw) else { throw CLIError.invalidBaseURL(raw) }
      baseURL = url
    } else {
      baseURL = nil
    }

    return ParsedArgs(model: model, prompt: prompt, baseURL: baseURL)
  }

  private func printJSON<T: Encodable>(_ value: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(value), let text = String(data: data, encoding: .utf8) {
      print(text)
      return
    }
    print(String(describing: value))
  }
}

private enum CLIError: Error, LocalizedError {
  case invalidCommand
  case missingAPIKey
  case missingModel
  case missingPrompt
  case invalidBaseURL(String)

  var errorDescription: String? {
    switch self {
    case .invalidCommand:
      return "invalid or missing command"
    case .missingAPIKey:
      return "OPENROUTER_API_KEY is not set"
    case .missingModel:
      return "missing --model argument"
    case .missingPrompt:
      return "missing --prompt argument"
    case .invalidBaseURL(let value):
      return "invalid --base-url: \(value)"
    }
  }
}
