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
- Workspace list/get/create/update/delete and bulk member add/remove are implemented;
  workspace member listing, organization APIs other than member listing,
  guardrails, other beta namespaces, and some analytics
  capabilities are not yet implemented. Activity and daily-ranking endpoints are implemented; consult
  [endpoint coverage](endpoint-coverage.md) for the precise inventory.
- Organization member listing requires a management key and supports only manual
  offset/limit pagination, without filters. The server validates offset >= 0 and
  limit 1–100; omitted values use defaults 0 and 50. Names are optional and roles
  remain extensible strings (currently `org:admin` and `org:member`). Organization
  settings and other organization operations remain deferred.
- Workspace operations require management keys. The server validates names (1–100
  characters), slugs (1–50 lowercase alphanumeric characters separated by single
  hyphens), descriptions (up to 500 characters), sampling rates (0.0001–1), supported
  disabled server tools, and member batches (1–100 user IDs). Members inherit their
  organization roles. Active workspace API keys block workspace deletion and member
  removal; SCIM-managed membership changes belong in the identity provider.
  Deletion permanently removes budgets and guardrails and disables classifiers and
  broadcast destinations. `confirmDefaultWorkspaceDeletion: true` explicitly opts
  into deleting the default workspace and permanently disabling unscoped inference
  keys; management and provisioning keys remain. The confirmation query is omitted
  by default. Nullable request settings use `WorkspaceField`: `.unchanged` omits,
  `.null` clears, and `.value(...)` assigns. Create settings are flattened into the
  request body. Budget configuration uses separate list/get/upsert/delete APIs.
- Workspace budgets require management keys. The server validates positive USD
  limits and strict hierarchy lifetime > monthly > weekly > daily; enforcement
  changes immediately. Lifetime budgets return a null reset interval. The optional
  BYOK flag applies workspace-wide across all intervals; omitting it on upsert
  leaves the setting unchanged. Deletion removes only the selected interval and
  succeeds even if absent; it does not reset BYOK settings. See the
  [budget examples and contracts](../guides/resources.md#workspace-budgets).
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
