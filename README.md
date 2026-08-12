# OpenRouter Swift

Swift Package SDK for OpenRouter API, inspired by [`revrost/go-openrouter`](https://github.com/revrost/go-openrouter).

## Quick Start

```swift
import OpenRouter

let client = OpenRouterClient(apiKey: "<OPENROUTER_API_KEY>")
```

## Example CLI

The `OpenRouterExamples` executable target can be used to test API features quickly.

Set API key:

```bash
export OPENROUTER_API_KEY="<your-key>"
```

Run commands:

```bash
swift run OpenRouterExamples chat --model openai/gpt-4o-mini --prompt "hello"
swift run OpenRouterExamples chatFallback --model deepseek/deepseek-chat --fallback-models "openai/gpt-4o-mini,anthropic/claude-sonnet-4.5" --prompt "hello"
swift run OpenRouterExamples stream --model openai/gpt-4o-mini --prompt "give me 3 bullets"
swift run OpenRouterExamples generation --generation-id "gen_123"
swift run OpenRouterExamples generationContent --generation-id "gen_123"
swift run OpenRouterExamples models
swift run OpenRouterExamples credits
swift run OpenRouterExamples embed --model text-embedding-3-small --prompt "swift sdk"
swift run OpenRouterExamples complete --model openai/gpt-3.5-turbo-instruct --prompt "hello"
swift run OpenRouterExamples chat --model openai/gpt-4o-mini --system "You are concise" --prompt "hello" --output text
swift run OpenRouterExamples chat --model openai/gpt-4o-mini --prompt "summarize" --reasoning-effort high --web-search-context-size medium
swift run OpenRouterExamples chat --model openai/gpt-4o-mini --prompt "summarize" --cache-enabled true --cache-ttl 300
```

Options:

- `--system <text>` adds a system message before the user prompt
- `--output json|text` controls output format (default: `json`)
- `--fallback-models <m1,m2,...>` enables fallback routing for `chatFallback`
- `--generation-id <id>` fetches generation details/content for `generation` and `generationContent`
- `--reasoning-effort <xhigh|high|medium|low|minimal|none>` sets reasoning effort
- `--web-search-context-size <low|medium|high>` enables web search context controls
- `--cache-enabled true|false`, `--cache-ttl <seconds>`, `--cache-clear true|false` control response caching headers
- streaming requests in the example CLI set `stream_options.include_usage=true` so terminal usage chunks can be emitted

## Additional SDK examples

```swift
let client = OpenRouterClient(apiKey: apiKey)

// typed generation endpoints
let generation = try await client.getGeneration(id: "gen_123")
let generationContent = try await client.listGenerationContent(id: "gen_123")

// Responses API (non-streaming)
let response = try await client.responses.create(.init(
  model: "openai/o4-mini",
  input: .text("hello")
))

// Anthropic Messages API. Set `maxTokens` for compatible providers.
let message = try await client.messages.create(.init(
  model: "anthropic/claude-sonnet-4",
  messages: [.init(role: .user, content: .text("Hello"))],
  maxTokens: 256
))
for try await event in client.messages.stream(.init(
  model: "anthropic/claude-sonnet-4",
  messages: [.init(role: .user, content: .text("Hello"))], maxTokens: 256
)) {
  if event.type == "content_block_delta" { print(event.delta ?? .null) }
}
// Unknown Messages blocks and SSE fields remain available through raw payload values.

// Rerank documents by relevance.
let reranked = try await client.rerank.create(.init(
  model: "cohere/rerank-v3.5", query: "Swift concurrency",
  documents: [.text("Actors protect mutable state."), .object(.init(text: "Structured concurrency guide"))],
  topN: 2
))

// Beta Responses API SSE streaming; events retain their raw payload for forward compatibility.
for try await event in client.responses.stream(.init(model: "openai/o4-mini", input: .text("hello"))) {
  if event.type == "response.output_text.delta" || event.type == "response.content_part.delta" {
    print(event.delta ?? "", terminator: "")
  }
  // `response.function_call_arguments.delta` is exposed through `event.delta` too.
}

// Responses function tool call and stateless replay. Reasoning-capable models can preserve
// reasoning context with `include: ["reasoning.encrypted_content"]` and `context: "all_turns"`.
let tool = ResponsesFunctionTool(name: "get_weather", parameters: .object(["type": .string("object")]))
let userMessage = ResponsesInputMessage(role: "user", content: [.init(text: "Weather in Paris?")])
let first = try await client.responses.create(.init(
  model: "openai/o4-mini", input: .messages([userMessage]), tools: [tool],
  reasoning: .init(context: "all_turns"), include: ["reasoning.encrypted_content"]
))
if let call = first.output.compactMap(\.functionCall).first {
  let replayItems: [ResponsesInputItem] =
    [.message(userMessage)]
    + first.output.compactMap(\.reasoningItem).map(ResponsesInputItem.reasoning)
    + [.functionCall(call), .functionCallOutput(.init(callID: call.callID, output: .text("Sunny")))]
  let followUp = try await client.responses.create(.init(
    model: "openai/o4-mini",
    input: .items(replayItems)
  ))
}

// raw fallback JSON helpers
let generationRaw = try await client.getGenerationRaw(id: "gen_123")
let generationContentRaw = try await client.listGenerationContentRaw(id: "gen_123")

// models / credits
let models = try await client.models.list()
let userModels = try await client.models.listUser(offset: 0, limit: 25)
let credits = try await client.credits.get()
let currentKey = try await client.keys.current()
let managedKeys = try await client.keys.list(includeDisabled: false, offset: 0)
let managedKey = try await client.keys.get(hash: "hash_example_metadata_only")
let disabledKey = try await client.keys.update(
  hash: "hash_example_metadata_only", .init(disabled: true)
)
// Destructive and permanent: only run after confirming the target key.
// let confirmation = try await client.keys.delete(hash: "hash_example_metadata_only")
let createdKey = try await client.keys.create(.init(name: "Service integration"))
// `createdKey.key` is returned once; store it securely without logging or printing it.
let activity = try await client.activity.get(date: "2026-08-10", groupBy: "workspace")
let rankings = try await client.datasets.rankingsDaily(period: "week", modality: "text")

// providers / endpoints
let providers = try await client.providers.list()
let endpoints = try await client.endpoints.list(author: "openai", slug: "gpt-4o-mini")
let zdrEndpoints = try await client.endpoints.listZDR()
```

## Media APIs

- Text-to-speech: `client.audio.speech(_:)` creates speech and returns audio `Data`.
- Transcription: `client.audio.transcribe(_:)` uploads an `AudioTranscriptionFile` and returns typed text, usage, and the raw response payload.
- Video: `client.videos.create(_:)` creates a job, `client.videos.get(jobId:)` polls it, and `client.videos.models.list()` discovers video-model capabilities.
- Video content: `client.videos.content(_:)` downloads a completed video as buffered `Data` and preserves its response `Content-Type` in `VideoContentResponse`. It buffers the complete file in memory; for large downloads, prefer the completed job's unsigned URLs.

### Live video certification smoke test

The full video workflow test creates provider work, can take up to 10 minutes, and incurs provider cost. It is opt-in and skipped by default, including under a normal `swift test` run. Run it only with a supported configured model and an intentional content download:

```bash
OPENROUTER_RUN_INTEGRATION=true \
OPENROUTER_RUN_VIDEO_INTEGRATION=true \
OPENROUTER_RUN_VIDEO_CONTENT_DOWNLOAD=true \
OPENROUTER_API_KEY="<your-key>" \
OPENROUTER_VIDEO_MODEL="<supported-video-model>" \
swift test --filter OpenRouterIntegrationTests/testIntegrationVideoWorkflow
```

## Tool calling and structured outputs

```swift
let weatherTool = ChatTool(
  function: .init(
    name: "get_weather",
    description: "Get weather for a city",
    parameters: .object([
      "type": .string("object"),
      "properties": .object([
        "city": .object(["type": .string("string")])
      ]),
      "required": .array([.string("city")])
    ])
  )
)

let response = try await client.chat.send(.init(
  model: "openai/gpt-4o-mini",
  messages: [.user("What's the weather in London?")],
  tools: [weatherTool],
  toolChoice: .auto
))
```

```swift
let jsonSchema = JSONSchemaWrapper(
  name: "summary",
  strict: true,
  schema: .object([
    "type": .string("object"),
    "properties": .object([
      "summary": .object(["type": .string("string")])
    ]),
    "required": .array([.string("summary")])
  ])
)

let structured = try await client.chat.send(.init(
  model: "openai/gpt-4o-mini",
  messages: [.user("Summarize this SDK")],
  responseFormat: .init(type: "json_schema", jsonSchema: jsonSchema)
))
```

## Current limitations

- The Responses API remains beta. SSE streaming is available via `client.responses.stream` with forward-compatible raw typed events, including text and function argument deltas; provider-specific beta event fields may still require `rawPayload`.
- Broader resources such as organization/workspaces, guardrails, analytics, and other beta namespaces are not yet implemented.
- The SSE parser supports OpenRouter chat streams and has basic multi-line frame parsing helpers; broader SSE metadata is currently ignored by the streaming client.

## Roadmap

Endpoint coverage is tracked in [`APIs.md`](APIs.md). Remaining non-endpoint follow-ups:

- Track additional beta Responses event fields as OpenRouter confirms them.
- Consider a higher-level Swift-friendly typed tool helper while keeping raw chat/tool APIs canonical.
- Add pagination helpers only after paginated resources are implemented.

## v0.2.0 API review notes

- Current public APIs are expected to remain source-compatible through `0.x` where practical.
- Flat client methods remain available alongside resource namespaces for compatibility.
- `JSONValue` remains the escape hatch for raw/forward-compatible payloads.
- Broader beta/resource coverage remains intentionally incremental.

## Versioning policy

Before `1.0`, minor versions may add APIs and patch versions are reserved for compatible fixes. After `1.0`, the package follows semantic versioning: breaking source changes require a major version, additive APIs use minor versions, and bug fixes use patch versions.

## Multimodal Content Formats

The SDK supports both simple and object-based multimodal payloads in chat message parts.

### Text

- Simple text content:
  - `Content.text("hello")`
- Multipart text part:
  - `.text("hello")`
- Prompt-cached text part:
  - `.textWithCache(text: "long context", cacheControl: .init(type: "ephemeral", ttl: "5m"))`

### Images

- URL string form:
  - `.imageURL("https://example.com/image.png")`
- Object form (detail-aware):
  - `.image(.init(url: "https://example.com/image.png", detail: "high"))`

### PDFs / Files

- URL string form:
  - `.fileURL("https://example.com/file.pdf")`
- Object form (file parser style):
  - `.file(.init(filename: "paper.pdf", fileData: "<base64>"))`

### Audio Input

- Object form:
  - `.inputAudio(.init(data: "<base64>", format: "wav"))`

### Example (multipart)

```swift
let message = ChatMessage(
  role: .user,
  content: .parts([
    .text("Describe this image and PDF"),
    .image(.init(url: "https://example.com/image.png", detail: "high")),
    .file(.init(filename: "paper.pdf", fileData: "<base64>")),
    .inputAudio(.init(data: "<base64>", format: "wav")),
  ])
)
```
