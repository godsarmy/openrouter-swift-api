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
- Broader resources such as organization/workspaces, guardrails, other beta
  namespaces, and some analytics capabilities are not yet implemented.
  Activity and daily-ranking endpoints are implemented; consult
  [endpoint coverage](endpoint-coverage.md) for the precise inventory.
- The [streaming](../guides/streaming.md) SSE parser supports OpenRouter chat
  streams and basic multiline frame parsing helpers; broader SSE metadata is
  currently ignored by the streaming client.
- [Video content](../guides/media.md) downloads buffer the entire file in memory.
- Linux/WSL builds do not replace testing on Apple platforms.

## Deferred work

Track additional beta Responses fields as OpenRouter confirms them. Consider a
higher-level Swift-friendly typed tool helper while keeping raw chat/tool APIs
canonical. Pagination helpers remain deferred; individual supported pagination
parameters are documented in the endpoint tracker.

The project-level roadmap remains in the [repository README](../../README.md).
