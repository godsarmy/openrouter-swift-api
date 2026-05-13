# OpenRouter Swift Reimplementation Plan

Goal: Reimplement OpenRouter SDK capabilities in Swift as a reusable Swift Package for future iOS apps, using `OpenRouterTeam/typescript-sdk` as the main parity reference.

## Progress Legend
- [ ] Not started
- [~] In progress
- [x] Done

---

## Phase 0 — Project Framing

- [x] Confirm target platform/version (recommended: iOS 15+)
- [x] Confirm Swift tools version and CI macOS/Xcode matrix
- [x] Define parity scope with `OpenRouterTeam/typescript-sdk`
- [x] Fold parity status into `README.md` / `PLAN.md`

**Exit criteria**
- Clear, frozen v1 feature scope and compatibility targets.

---

## Phase 1 — Package Foundation

- [x] Initialize Swift Package: `OpenRouterSwift`
- [x] Create targets:
  - [x] `OpenRouter` (library)
  - [x] `OpenRouterTests` (tests)
  - [x] Optional `OpenRouterExamples` (sample usage)
- [x] Add base module layout:
  - [x] `Sources/OpenRouter/Public`
  - [x] `Sources/OpenRouter/Internal/Transport`
  - [x] `Sources/OpenRouter/Internal/Streaming`
  - [x] `Sources/OpenRouter/Models`
- [x] Add README skeleton with Quick Start placeholder

**Exit criteria**
- Package builds cleanly with placeholder client type.

---

## Phase 2 — Public API Design

- [x] Define `OpenRouterClient` initializer/config:
  - [x] `apiKey`
  - [x] optional `baseURL`
  - [x] optional `httpReferer`
  - [x] optional `xTitle`
  - [x] timeout/session injection
- [x] Define primary methods:
  - [x] `createChatCompletion(_:) async throws -> ChatCompletionResponse`
  - [x] `createChatCompletionStream(_:) -> AsyncThrowingStream<ChatCompletionChunk, Error>`
  - [x] `createEmbeddings(_:) async throws -> EmbeddingResponse`
  - [x] `createCompletion(_:) async throws -> CompletionResponse` (if in scope)
- [x] Define fallback APIs:
  - [x] `createChatCompletionWithFallback(...)`
  - [x] `createChatCompletionStreamWithFallback(...)`
  - [x] `ChatCompletionFallbackPolicy`

**Exit criteria**
- Public signatures stabilized for v1.

---

## Phase 3 — Models & Serialization

- [x] Implement Codable request/response models:
  - [x] Chat completion request/response
  - [x] Message roles and content parts
  - [x] Tool/function calling schema types
  - [x] Structured output / response_format JSON schema
  - [x] Embedding request/response
  - [x] Completion request/response (if in scope)
  - [x] Usage/token accounting fields
- [x] Support multimodal content:
  - [x] text
  - [x] image
  - [x] pdf
  - [x] audio
- [x] Add robust decoding for polymorphic fields

**Exit criteria**
- Model round-trip encode/decode tests passing.

---

## Phase 4 — Transport Layer

- [x] Build request factory (method/path/headers/body)
- [x] Inject auth (`Authorization: Bearer ...`)
- [x] Inject optional OpenRouter headers (`HTTP-Referer`, `X-OpenRouter-Title`, categories, experimental metadata)
- [x] Implement JSON response decoding and error decoding
- [x] Map HTTP + API errors to Swift error enum

**Exit criteria**
- Non-streaming endpoints function through a single shared transport.

---

## Phase 5 — Streaming (SSE)

- [x] Implement SSE parser for `data:` frames
- [x] Handle sentinel `[DONE]`
- [x] Decode chunk payloads into `ChatCompletionChunk`
- [x] Expose as `AsyncThrowingStream`
- [x] Ensure cancellation/cleanup works correctly

**Exit criteria**
- Streamed chat completion stable under normal/error/cancel paths.

---

## Phase 6 — Fallback Policy & Reliability

- [x] Add default fallbackable error codes:
  - [x] 402, 408, 429, 500, 502, 503, 504, 524, 529
- [x] Check both HTTP status and API error body code
- [x] Implement model retry order semantics
- [x] Ensure streaming fallback only occurs before stream establishment
- [x] Add configurable policy override support

**Exit criteria**
- Fallback behavior matches documented OpenRouter SDK semantics.

---

## Phase 7 — Testing

- [x] Unit tests:
  - [x] Model encoding/decoding
  - [x] Error mapping
  - [x] Fallback policy decisions
  - [x] SSE parser edge cases
- [x] Transport tests with mocked `URLProtocol`
- [x] Integration tests (opt-in via `OPENROUTER_API_KEY`):
  - [x] Chat completion
  - [x] Streaming chat completion
  - [x] Embeddings
