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
- The [streaming](../guides/streaming.md) SSE parser supports multiline frames.
  Image streams retain optional event names; SSE IDs/retry metadata do not
  provide automatic reconnection or resumable generation.
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
- [Image generation](../guides/media.md#streaming-image-generation) supports buffered
  JSON and native SSE. Non-streaming providers return a buffered synthetic event.
  Native SSE requires a valid completion and `[DONE]`; partial images are not
  concatenated or mapped to final-image identities. There is no automatic output
  rendering, saving, download, or resubmission. Cancellation is not a billing
  guarantee; consumers must check task cancellation after iteration.
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
