# Changelog

All notable changes to this package will be documented in this file.

This project follows semantic versioning once public releases are tagged.

## Unreleased

- Added on-demand async member pagination via `workspaces.members` and `organization.members`, with independent iterators, cancellation checks, and terminal error propagation. Existing page methods remain available.

## 0.6.0 - 2026-10-29

### Added

- Native image SSE via `images.stream` and `createImageStream`, with typed raw-preserving events, provider errors, strict completion validation, cancellation, and buffered JSON fallback.
- Workspace create/update/delete and bulk member add/remove, with nullable settings and explicit default-workspace deletion confirmation.
- Organization member listing with typed profiles and offset/limit pagination.
- Workspace budget list/get/upsert/delete with typed intervals and optional workspace-wide BYOK configuration.
- Workspace member listing via `workspaces.listMembers` and `listWorkspaceMembers`, reusing typed workspace memberships with offset/limit pagination and total count.

### Compatibility and operational notes

- No source-breaking changes to existing public declarations were identified in the v0.5.0-to-v0.6.0 source review. Existing signatures and enum cases remain unchanged; this is not an ABI guarantee.
- Existing buffered image APIs retain their behavior. Native image SSE requires a valid completion and `[DONE]`; non-streaming providers yield a buffered synthetic event. Partial images are not concatenated or mapped to final-image identities. Cancellation does not guarantee that billing stops.
- Workspace, organization member, and budget operations require management keys. Pagination is manual. Default workspace member listing includes all organization members through implicit membership.
- Workspace updates distinguish omitted, null, and assigned settings with `WorkspaceField`. Workspace deletion is irreversible; default-workspace deletion requires explicit opt-in and disables unscoped inference keys. Active workspace keys and SCIM policies can restrict membership changes or deletion.
- Budget changes enforce immediately. Limits must satisfy the server's interval hierarchy; the BYOK setting applies workspace-wide. Deleting a budget removes only that interval and preserves the BYOK setting.
- Validation used offline tests; no paid generation or destructive live management calls were performed for this release.

### Documentation

- Added image streaming, workspace management, organization/member listing, and budget examples and limitations; endpoint coverage now records 57 of the 139 operations in the audited specification.

## 0.5.0 - 2026-10-28

### Added

- Read-only workspace list/get with typed settings, offset/limit pagination, and UUID-or-slug lookup.
- File listing, metadata retrieval, and buffered content downloads with native/OpenAI/Anthropic response shapes, pagination fields, and workspace/provider filters.
- Explicit irreversible file deletion with validated confirmation markers; unknown response shapes do not report confirmed success.
- Batch submission, listing, retrieval, and terminal artifact deletion, with inline requests, repeated status filters, raw endpoint-specific results, and separate OpenRouter/upstream cleanup outcomes.
- Image-model and provider-endpoint discovery with typed architecture/pricing fields and dynamic capability descriptors.
- Non-streaming image generation via `images.create` and `createImage`, with image references, provider options, base64 outputs, typed usage, and preserved raw payloads.

### Compatibility and operational notes

- No source-breaking changes to existing public declarations were identified in the v0.4.0-to-v0.5.0 review. Existing method signatures and enum cases are unchanged; this is not an ABI guarantee.
- Existing file uploads still return `FileMetadata`; provider-backed uploads remain unimplemented. Retrieval supports provider-shaped responses without changing upload behavior.
- Raw-backed response envelopes encode their authoritative `rawPayload`; changing typed snapshot properties alone does not rewrite that JSON.
- Batch creation submits real work and can incur charges. Submission uses ordered metadata before inline requests; HTTP 202 means accepted for asynchronous validation, not completed.
- File deletion is irreversible. Batch deletion purges terminal request/result artifacts, not running jobs or billing/audit records; upstream deletion may be unsupported. Neither runs automatically.
- Image generation always sends `stream: false` and buffers base64 output. Native image SSE remains unsupported; the SDK does not render, save, or download images automatically.
- Retries default to disabled. There is no automatic batch polling, cancellation, or webhook receiver. Paid generation/submission and real deletion were not used during testing.

### Documentation

- Reconciled the endpoint tracker with the official OpenAPI inventory and documented method-aware coverage, legacy compatibility, provider shapes, billing/retention limits, and new resource examples.

## 0.4.0 - 2026-10-25

### Added

- Unauthenticated authorization-code exchange with optional PKCE via `auth.keys.exchange` and `exchangeAuthCodeForAPIKey`, credential-redacted models, and keyless client initialization for exchange.
- `TypedChatTool` for typed chat function arguments and JSON tool results, with explicit schemas and application-controlled execution.
- Typed streaming tool-call deltas and a manual `ChatToolCallAccumulator`, with per-choice assembly and rejection of incomplete, conflicting, or duplicate-ID calls before typed decoding.
- `Content.null` to decode and replay chat messages with explicit null content; missing content remains rejected.

### Fixed

- Reject exchange before sending when an injected session has a session-level Authorization header; debug logging tests cover credential-free success and error events.
- Document cancellation checks before streamed tool-call finalization and retain tool schemas in follow-up request examples.

### Compatibility and limitations

- Exhaustive switches over `Content` must handle `.null`; exhaustive switches over `OpenRouterError` must handle `.unauthenticatedSessionRequired`.
- Existing `Delta(role:content:)` calls remain valid, but two-argument initializer references must use an explicit closure because the initializer now also accepts `toolCalls`; see the versioning guide for migration.
- Exchange needs a session without Authorization in `httpAdditionalHeaders`; configuring a client API key does not send that key with exchange.
- Streaming assembly is explicit and buffers arguments. Finalize only after normal stream exhaustion and an explicit cancellation check; the accumulator does not observe SSE `[DONE]` or execute tools.
- Responses API behavior remains beta. Pagination helpers and deferred administrative namespaces remain out of scope.

### Documentation

- Reorganized SDK guides and endpoint coverage into an OKF v0.2 documentation bundle, with typed-tool and streaming round-trip examples.

## 0.3.0 - 2026-08-13

- Added model detail, model count, and user-filtered model discovery APIs.
- Added file uploads with optional workspace targeting.
- Added user activity analytics and daily model-ranking datasets.
- Added current-key metadata and complete management API-key CRUD support.
- Added authorization-code creation with optional PKCE and redacted credential descriptions.
- Added reusable typed PATCH and DELETE transport support with safe dynamic path escaping.
- Improved request-body handling and cross-platform macOS/Linux test coverage.

## 0.2.0 - 2026-07-27

- Added Anthropic-compatible Messages creation and SSE streaming APIs.
- Expanded the beta Responses API with typed/raw events, function tools, stateless function-call/output replay, and reasoning replay support.
- Added reranking and embedding-model discovery APIs.
- Added audio speech synthesis and multipart audio transcription APIs.
- Added the complete video workflow: job creation, polling, buffered content download with Content-Type, and video-model capability discovery.

## 0.1.0-rc.1

- Initial release candidate for core OpenRouter Swift SDK functionality.
- Includes chat completions, streaming chat, embeddings, completions, generations, models, credits, providers, and endpoints.
- Includes reasoning, tool calling, structured output, prompt caching, response caching, web search, multimodal content, usage/cost fields, fallback routing, retries, request options, and typed API error mapping.
- Excludes beta Responses API pending compatibility confirmation.
