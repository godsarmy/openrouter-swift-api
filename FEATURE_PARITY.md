# Feature Parity: go-openrouter → OpenRouter Swift

Status legend: ✅ Done · 🟨 In Progress · ⬜ Planned · ❌ Out of scope (v1)

## Scope Baseline

Source SDK: `https://github.com/revrost/go-openrouter`

v1 Goal: parity for primary API surfaces needed by iOS apps using OpenRouter.

## Client & Configuration

| Go Surface | Swift Surface (planned) | Status | Notes |
|---|---|---:|---|
| `NewClient(apiKey, options...)` | `OpenRouterClient(apiKey:configuration:)` | ⬜ | Configuration includes baseURL, timeout, headers |
| `WithHTTPReferer(...)` | `configuration.httpReferer` | ⬜ | Sent as `HTTP-Referer` |
| `WithXTitle(...)` | `configuration.xTitle` | ⬜ | Sent as `X-Title` |

## Chat Completions

| Go Surface | Swift Surface (planned) | Status | Notes |
|---|---|---:|---|
| `CreateChatCompletion` | `createChatCompletion(_:) async throws` | ⬜ | Core endpoint |
| `CreateChatCompletionStream` | `createChatCompletionStream(_:) -> AsyncThrowingStream` | ⬜ | SSE streaming |
| `CreateChatCompletionWithFallback` | `createChatCompletionWithFallback(_:fallbackModels:)` | ⬜ | Sequential fallback |
| `CreateChatCompletionStreamWithFallback` | `createChatCompletionStreamWithFallback(_:fallbackModels:)` | ⬜ | Fallback only pre-stream |
| `CreateChatCompletionWithFallbackPolicy` | `createChatCompletionWithFallbackPolicy(_:policy:)` | ⬜ | Custom status/error code policy |
| `DefaultChatCompletionFallbackErrorCodes` | `ChatCompletionFallbackPolicy.defaultErrorCodes` | ⬜ | `402, 408, 429, 500, 502, 503, 504, 524, 529` |

## Other Endpoints

| Go Surface | Swift Surface (planned) | Status | Notes |
|---|---|---:|---|
| Completion API | `createCompletion(_:) async throws` | ⬜ | Keep if required by target apps |
| Embeddings API | `createEmbeddings(_:) async throws` | ⬜ | Required |

## Data/Schema Capabilities

| Capability | Swift Plan | Status | Notes |
|---|---|---:|---|
| Tool calling | Codable tool definitions + calls | ⬜ | Function/tool JSON schema support |
| Structured outputs | `response_format` JSON schema types | ⬜ | Strict mode support |
| Multimodal input | text/image/pdf/audio content parts | ⬜ | Match OpenRouter message content types |
| Usage fields | Token usage structs | ⬜ | Include request/response accounting fields |
| Reasoning fields | Typed optional fields | ⬜ | Preserve provider-specific optionality |
| Prompt caching fields | Typed optional fields | ⬜ | Transparent pass-through where needed |
| Web search fields | Typed optional fields | ⬜ | Endpoint-specific options support |

## Error Behavior

| Behavior | Swift Plan | Status | Notes |
|---|---|---:|---|
| Map HTTP + API error body | Unified `OpenRouterError` | ⬜ | Include status, code, message, raw payload |
| Fallback decision checks HTTP and API code | Policy evaluator | ⬜ | Match Go behavior |

## Non-goals (v1)

- ❌ Opinionated iOS UI helpers
- ❌ Persistence/caching layer in SDK core
- ❌ Model registry sync job

## Acceptance Criteria

- All “Client & Configuration” and “Chat Completions” rows implemented.
- Embeddings implemented.
- Streaming reliability + cancellation covered by tests.
- Fallback behavior verified against default code list.
