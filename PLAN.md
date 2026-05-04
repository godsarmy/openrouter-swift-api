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

- [ ] Define `OpenRouterClient` initializer/config:
  - [ ] `apiKey`
  - [ ] optional `baseURL`
  - [ ] optional `httpReferer`
  - [ ] optional `xTitle`
  - [ ] timeout/session injection
- [ ] Define primary methods:
  - [ ] `createChatCompletion(_:) async throws -> ChatCompletionResponse`
  - [ ] `createChatCompletionStream(_:) -> AsyncThrowingStream<ChatCompletionChunk, Error>`
  - [ ] `createEmbeddings(_:) async throws -> EmbeddingResponse`
  - [ ] `createCompletion(_:) async throws -> CompletionResponse` (if in scope)
- [ ] Define fallback APIs:
  - [ ] `createChatCompletionWithFallback(...)`
  - [ ] `createChatCompletionStreamWithFallback(...)`
  - [ ] `ChatCompletionFallbackPolicy`

**Exit criteria**
- Public signatures stabilized for v1.

---

## Phase 3 — Models & Serialization

- [ ] Implement Codable request/response models:
  - [ ] Chat completion request/response
  - [ ] Message roles and content parts
  - [ ] Tool/function calling schema types
  - [ ] Structured output / response_format JSON schema
  - [ ] Embedding request/response
  - [ ] Completion request/response (if in scope)
  - [ ] Usage/token accounting fields
- [ ] Support multimodal content:
  - [ ] text
  - [ ] image
  - [ ] pdf
  - [ ] audio
- [ ] Add robust decoding for polymorphic fields

**Exit criteria**
- Model round-trip encode/decode tests passing.

---

## Phase 4 — Transport Layer

- [ ] Build request factory (method/path/headers/body)
- [ ] Inject auth (`Authorization: Bearer ...`)
- [ ] Inject optional OpenRouter headers (`HTTP-Referer`, `X-Title`)
- [ ] Implement JSON response decoding and error decoding
- [ ] Map HTTP + API errors to Swift error enum

**Exit criteria**
- Non-streaming endpoints function through a single shared transport.

---

## Phase 5 — Streaming (SSE)

- [ ] Implement SSE parser for `data:` frames
- [ ] Handle sentinel `[DONE]`
- [ ] Decode chunk payloads into `ChatCompletionChunk`
- [ ] Expose as `AsyncThrowingStream`
- [ ] Ensure cancellation/cleanup works correctly

**Exit criteria**
- Streamed chat completion stable under normal/error/cancel paths.

---

## Phase 6 — Fallback Policy & Reliability

- [ ] Add default fallbackable error codes:
  - [ ] 402, 408, 429, 500, 502, 503, 504, 524, 529
- [ ] Check both HTTP status and API error body code
- [ ] Implement model retry order semantics
- [ ] Ensure streaming fallback only occurs before stream establishment
- [ ] Add configurable policy override support

**Exit criteria**
- Fallback behavior matches documented Go client semantics.

---

## Phase 7 — Testing

- [ ] Unit tests:
  - [ ] Model encoding/decoding
  - [ ] Error mapping
  - [ ] Fallback policy decisions
  - [ ] SSE parser edge cases
- [ ] Transport tests with mocked `URLProtocol`
- [ ] Integration tests (opt-in via `OPENROUTER_API_KEY`):
  - [ ] Chat completion
  - [ ] Streaming chat completion
  - [ ] Embeddings
- [ ] Add deterministic fixtures for CI

**Exit criteria**
- Reliable CI passing without requiring live API for core suite.

---

## Phase 8 — Docs, Examples, Developer Experience

- [ ] Quick start in README
- [ ] Examples:
  - [ ] Basic chat
  - [ ] Streaming chat
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

## Milestones

- [ ] **M1**: Package + non-streaming chat working end-to-end
- [ ] **M2**: Streaming + fallback policy complete
- [ ] **M3**: Embeddings/tools/structured outputs + docs/tests
- [ ] **M4**: CI green + first release tag

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
- In progress:
  - Phase 2 public API design.
- Next:
  - Define client configuration and v1 public method signatures.

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
