# OpenRouter Swift — API Parity and Refactor Plan

## Status Snapshot (May 2026)

- ✅ Done: models endpoint, credits endpoint, header/config parity (`appTitle`, `appCategories`, `experimentalMetadata`), typed generation model structs + tests
- 🟡 Partial: typed generation APIs are available via `getGenerationResponse` / `listGenerationContentResponse`, while legacy `JSONValue` methods remain
- ⏳ Pending: resource namespaces, stream/non-stream error parity, `RequestOptions`, retry policy, typed error conveniences, docs/examples refresh
- 🔒 Deferred: Responses API (until compatibility/priority is confirmed)

## Goal
Improve parity with the official TypeScript SDK source at:

`https://github.com/OpenRouterTeam/typescript-sdk/tree/main/src`

Focus areas:
- typed endpoint coverage
- resource-oriented API shape
- transport reliability
- streaming/non-streaming consistency
- request/header parity
- reduced overuse of `JSONValue`

---

## P0 — Core parity fixes

### 1) Add typed generation models

**Status:** 🟡 Partial

**Current state**

Swift currently exposes:

```swift
getGeneration(id:) -> JSONValue
listGenerationContent(id:) -> JSONValue
```

**Problem**

The API is functional but untyped, so callers lose discoverability and compile-time safety.

**Plan**

Add typed models in `Sources/OpenRouter/Public/OpenRouterAPIModels.swift`:

```swift
public struct GenerationResponse: Codable, Sendable, Equatable { ... }
public struct GenerationContentResponse: Codable, Sendable, Equatable { ... }
```

Update client methods in `Sources/OpenRouter/Public/OpenRouterClient.swift`:

```swift
public func getGeneration(id: String) async throws -> GenerationResponse
public func listGenerationContent(id: String) async throws -> GenerationContentResponse
```

Optionally keep raw helpers:

```swift
public func getGenerationRaw(id: String) async throws -> JSONValue
public func listGenerationContentRaw(id: String) async throws -> JSONValue
```

**Tests**

Update:
- `Tests/OpenRouterTests/OpenRouterGenerationsTests.swift`

Add assertions for typed fields and raw fallback behavior if raw helpers are kept.

---

### 2) Add missing high-value resources

**Status:** 🟡 Partial

The TypeScript SDK exposes many namespaces. Swift currently covers only a subset.

Prioritize low-risk, high-use endpoints first.

#### 2.1 Models endpoint

**Status:** ✅ Done

Add:

```swift
public func listModels() async throws -> ModelsResponse
```

Later namespace shape:

```swift
client.models.list()
```

Suggested models:

```swift
public struct ModelsResponse: Codable, Sendable, Equatable {
  public var data: [OpenRouterModel]
}

public struct OpenRouterModel: Codable, Sendable, Equatable {
  public var id: String
  public var name: String?
  public var description: String?
  public var contextLength: Int?
  public var pricing: ModelPricing?
}
```

#### 2.2 Credits endpoint

**Status:** ✅ Done

Add:

```swift
public func getCredits() async throws -> CreditsResponse
```

Later namespace shape:

```swift
client.credits.get()
```

#### 2.3 Responses API

**Status:** 🔒 Deferred

Add after models/credits if OpenRouter compatibility is confirmed:

```swift
public func createResponse(_ request: ResponsesRequest) async throws -> OpenResponsesResult
public func createResponseStream(_ request: ResponsesRequest) -> AsyncThrowingStream<ResponseStreamEvent, Error>
```

**Tests**

Add mocked endpoint tests for each new method.

---

### 3) Improve request/header parity

**Status:** ✅ Done

The TypeScript SDK supports global and per-operation header options:

- `httpReferer`
- `appTitle`
- `appCategories`
- `xOpenRouterExperimentalMetadata`

Current Swift config has:

- `httpReferer`
- `xTitle`

**Plan**

Add config fields:

```swift
public var appTitle: String?
public var appCategories: [String]?
public var experimentalMetadata: String?
```

Map to headers:

- `HTTP-Referer`
- `X-OpenRouter-Title`
- `X-OpenRouter-Categories`
- `X-OpenRouter-Experimental-Metadata`

Keep `xTitle` as compatibility alias if needed.

**Tests**

Update:
- `Tests/OpenRouterTests/OpenRouterTransportTests.swift`

---

## P1 — API and transport refactor

### 4) Introduce resource namespaces

**Status:** ⏳ Pending

Current Swift API is flat:

```swift
client.createChatCompletion(...)
client.createEmbeddings(...)
client.getGeneration(...)
```

The TypeScript SDK uses resource namespaces:

```ts
client.chat.send(...)
client.embeddings.create(...)
client.generations.getGeneration(...)
```

**Suggested Swift shape**

```swift
client.chat.send(...)
client.embeddings.create(...)
client.generations.get(...)
client.models.list()
client.credits.get()
```

**Plan**

