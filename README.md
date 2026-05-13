# OpenRouter Swift

Swift Package SDK for OpenRouter API, inspired by [`revrost/go-openrouter`](https://github.com/revrost/go-openrouter).

## Status

Core parity milestones are implemented, including:

- typed generation APIs (`getGeneration`, `listGenerationContent`) with raw JSON helpers
- resource namespaces (`client.chat`, `client.embeddings`, `client.generations`, `client.models`, `client.credits`)
- request options (`RequestOptions`) and retry policy (`RetryPolicy`)
- stream/non-stream error mapping parity
- typed error convenience flags on `OpenRouterError`

Track progress in:

- `PLAN.md`

Current v0.1 deferred item:

- Responses API parity (`createResponse`, `createResponseStream`) is deferred because the TypeScript SDK exposes it under `beta.responses` and its polymorphic payload/streaming surface needs a dedicated compatibility pass.

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

// raw fallback JSON helpers
let generationRaw = try await client.getGenerationRaw(id: "gen_123")
let generationContentRaw = try await client.listGenerationContentRaw(id: "gen_123")

// models / credits
let models = try await client.models.list()
let credits = try await client.credits.get()

// providers / endpoints
let providers = try await client.providers.list()
let endpoints = try await client.endpoints.list(author: "openai", slug: "gpt-4o-mini")
let zdrEndpoints = try await client.endpoints.listZDR()
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

- Responses API parity is intentionally deferred for `v0.1.0` while OpenRouter beta compatibility is confirmed.
- The Swift SDK prioritizes mobile-relevant TypeScript SDK resources; broader resources such as organization/workspaces, guardrails, rerank, TTS/STT, video generation, analytics, and beta namespaces are not yet implemented.
- The SSE parser supports OpenRouter chat streams and has basic multi-line frame parsing helpers; broader SSE metadata is currently ignored by the streaming client.

## v0.1.0 API review notes

- Current public APIs are expected to remain source-compatible through `0.x` where practical.
- Flat client methods remain available alongside resource namespaces for compatibility.
- `JSONValue` remains the escape hatch for raw/forward-compatible payloads.
- Responses API and broader beta/resource coverage are intentionally excluded from the first release candidate.

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
