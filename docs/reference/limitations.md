---
type: Reference
title: Current limitations
description: Understand beta behavior, compatibility constraints, and unimplemented resources.
tags: [limitations, beta, roadmap, sse]
---

# Current limitations

- The [Responses API](../guides/responses.md) remains beta. SSE streaming has
  forward-compatible raw typed events, including text and function argument
  deltas; provider-specific beta fields may still require `rawPayload`.
- Workspace list/get discovery is implemented, but workspace mutations, membership,
  budgets, organization APIs, guardrails, other beta namespaces, and some analytics
  capabilities are not yet implemented. Activity and daily-ranking endpoints are implemented; consult
  [endpoint coverage](endpoint-coverage.md) for the precise inventory.
- The [streaming](../guides/streaming.md) SSE parser supports OpenRouter chat
  streams and basic multiline frame parsing helpers; broader SSE metadata is
  currently ignored by the streaming client.
- [Video content](../guides/media.md) and [file content](../guides/resources.md#file-retrieval)
  downloads buffer the entire file in memory. File downloads support server-created
  files only; uploaded files return HTTP 400. Provider-backed uploads are not
  implemented; the existing upload API remains unchanged. File deletion is
  supported but irreversible and never performed automatically.
- [Batch processing](../guides/batches.md) supports explicit create/list/get and
  terminal-job deletion. There is no automatic polling, webhook receiver, or job
  cancellation. Deletion purges artifacts, not billing/audit records, and upstream
  deletion may be unsupported. Result bodies and provider-specific usage remain
  JSON; payment and retention failures are API errors.
- [Image-model discovery](../guides/media.md#image-model-discovery) is implemented,
  but dedicated `POST /images` generation and its native SSE protocol are not.
  Streaming flags and pricing/capability maps describe upstream endpoints only.
- [Typed chat tools](../guides/tool-calling.md) handle complete calls. Streamed
  calls must first be finalized with the [manual accumulator](../guides/streaming.md#streaming-tool-calls),
  after normal stream exhaustion. It buffers arguments and does not itself
  observe SSE `[DONE]`. Schemas remain explicit; applications own validation
  and execution. Explicit `content: null` is supported as
  `Content.null`, but chat messages with an omitted `content` key are still rejected.
- Linux/WSL builds do not replace testing on Apple platforms.

## Deferred work

Track additional beta Responses fields as OpenRouter confirms them.
Pagination helpers remain deferred; individual supported pagination
parameters are documented in the endpoint tracker.

The project-level roadmap remains in the [repository README](../../README.md).