- [x] Add deterministic fixtures for CI

**Exit criteria**
- Reliable CI passing without requiring live API for core suite.

---

## Phase 8 — Docs, Examples, Developer Experience

- [x] Quick start in README
- [ ] Examples:
  - [x] Basic chat
  - [x] Streaming chat
  - [x] Tool calling
  - [x] Structured outputs
  - [x] Fallback usage
- [x] Add convenience builders:
  - [x] `.user("...")`, `.system("...")`
- [x] Add migration notes and known limitations

**Exit criteria**
- A new user can run examples in minutes.

---

## Phase 9 — Release Management

- [x] Add CI workflow (build + test)
- [~] Add lint/format tooling (currently using `swift format` manually; formal check job still optional)
- [ ] Tag first release (`v0.1.0` suggested; release candidate notes prepared)
- [x] Maintain `CHANGELOG.md`
- [x] Define versioning and compatibility policy

**Exit criteria**
- First consumable package release published.

---

## Phase 10 — TypeScript SDK Parity Gap Closure

Source reference: `https://github.com/OpenRouterTeam/typescript-sdk`

### Current Swift Coverage Snapshot

- [x] Chat Completion
- [x] Completion
- [x] Streaming
- [x] Embeddings
- [x] Generations
- [x] Models
- [x] Credits
- [x] Reasoning
- [x] Tool calling
- [x] Structured outputs
- [x] Prompt caching
- [x] Response caching
- [x] Web search
- [x] Multimodal [Images, PDFs, Audio]
- [x] Usage fields
- [x] Resource namespaces (`client.chat`, `client.embeddings`, `client.generations`, `client.models`, `client.credits`)
- [x] Per-request options (`RequestOptions`: timeout, retries, baseURL, extraHeaders)
- [x] Retry/backoff policy with retry status codes and `Retry-After`
- [x] Stream/non-stream API error envelope mapping parity

- [x] Reasoning support parity:
  - [x] Add request reasoning options in `ChatCompletionRequest`
  - [x] Add response/chunk reasoning fields where returned
  - [x] Add model round-trip tests for reasoning fields
- [x] Prompt caching parity:
  - [x] Add prompt-caching request fields
  - [x] Verify field names/shape against OpenRouter docs
  - [x] Add encode/decode tests
- [x] Response caching parity:
  - [x] Add `ResponseCacheConfig` on supported requests
  - [x] Map cache config to transport headers (enable/ttl/clear)
  - [x] Parse cache metadata from response headers
  - [x] Expose cache metadata for streaming responses
  - [x] Add unit tests for header emission + metadata parsing
- [x] Web search parity:
  - [x] Add web-search request options to chat request models
  - [x] Add typed response fields for search-related annotations (if present)
  - [x] Add request/response tests
- [x] Multimodal tightening parity:
  - [x] Validate image/pdf/audio payload object shapes
  - [x] Add multimodal fixture tests (image/pdf/audio variants)
  - [x] Document accepted multimodal formats in README
- [x] Streaming reliability upgrade:
  - [x] Replace buffered stream read with true incremental streaming where available
  - [x] Keep SSE parser `[DONE]` behavior consistent
  - [x] Add tests for incremental chunk delivery behavior

### Required Modifications vs TypeScript SDK

#### P0 — Release-blocking / high-value gaps

- [~] Responses API parity:
  - [x] Confirmed TypeScript SDK exposes it under `beta.responses` with complex polymorphic payload/streaming surface.
  - [x] Deferred from `v0.1.0` pending dedicated compatibility pass.
  - [ ] Add typed `ResponsesRequest` / response result models.
  - [ ] Add `createResponse(_:, options:)`.
  - [ ] Add `createResponseStream(_:) -> AsyncThrowingStream<...>` when stream shape is confirmed.
  - [ ] Add mocked transport + streaming tests.
- [x] README/API limitations section:
  - [x] Document implemented TypeScript SDK parity subset.
  - [x] Explicitly document unsupported TypeScript resources and deferred Responses API.
  - [x] Add tool-calling and structured-output usage snippets.
- [~] Release readiness:
  - [x] Add `CHANGELOG.md`.
  - [x] Define semantic versioning/source-compatibility policy.
  - [x] Add v0.1.0 API review notes.
  - [ ] Tag `v0.1.0` after API review.

#### P1 — Strong parity / developer experience

- [ ] Broaden TypeScript resource coverage, prioritized by likely mobile demand:
  - [x] Providers resource.
  - [x] Endpoints resource.
  - [ ] API keys resource, if safe and supported for client contexts.
  - [ ] Organization/workspaces resources, if server-side Swift use is in scope.
  - [ ] Guardrails, rerank, TTS/STT, video generation, analytics, beta resources as follow-up if OpenRouter API compatibility is stable.
