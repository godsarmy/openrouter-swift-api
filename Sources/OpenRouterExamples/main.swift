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
    case chatFallback
    case stream
    case embed
    case complete
    case models
    case credits
    case generation
    case generationContent
  }

  struct ParsedArgs {
    var model: String?
    var prompt: String?
    var system: String?
    var generationID: String?
    var baseURL: URL?
    var output: OutputMode
    var fallbackModels: [String]
    var reasoningEffort: String?
    var webSearchContextSize: String?
    var cacheEnabled: Bool?
    var cacheTTLSeconds: Int?
    var cacheClear: Bool?
  }

  enum OutputMode: String {
    case json
    case text
  }

  static let usage = """
    Usage:
      swift run OpenRouterExamples <command> --model <model> --prompt <text> [--system <text>] [--base-url <url>] [--output json|text] [--reasoning-effort <level>] [--web-search-context-size <low|medium|high>] [--cache-enabled true|false] [--cache-ttl <seconds>] [--cache-clear true|false]

    Commands:
      chat      Run non-streaming chat completion
      chatFallback Run chat completion with fallback models
      stream    Run streaming chat completion (prints chunks as JSON)
      embed     Run embeddings request for prompt text
      complete  Run legacy completion request
      models    List models
      credits   Get credits summary
      generation Get generation by id
      generationContent Get generation content by id

    Fallback:
      --fallback-models <model1,model2,...>

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
      let request = buildChatRequest(stream: false)
      let response = try await client.createChatCompletion(request)
      printChatResponse(response)
    case .chatFallback:
      guard !args.fallbackModels.isEmpty else {
        throw CLIError.missingFallbackModels
      }
      let request = buildChatRequest(stream: false)
      let response = try await client.createChatCompletionWithFallback(
        request,
        fallbackModels: args.fallbackModels
      )
      printChatResponse(response)
    case .stream:
      let request = buildChatRequest(stream: true)
      for try await chunk in client.createChatCompletionStream(request) {
        printChatChunk(chunk)
      }
    case .embed:
      guard let model = args.model, let prompt = args.prompt else {
        throw CLIError.missingModelOrPrompt
      }
      let request = EmbeddingRequest(
        model: model,
        input: .string(prompt),
        responseCache: buildResponseCacheConfig()
      )
      let response = try await client.createEmbeddings(request)
      printEncoded(response)
    case .complete:
      guard let model = args.model, let prompt = args.prompt else {
        throw CLIError.missingModelOrPrompt
      }
      let request = CompletionRequest(
        model: model,
        prompt: prompt,
        responseCache: buildResponseCacheConfig()
      )
      let response = try await client.createCompletion(request)
      printCompletionResponse(response)
    case .models:
      printEncoded(try await client.models.list())
    case .credits:
      printEncoded(try await client.credits.get())
    case .generation:
      guard let generationID = args.generationID else { throw CLIError.missingGenerationID }
      printEncoded(try await client.generations.get(id: generationID))
    case .generationContent:
      guard let generationID = args.generationID else { throw CLIError.missingGenerationID }
      printEncoded(try await client.generations.content(id: generationID))
    }
  }

  private func buildChatRequest(stream: Bool) -> ChatCompletionRequest {
    let model = args.model ?? "openai/gpt-4o-mini"
    let prompt = args.prompt ?? "hello"
    return ChatCompletionRequest(
      model: model,
      models: command == .chatFallback && !args.fallbackModels.isEmpty
        ? [model] + args.fallbackModels : nil,
      messages: buildMessages(prompt: prompt),
      stream: stream,
      reasoning: buildReasoningConfig(),
      webSearchOptions: buildWebSearchOptions(),
      responseCache: buildResponseCacheConfig(),
      streamOptions: stream ? .init(includeUsage: true) : nil
    )
  }

  private func buildReasoningConfig() -> ChatCompletionReasoning? {
    guard let effort = args.reasoningEffort, !effort.isEmpty else { return nil }
    return ChatCompletionReasoning(effort: effort)
  }

  private func buildWebSearchOptions() -> WebSearchOptions? {
    guard let size = args.webSearchContextSize, !size.isEmpty else { return nil }
    return WebSearchOptions(searchContextSize: size)
  }

  private func buildResponseCacheConfig() -> ResponseCacheConfig? {
    if args.cacheEnabled == nil && args.cacheTTLSeconds == nil && args.cacheClear == nil {
      return nil
    }
    return ResponseCacheConfig(
      enabled: args.cacheEnabled,
      ttlSeconds: args.cacheTTLSeconds,
      clear: args.cacheClear
    )
  }

  private func buildMessages(prompt: String) -> [ChatMessage] {
    var messages: [ChatMessage] = []
    if let system = args.system, !system.isEmpty {
      messages.append(.system(system))
    }
    messages.append(.user(prompt))
    return messages
  }

  private static func parseArgs(_ tokens: [String]) throws -> ParsedArgs {
    func value(for key: String) -> String? {
      guard let i = tokens.firstIndex(of: key), i + 1 < tokens.count else { return nil }
      return tokens[i + 1]
    }

    let model = value(for: "--model")
    let prompt = value(for: "--prompt")
    let system = value(for: "--system")
    let generationID = value(for: "--generation-id")
    let fallbackModels =
      value(for: "--fallback-models")?
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty } ?? []

    let reasoningEffort = value(for: "--reasoning-effort")
    let webSearchContextSize = value(for: "--web-search-context-size")

    let cacheEnabled = parseBool(value(for: "--cache-enabled"))
    let cacheClear = parseBool(value(for: "--cache-clear"))
    let cacheTTL = parseInt(value(for: "--cache-ttl"))

    let baseURL: URL?
    if let raw = value(for: "--base-url") {
      guard let url = URL(string: raw) else { throw CLIError.invalidBaseURL(raw) }
      baseURL = url
    } else {
      baseURL = nil
    }

    let outputRaw = value(for: "--output") ?? OutputMode.json.rawValue
    guard let output = OutputMode(rawValue: outputRaw) else {
      throw CLIError.invalidOutput(outputRaw)
    }

    return ParsedArgs(
      model: model,
      prompt: prompt,
      system: system,
      generationID: generationID,
      baseURL: baseURL,
      output: output,
      fallbackModels: fallbackModels,
      reasoningEffort: reasoningEffort,
      webSearchContextSize: webSearchContextSize,
      cacheEnabled: cacheEnabled,
      cacheTTLSeconds: cacheTTL,
      cacheClear: cacheClear
    )
  }

  private static func parseBool(_ value: String?) -> Bool? {
    guard let value else { return nil }
    switch value.lowercased() {
    case "true": return true
    case "false": return false
    default: return nil
    }
  }

  private static func parseInt(_ value: String?) -> Int? {
    guard let value else { return nil }
    return Int(value)
  }

  private func printEncoded<T: Encodable>(_ value: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(value), let text = String(data: data, encoding: .utf8) {
      print(text)
      return
    }
    print(String(describing: value))
  }

  private func printChatResponse(_ response: ChatCompletionResponse) {
    switch args.output {
    case .json:
      printEncoded(response)
    case .text:
      if let first = response.choices.first {
        switch first.message.content {
        case .text(let text):
          print(text)
        case .parts(let parts):
          let text = parts.compactMap {
            if case .text(let value) = $0 { return value }
            return nil
          }.joined(separator: "\n")
          print(text)
        }
      }
    }
  }

  private func printChatChunk(_ chunk: ChatCompletionChunk) {
    switch args.output {
    case .json:
      printEncoded(chunk)
    case .text:
      for choice in chunk.choices {
        if let content = choice.delta?.content {
          print(content, terminator: "")
        }
      }
    }
  }

  private func printCompletionResponse(_ response: CompletionResponse) {
    switch args.output {
    case .json:
      printEncoded(response)
    case .text:
      if let first = response.choices.first {
        print(first.text)
      }
    }
  }
}

private enum CLIError: Error, LocalizedError {
  case invalidCommand
  case missingAPIKey
  case missingModel
  case missingPrompt
  case missingModelOrPrompt
  case missingFallbackModels
  case missingGenerationID
  case invalidBaseURL(String)
  case invalidOutput(String)

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
    case .missingModelOrPrompt:
      return "missing --model or --prompt argument"
    case .missingFallbackModels:
      return "missing --fallback-models for chatFallback command"
    case .missingGenerationID:
      return "missing --generation-id argument"
    case .invalidBaseURL(let value):
      return "invalid --base-url: \(value)"
    case .invalidOutput(let value):
      return "invalid --output value: \(value). Use 'json' or 'text'."
    }
  }
}