Add resource structs:

```swift
public struct ChatResource { ... }
public struct EmbeddingsResource { ... }
public struct GenerationsResource { ... }
public struct ModelsResource { ... }
public struct CreditsResource { ... }
```

Expose on `OpenRouterClient`:

```swift
public var chat: ChatResource { ... }
public var embeddings: EmbeddingsResource { ... }
public var generations: GenerationsResource { ... }
public var models: ModelsResource { ... }
public var credits: CreditsResource { ... }
```

Keep existing flat methods as backwards-compatible wrappers during transition.

---

### 5) Unify stream and non-stream error handling

**Status:** ⏳ Pending

**Current state**

Non-stream responses use shared decode/error mapping.

Streaming non-2xx responses currently produce a more generic error path.

**Problem**

Streaming errors lose useful API body details.

**Plan**

Refactor streaming response handling so stream errors parse the same envelope as non-stream:

```json
{
  "error": {
    "code": 429,
    "message": "Rate limited"
  }
}
```

Targets:
- `Sources/OpenRouter/Public/OpenRouterClient.swift`
- `Sources/OpenRouter/Internal/Transport/HTTPTransport.swift`

**Tests**

Add streaming non-2xx tests asserting:
- status code preserved
- error code/message preserved
- raw body preserved when JSON decode fails

---

### 6) Add `RequestOptions`

**Status:** ⏳ Pending

The TypeScript SDK supports per-request options such as timeout, retries, base URL override, and extra headers.

**Suggested Swift shape**

```swift
public struct RequestOptions: Sendable, Equatable {
  public var timeout: TimeInterval?
  public var retries: RetryPolicy?
  public var baseURL: URL?
  public var extraHeaders: [String: String]
}
```

Add overloads:

```swift
public func createChatCompletion(
  _ request: ChatCompletionRequest,
  options: RequestOptions? = nil
) async throws -> ChatCompletionResponse
```

Apply similarly to embeddings, completions, generations, models, credits, and future responses API.

---

## P2 — Reliability and ergonomics

### 7) Add retry policy

**Status:** ⏳ Pending

The TypeScript SDK includes retry/backoff behavior.

**Suggested Swift shape**

```swift
public enum RetryPolicy: Sendable, Equatable {
  case none
  case backoff(
    maxAttempts: Int,
    initialDelay: TimeInterval,
    maxDelay: TimeInterval,
    exponent: Double,
    retryStatusCodes: Set<Int>,
    retryConnectionErrors: Bool
  )
}
```

Behavior:
- retry configured status codes
- support status families such as `5xx`
- respect `Retry-After` header when present
- optionally retry connection failures

**Tests**

Add tests for:
- retries on 500/502/503
- no retry on 400 by default
- `Retry-After` handling
- connection error retry when enabled

---

### 8) Add typed error conveniences

**Status:** ⏳ Pending

Current `OpenRouterError.apiError` is usable, but callers need to inspect status manually.

Add convenience properties:

```swift
public var statusCode: Int?
public var isUnauthorized: Bool
public var isPaymentRequired: Bool
public var isRateLimited: Bool
public var isServerError: Bool
public var retryAfter: TimeInterval?
```

Optional future refinement:

```swift
case unauthorized(...)
case paymentRequired(...)
case rateLimited(...)
case serverError(...)
```

Prefer convenience properties first to avoid breaking current API.

---

### 9) Reduce `JSONValue` overuse

**Status:** ⏳ Pending

Keep `JSONValue` as an escape hatch, but avoid making it the primary result for stable endpoints.

Prioritize typed wrappers for:
- generation responses
- generation content responses
- models endpoint
- credits endpoint
- responses API results/events
- common tool/function schema helpers
- structured output schema helpers

---

## P3 — Documentation and examples

### 10) Update README and examples

**Status:** ⏳ Pending

Add examples for:
- usage/cost from non-streaming chat
- usage/cost from final streaming chunk
- generation lookup by generation id
- models list
- credits lookup
- provider routing / `models` request fallback
- `stream_options.include_usage`

Targets:
- `README.md`
- `Sources/OpenRouterExamples/main.swift`
- `PLAN.md` / parity docs if maintained

---

## Suggested execution order

1. Typed generation models and generation API return types.
2. Models endpoint.
3. Credits endpoint.
4. Header/config parity (`appTitle`, `appCategories`, experimental metadata).
5. Resource namespaces with flat wrappers preserved.
6. Streaming error-body parity.
7. `RequestOptions`.
8. Retry policy.
9. Typed Responses API.
10. Docs/examples refresh.

---

## Acceptance criteria

- Existing public methods remain source-compatible unless explicitly versioned as breaking.
- New endpoint methods have mocked tests.
- Stable endpoints return typed models, not `JSONValue`.
- Streaming and non-streaming error behavior are consistent.
- `swift test` passes after each phase.
- README/examples reflect newly added public APIs.
