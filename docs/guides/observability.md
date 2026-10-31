---
type: Guide
title: Observability destinations
description: Manage external telemetry destinations and forwarding policies with management credentials.
tags: [observability, management, telemetry, privacy]
sources:
  - resource: https://openrouter.ai/openapi.json
    title: OpenRouter OpenAPI specification
  - resource: ../../Sources/OpenRouter/Public/Observability.swift
    title: Destination and filter models
---

# Observability destinations

Use a [configured client](../getting-started/quick-start.md) with a **management
API key**, in an async context. These APIs configure external telemetry forwarding;
the SDK does not install a collector, receive webhooks, or send telemetry itself.

## List and retrieve

```swift
let destinations = try await client.observability.destinations.list(offset: 0, limit: 25)
let totalDestinations = destinations.totalCount
if let id = destinations.data.first?.id {
  let destination = try await client.observability.destinations.get(id: id)
  let destinationType = destination.data.type
}
```

List also accepts `workspaceID`. Omitted workspace selects the account's default
workspace. Only stable destination types are surfaced. Pagination is manual:
omitted offset/limit use server defaults 0/50; the server validates offset >= 0 and
limit 1–100. `totalCount` counts matches, not only the current page. IDs/workspace
inputs are strings; path IDs are escaped as single segments and UUID validity is
server-validated.

## Configure deliberately

Creating or enabling a destination can forward request data outside OpenRouter.
Approve the destination, data policy, and credential source before running:

```swift
let created = try await client.observability.destinations.create(
  .init(
    type: "webhook", name: "Production telemetry",
    config: ["url": .string("https://example.com/openrouter-events")],
    enabled: false, privacyMode: true
  )
)
// Explicitly clears both restrictions; do not run without reviewing broader forwarding:
// let updated = try await client.observability.destinations.update(
//   id: created.data.id, .init(apiKeyHashes: .null, filterRules: .null)
// )
// Soft-deletes the destination; uncomment only after approval:
// let deleted = try await client.observability.destinations.delete(id: created.data.id)
```

Create requires `type`, `name`, and a configuration object. This example explicitly
disables forwarding until reviewed. Server defaults otherwise enable the
destination, disable privacy mode and the four broadcast flags, and select
`["global"]` regions. A maximum of five destinations per type is allowed.

`type` is an extensible string. `config` is an object of `JSONValue` values, not a
closed provider-specific Swift union; unknown keys and destination type strings
are preserved. Provider-specific requirements are validated by the server.
The SDK models common destination fields and structured filters, not every
provider's config schema.

PATCH changes only supplied fields. It cannot change destination type or workspace.
`ObservabilityField.unchanged`, `.null`, and `.value(...)` distinguish omission,
clearing, and assignment for API-key hashes and filter rules. Other nil PATCH
fields are omitted; config and regions cannot be cleared with top-level null.
Send only the config keys you intend to update: masked values are ignored by the
server and unset config fields retain their current values. **Do not copy a
returned config into an update request automatically.**

## Secrets and forwarding controls

Treat request **and response** configs as sensitive. The specification contains
masked examples but does not guarantee that all returned credentials are omitted
or masked. Config-bearing model descriptions/debug reflection are redacted;
JSON encoding and direct `config` access intentionally retain actual values.
Do not print or persist encoded configs, extracted credentials, or filter values.
Redaction is not a guarantee against application-level logging of those values.

- `privacyMode` prevents forwarding request/response bodies, leaving metadata.
  Review metadata, destination access, and application privacy requirements too.
- `apiKeyHashes == nil` in a response means all keys. On create, nil omits the
  restriction; on PATCH, `.null` clears it. Supplied lists must be nonempty.
- `regions` select where requests are served for forwarding; known values are
  `global`, `europe`, and `us`. The server accepts `eu` as an alias for `europe`.
  Arrays must be nonempty; omit on PATCH to leave unchanged.
- `samplingRate` is server-validated in the documented range 0.0001–1.
- Broadcast flags independently include generation cost, cost allocation (beta),
  identity, and request-context metadata. Cost allocation is emitted only when it
  reconciles with billed cost.

## Structured filters

Filter config has required `groups` and an optional `enabled` flag (default true).
Each group has required `rules` and optional `logic` (`and`/`or`, default `and`).
Rules require `field` and `operator`; optional values are strings or numbers.
Fields include models, providers, session/user IDs, API-key names, finish reason,
input/output, costs, and token counts. Operators include equality, string/regex
matches, numeric comparisons, and existence checks. The SDK preserves extensible
field/operator strings; the server evaluates and validates the rules.

Filtering does not install an application-side privacy filter. Removing rules or
key restrictions may broaden the data forwarded to an external destination.

## Errors and aliases

Flat aliases are `listObservabilityDestinations`, `createObservabilityDestination`,
`getObservabilityDestination`, `updateObservabilityDestination`, and
`deleteObservabilityDestination`. All methods accept per-request `RequestOptions`.
Authentication, permission, invalid input, not-found, conflict, and server failures
use normal typed API errors. Creation returns HTTP 201; successful deletion
requires `deleted: true`. Deletion is soft deletion, not an SDK promise to erase
previously forwarded data from external systems.

Retries default to disabled. Do not blindly retry ambiguous creation, credential
updates, or deletion failures. No live destination changes were used for validation;
account access and actual telemetry delivery are not established by offline tests.
See [endpoint coverage](../reference/endpoint-coverage.md) and the
[parity plan](../../PLAN.md) for remaining scope.