- [ ] Typed error taxonomy:
  - [ ] Keep `OpenRouterError.apiError` for source compatibility.
  - [x] Add helpers or cases for common statuses (`badRequest`, `unauthorized`, `forbidden`, `notFound`, `rateLimited`, `serverError`).
  - [x] Preserve transport/network errors separately from API errors.
- [x] Debug/observability hooks:
  - [x] Add optional redacted debug logger to `Configuration`.
  - [x] Log request method/path/status/retry attempts without secrets.
- [ ] Higher-level typed tool helper (TypeScript `callModel` analogue):
  - [ ] Explore Swift-friendly API for typed tool execution.
  - [ ] Keep raw chat/tool APIs as canonical lower-level surface.

#### P2 — Protocol robustness / optional parity

- [ ] SSE parser hardening:
  - [x] Support multi-line `data:` frame coalescing if needed.
  - [x] Decide whether to preserve/ignore `event:`, `id:`, and `retry:` fields.
  - [x] Add fixtures for comments, CRLF, multi-line payloads, and trailing partial lines.
- [ ] Standalone function-style APIs:
  - [ ] Evaluate whether Swift should add non-client free functions or lightweight service functions.
  - [ ] Prefer not adding if it duplicates API surface without strong Swift ergonomics benefit.
- [ ] Auto-pagination / iterators:
  - [ ] Add only when paginated resources are implemented.

**Exit criteria**
- Core Swift SDK remains source-compatible for current public APIs.
- Responses API status is either implemented or intentionally documented as deferred.
- README clearly states implemented TypeScript SDK parity subset and limitations.
- `swift test` and CI pass.

---

## Milestones

- [x] **M1**: Package + non-streaming chat working end-to-end
- [x] **M2**: Streaming + fallback policy complete
- [x] **M3**: Embeddings/tools/structured outputs + docs/tests
- [~] **M4**: CI green + first release tag
- [x] **M5**: Reasoning/caching/web-search parity complete
- [x] **M6**: TypeScript SDK parity audit closure (Responses API decision + documented resource gaps)

---

## Risks & Mitigations

- [ ] SSE edge-case parsing issues → build fixture-based parser tests early
- [ ] API schema drift vs OpenRouter docs → periodic parity audit
- [ ] Overly rigid models for polymorphic payloads → controlled custom decoders
- [ ] iOS networking/cancellation quirks → explicit cancellation tests
- [ ] TypeScript SDK resource breadth grows faster than Swift implementation → prioritize mobile-relevant resources and document gaps.

---

## Session Tracking

### Current focus
- [x] Set current task at session start

### Activity log
- [x] Initial plan drafted and committed to `PLAN.md`
- [x] Add dated updates per session

### 2026-05-03
- Completed:
  - Added Phase 0 framing artifacts (later folded into `README.md` / `PLAN.md`).
  - Confirmed v1 compatibility targets and CI direction.
  - Marked all Phase 0 checklist items complete.
  - Completed Phase 1 package foundation with library, tests, examples targets and base layout.
  - Completed Phase 2 public API signatures for client/config/endpoints/fallback policy.
  - Completed Phase 3 models/serialization with multimodal content and polymorphic JSON decoding.
  - Completed Phase 4 transport layer with request builder, auth/custom headers, and API error mapping.
  - Completed Phase 5 streaming with SSE parser, [DONE] handling, and chunk decoding.
  - Added executable CLI examples for chat/stream/embed/complete with env-based API key.
  - Enhanced CLI with --system prompt support and --output json|text modes.
  - Completed Phase 6 fallback policy with status/body-code checks and retry order logic.
  - Completed Phase 7 testing with mocked transport, integration test scaffolding, and fixtures.
- In progress:
  - Phase 8 docs/examples/developer experience.
- Next:
  - Add tool-calling, structured-output, and fallback-focused usage examples.

### 2026-05-11
- Completed:
  - Added typed generation primary APIs and raw JSON helpers.
  - Added models/credits resources and resource namespace API shape.
  - Added request options, retry policy, typed error conveniences, and stream/non-stream error mapping parity.
  - Added CI workflow and removed completed one-off planning docs after folding status into README/PLAN.
  - Reviewed TypeScript SDK public API surface and updated this plan with remaining parity gaps.
- In progress:
  - TypeScript SDK parity gap closure.
- Next:
  - Tag `v0.1.0` after final API review.
  - Start dedicated Responses API compatibility pass after first release.

Suggested update format:

```md
### 2026-05-03
- Completed:
  - ...
- In progress:
  - ...
- Next:
  - ...
```
