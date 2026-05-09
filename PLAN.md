# OpenRouter Swift Reimplementation Plan

Goal: Reimplement the `go-openrouter` SDK in Swift as a reusable Swift Package for future iOS apps.

## Progress Legend
- [ ] Not started
- [~] In progress
- [x] Done

---

## Phase 0 — Project Framing

- [x] Confirm target platform/version (recommended: iOS 15+)
- [x] Confirm Swift tools version and CI macOS/Xcode matrix
- [x] Define parity scope with `revrost/go-openrouter`
- [x] Produce `FEATURE_PARITY.md` mapping Go API → Swift API

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
- [x] Inject optional OpenRouter headers (`HTTP-Referer`, `X-Title`)
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
- Fallback behavior matches documented Go client semantics.

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

- [ ] Quick start in README
- [ ] Examples:
  - [x] Basic chat
  - [x] Streaming chat
  - [ ] Tool calling
  - [ ] Structured outputs
  - [ ] Fallback usage
- [ ] Add convenience builders (optional):
  - [ ] `.user("...")`, `.system("...")`
- [ ] Add migration notes and known limitations

**Exit criteria**
- A new user can run examples in minutes.

---

## Phase 9 — Release Management

- [ ] Add CI workflow (build + test)
- [ ] Add lint/format tooling (optional SwiftLint/SwiftFormat)
- [ ] Tag first release (`v0.1.0` suggested)
- [ ] Maintain `CHANGELOG.md`
- [ ] Define versioning and compatibility policy

**Exit criteria**
- First consumable package release published.

---

## Phase 10 — Go Parity Gap Closure

Source reference: `https://github.com/revrost/go-openrouter`

### Parity Snapshot vs Go SDK (feature list)

- [x] Chat Completion
- [x] Completion
- [x] Streaming *(needs reliability upgrade to true incremental streaming path)*
- [x] Embeddings
- [ ] Reasoning
- [x] Tool calling
- [x] Structured outputs
- [ ] Prompt caching
- [ ] Response caching
- [ ] Web search
- [~] Multimodal [Images, PDFs, Audio] *(base support in place; tighten payload parity + fixtures)*
- [x] Usage fields

- [ ] Reasoning support parity:
  - [ ] Add request reasoning options in `ChatCompletionRequest`
  - [ ] Add response/chunk reasoning fields where returned
  - [ ] Add model round-trip tests for reasoning fields
- [ ] Prompt caching parity:
  - [ ] Add prompt-caching request fields
  - [ ] Verify field names/shape against OpenRouter docs
  - [ ] Add encode/decode tests
- [ ] Response caching parity:
  - [ ] Add `ResponseCacheConfig` on supported requests
  - [ ] Map cache config to transport headers (enable/ttl/clear)
  - [ ] Parse cache metadata from response headers
  - [ ] Expose cache metadata for streaming responses
  - [ ] Add unit tests for header emission + metadata parsing
- [ ] Web search parity:
  - [ ] Add web-search request options to chat request models
  - [ ] Add typed response fields for search-related annotations (if present)
  - [ ] Add request/response tests
- [ ] Multimodal tightening parity:
  - [ ] Validate image/pdf/audio payload object shapes
  - [ ] Add multimodal fixture tests (image/pdf/audio variants)
  - [ ] Document accepted multimodal formats in README
- [ ] Streaming reliability upgrade:
  - [ ] Replace buffered stream read with true incremental streaming where available
  - [ ] Keep SSE parser `[DONE]` behavior consistent
  - [ ] Add tests for incremental chunk delivery behavior

**Exit criteria**
- Feature parity checklist aligns with Go SDK claims for:
  - Chat completion, completion, streaming, embeddings
  - reasoning, tool calling, structured outputs
  - prompt caching, response caching, web search
  - multimodal input and usage fields

---

## Milestones

- [ ] **M1**: Package + non-streaming chat working end-to-end
- [ ] **M2**: Streaming + fallback policy complete
- [ ] **M3**: Embeddings/tools/structured outputs + docs/tests
- [ ] **M4**: CI green + first release tag
- [ ] **M5**: Reasoning/caching/web-search parity complete

---

## Risks & Mitigations

- [ ] SSE edge-case parsing issues → build fixture-based parser tests early
- [ ] API schema drift vs OpenRouter docs → periodic parity audit
- [ ] Overly rigid models for polymorphic payloads → controlled custom decoders
- [ ] iOS networking/cancellation quirks → explicit cancellation tests

---

## Session Tracking

### Current focus
- [x] Set current task at session start

### Activity log
- [x] Initial plan drafted and committed to `PLAN.md`
- [x] Add dated updates per session

### 2026-05-03
- Completed:
  - Added Phase 0 framing artifacts: `FEATURE_PARITY.md`, `COMPATIBILITY.md`.
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
