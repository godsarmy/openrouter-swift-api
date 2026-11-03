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
- Workspace list/get/create/update/delete and member list/add/remove, organization
  member listing, and organization settings are implemented. Other beta namespaces
  and some analytics capabilities remain unimplemented. Activity and daily-ranking
  endpoints are implemented; consult
  [endpoint coverage](endpoint-coverage.md) for the precise inventory.
- Organization member listing requires a management key and supports manual or async
  offset/limit pagination, without filters. The server validates offset >= 0 and
  limit 1–100; omitted values use defaults 0 and 50. Names are optional and roles
  remain extensible strings (currently `org:admin` and `org:member`).
- [Organization settings](../guides/resources.md#organization-settings) require a
  management key associated with the organization. The only reviewed writable
  field is the required, nonnullable filtered-dashboard-catalog Boolean. It does
  not change inference eligibility or authenticated `/models` filtering; account
  availability and dashboard effects were not live-verified.
- Workspace member listing requires a management key and supports manual or async offset/limit
  pagination (defaults 0/50, limit 1–100). Default workspaces return all organization
  members through implicit membership. Responses contain workspace membership IDs,
  user IDs, roles, and creation timestamps rather than organization profile fields.
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
- [BYOK credentials](../guides/resources.md#byok-provider-credentials) require
  management keys. Raw provider secrets are write-only; response labels are
  masked. Updates support explicit null clearing, but create nil values are
  omitted. Policy bounds/combinations and UUID inputs are server-validated.
  Region/ZDR declarations are self-reported, not verified privacy guarantees.
  Deletion wipes secret material; ambiguous mutations must not be blindly retried.
- [Guardrails](../guides/guardrails.md) require management keys. Creating a
  guardrail in a workspace does not assign it or enforce it on workspace traffic.
  Nullable PATCH settings support omission/null/value; create nil settings omit.
  Listing is manually paginated; bulk operations accept 1–500 nonempty IDs/hashes.
  UUIDs, policy bounds, and combinations are server-validated. The SDK transports
  content filters and privacy policies; it does not execute filters locally or
  guarantee application security. Mutation retries require caller care.
- [Observability destinations](../guides/observability.md) require management keys
  and can forward data to external systems. Provider configs are extensible objects,
  not fully typed provider-specific schemas. Response credentials are not guaranteed
  to be omitted or masked. Debug descriptions are redacted, but explicit JSON
  encoding and extracted configs/filters can expose sensitive values. Listing is
  manually paginated; bounds/configs are server-validated. Deletion is soft deletion
  and does not erase data already forwarded to an external provider.
- [Preset POSTs](../guides/presets.md) create configuration or new versions, not
  inference. The server persists only overlapping config fields and ignores
  non-config inputs; the SDK does not rewrite submitted bodies. Typed writes
  inherit existing request-model field coverage; direct JSON-object overloads
  support additional fields. Listing is manually paginated and versions may be
  null per the schema. Repeating ambiguous writes may create additional versions.
- [External users](../guides/external-users.md) are caller-supplied tracking-ID
  registrations, not login accounts or credentials. DELETE soft-deactivates and
  returns no content; it does not erase identity or block inference. PATCH can
  reactivate; create conflicts even for an already-registered inactive ID. IDs
  `.`/`..` cannot be addressed by path and are rejected locally there; use a list
  filter for lookup. Other identifier/pagination bounds are server-validated.
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
Workspace and organization members support [async member pagination](../guides/resources.md#member-pagination).
It buffers one page and is not a snapshot; changing membership may cause duplicates
or omissions. Helpers for other resources remain deferred; individual supported
pagination parameters are documented in the endpoint tracker.

The project-level roadmap remains in the [repository README](../../README.md).
