---
type: Reference
title: Versioning
description: Understand source compatibility and release policy.
tags: [versioning, compatibility, releases]
---

# Versioning

Before `1.0`, minor versions may add APIs and patch versions are reserved for
compatible fixes. After `1.0`, the package follows semantic versioning: breaking
source changes require a major version, additive APIs use minor versions, and
bug fixes use patch versions.

## API review notes for v0.6.0

The [changelog](../../CHANGELOG.md) collects v0.6.0's native image streaming,
workspace management and member listing, organization member listing, and budgets.
The source diff from v0.5.0 identified no removed public declarations, changed
existing public signatures, or new cases in existing public enums. This is a
source-diff compatibility conclusion, not an ABI guarantee or live API certification.

Operational considerations:

- Existing buffered image generation remains unchanged. `images.stream` requests
  native SSE and accepts buffered JSON fallback. Native streams require a valid
  completion and `[DONE]`. Partial images remain independent opaque snapshots;
  cancellation does not guarantee that provider billing stops.
- Management operations require management keys. Workspace/member pagination is
  explicit; default workspaces include all organization members implicitly.
- `WorkspaceField` distinguishes omission, explicit null, and assigned values in
  workspace settings. Workspace deletion is irreversible, and deleting the default
  workspace requires explicit confirmation and disables unscoped inference keys.
  Active workspace keys and SCIM policies can restrict management operations.
- Budget enforcement changes immediately. Limits must follow the server's interval
  hierarchy. BYOK settings apply workspace-wide; deleting an interval preserves
  those settings.
- Validation uses offline tests. Paid generation and destructive live management
  operations were not performed for this release.

See [limitations](../reference/limitations.md), [resources](../guides/resources.md),
and [image streaming](../guides/media.md#streaming-image-generation) for contracts
and examples. Historical exclusions below apply to their named release only.

## API review notes for v0.5.0

The [changelog](../../CHANGELOG.md) collects v0.5.0's workspace discovery, file
retrieval/deletion, batch processing, and image discovery/generation. These notes
describe its source-compatibility and operational boundaries.

The reviewed source diff from v0.4.0 identified no source-breaking changes to
existing public declarations. Existing client initializers/methods and upload
signatures remain unchanged, and existing public enums gain no cases. This is a
source-diff compatibility conclusion, not an ABI guarantee or a live-provider
certification.

Operational considerations:

- Existing `files.upload` still returns `FileMetadata`. New file retrieval
  methods return the separate provider-aware `FileResponse`; inspect its case,
  including `.unknown`, rather than assuming every provider uses native fields.
- Raw-backed response envelopes are snapshots. Encoding uses `rawPayload`;
  typed property mutations alone do not rewrite it. See the relevant
  [resource examples](../guides/resources.md).
- Batch submission uses inline request objects, not an uploaded input file.
  `createBatch` handles metadata ordering; HTTP 202 is acceptance, not completion.
  Inspect batch status and per-request results, including payment/retention errors.
- Deletion methods are explicit and irreversible. Batch artifact purging is not
  cancellation and does not erase billing/audit records. Inspect per-target
  outcomes rather than treating HTTP 200 as universal provider deletion.
- Image generation is buffered JSON only. The request always sends `stream: false`;
  decoding `stream: true` into `ImageGenerationRequest` is rejected. Output is
  base64 data, not a URL. Native image SSE remains deferred.
- Generation/submission can incur charges. Retries are disabled by default;
  automatic polling, webhook handling, and cancellation are not provided.

Consult [limitations](../reference/limitations.md),
[batch processing](../guides/batches.md), and [Media APIs](../guides/media.md)
before using new operations. Endpoint coverage is not a claim of full field parity
with every evolving upstream schema.

## API review notes for v0.4.0

The [changelog](../../CHANGELOG.md) collects v0.4.0's
authorization-code exchange, typed chat tools, null content, and streamed tool-call
assembly. These notes describe its source-compatibility and operational boundaries.

Migration considerations:

- Add `.null` to exhaustive switches over `Content`. It preserves explicit JSON
  null; omitted chat content is still rejected.
- Add `.unauthenticatedSessionRequired` to exhaustive switches over
  `OpenRouterError`. For exchange, create an injected session without an
  Authorization entry in `httpAdditionalHeaders`.
- Existing `OpenRouterClient(apiKey:...)` and `Delta(role:content:)` calls remain
  valid. References to the old two-argument `Delta` initializer must instead use
  an explicit closure, since its signature now includes `toolCalls`:

  ```swift
  let makeDelta: (ChatMessage.Role?, String?) -> ChatCompletionChunk.Delta = {
    ChatCompletionChunk.Delta(role: $0, content: $1)
  }
  ```

- Raw chat/tool APIs remain available. Typed helpers do not generate schemas,
  authorize inputs, execute tools, or run a loop.
- When collecting streamed calls, consume the stream, call
  `Task.checkCancellation()`, then finalize. The finish reason is a completion
  gate, not proof that SSE `[DONE]` arrived. See [streaming](../guides/streaming.md).

## API review notes from v0.2.0

- Current public APIs are expected to remain source-compatible through `0.x` where practical.
- Flat client methods remain available alongside resource namespaces for compatibility.
- `JSONValue` remains the escape hatch for raw/forward-compatible payloads.
- Broader beta/resource coverage remains intentionally incremental.

Package releases are recorded in the [changelog](../../CHANGELOG.md).
Documentation updates are recorded separately in the [bundle log](../log.md).
Consult [endpoint coverage](../reference/endpoint-coverage.md) and
[limitations](../reference/limitations.md) for the current feature status rather
than treating historical release exclusions as current limitations.
