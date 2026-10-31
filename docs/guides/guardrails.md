---
type: Guide
title: Guardrails
description: Manage guardrail policies and explicit API-key or member assignments using management credentials.
tags: [guardrails, management, policies, assignments]
sources:
  - resource: https://openrouter.ai/openapi.json
    title: OpenRouter OpenAPI specification
  - resource: ../../Sources/OpenRouter/Public/Guardrail.swift
    title: Guardrail models
---

# Guardrails

Use a [configured client](../getting-started/quick-start.md) with a **management
API key**, in an async context. Guardrail CRUD, assignment listing, and bulk
assignment/removal all require management authorization. These are server-side
policies, not local content validation performed by the SDK.

## Read policies

```swift
let page = try await client.guardrails.list(offset: 0, limit: 25)
let totalGuardrails = page.totalCount
if let id = page.data.first?.id {
  let guardrail = try await client.guardrails.get(id: id)
  let name = guardrail.data.name
}
```

List also accepts `workspaceID`. Omitted workspace selects the default workspace.
Pagination is manual: omitted offset/limit use server defaults 0/50; the server
validates offset >= 0 and limit 1–100. `totalCount` describes all matches, not just
the current page. Identifier inputs are strings, escaped as single path segments;
the server validates UUIDs.

Returned `workspaceID == nil` denotes a legacy unscoped guardrail, **not** the
default workspace or a policy automatically applied across all workspaces.

## Create and update policies

Changes can affect request eligibility and budgets. Approve the policy before
running these examples:

```swift
let created = try await client.guardrails.create(.init(name: "Production policy"))
let updated = try await client.guardrails.update(
  id: created.data.id,
  .init(allowedModels: .value(["openai/gpt-4o-mini"]), description: .null)
)
// Removes the guardrail; uncomment only after approving the change:
// let deleted = try await client.guardrails.delete(id: created.data.id)
```

Creating a guardrail only places it in a workspace. It enforces nothing for that
workspace's traffic until assigned to API keys or members. To constrain all
workspace traffic, configure the workspace's default guardrail. Omitted create
`workspaceID` uses the default workspace; if that workspace was deleted, supply
an explicit workspace UUID or the server returns HTTP 400.

Create requires `name` (1–200 characters). Optional nil create fields are omitted.
Nullable PATCH settings distinguish omission, explicit null, and assignment with
`GuardrailField.unchanged`, `.null`, and `.value(...)`. Nonnullable update fields
such as name and `includeBYOKInBudgets` use ordinary optionals: nil omits rather
than clears. Provider and model restrictions, budget fields, content filters,
data-region restrictions, and privacy/training settings follow the server schema.

Important server contracts:

- On creation, supply `limitUSD` and `resetInterval` together; setting only one
  returns HTTP 400. Known reset intervals are `daily`, `weekly`, and `monthly`.
- `includeBYOKInBudgets` controls whether BYOK spend counts toward this guardrail's
  budget. Creation defaults to false; omit it on PATCH to leave it unchanged.
- Model inputs accept slugs or canonical slugs; returned model lists contain
  canonical identifiers. Non-null model/provider restriction arrays must be
  nonempty; clear a restriction with null instead of an empty array.
- `allowedDataRegions` controls **ingress** through `global`, `europe`, or `us`.
  Null leaves it unrestricted; an empty array is rejected. Applicable guardrails'
  region restrictions intersect. This is distinct from a BYOK processing-region
  declaration.
- Provider-specific ZDR flags include Anthropic, OpenAI, Google, xAI, and other
  providers. Legacy `enforceZDR` is deprecated upstream: it supplies values for
  per-provider fields not explicitly provided. Safety-retention settings can
  only make the account policy more restrictive.
- Publication/training flags affect free/paid endpoint eligibility.
  First-party-harness enforcement filters model listings for named coding
  harnesses; it does not prohibit routing to a directly named model.

## Content filters

Custom filters carry a regex `pattern`, an `action`, and an optional label.
Builtin filters carry a `slug` and an `action`; returned labels are system-assigned.
A caller-supplied builtin label is deprecated and ignored by the server.
Known actions are `block`, `redact`, and detect-only `flag`.

Builtin `scanScope` supports `user_only` and `all_messages` (default), and applies
only to `regex-prompt-injection`. Custom regex entries have no scan-scope field.
The SDK transports filter configuration; it does not execute regexes, detect PII,
or guarantee that a policy satisfies an application's security requirements.

## Assignments and operational limits

```swift
let allKeyAssignments = try await client.guardrails.listKeyAssignments(limit: 25)
if let id = page.data.first?.id {
  let scopedKeys = try await client.guardrails.listKeyAssignments(id: id, limit: 25)
  let scopedMembers = try await client.guardrails.listMemberAssignments(id: id, limit: 25)
  // After selecting real account IDs and approving enforcement changes:
  // let assigned = try await client.guardrails.bulkAssignMembersToGuardrail(
  //   id: id, .init(memberUserIDs: ["user_approved"])
  // )
}
```

Omit `id` for global key/member assignment lists and supply it for a single
guardrail. Bulk methods are `bulkAssignKeysToGuardrail`,
`bulkUnassignKeysFromGuardrail`, `bulkAssignMembersToGuardrail`, and
`bulkUnassignMembersFromGuardrail`. Key request models use `keyHashes`; member
request models use `memberUserIDs`. Flat aliases retain the CRUD names
`listGuardrails`, `createGuardrail`, `getGuardrail`, `updateGuardrail`, and
`deleteGuardrail`; scoped list aliases are `listGuardrailKeyAssignments` and
`listGuardrailMemberAssignments`, global aliases are `listKeyAssignments` and
`listMemberAssignments`, and bulk aliases match their resource method names.

Both global and per-guardrail key/member assignment listings support offset/limit
pagination and return `data` plus `totalCount`. Key assignments identify key hashes,
names, and labels, not plaintext API keys. Member assignments identify user and
organization IDs. Both expose a nullable assigning-user ID and creation timestamp.

Bulk assignment/removal targets a single guardrail and requires **1–500 nonempty
key hashes or member user IDs** per request. Assign returns `assignedCount`; remove
returns `unassignedCount`. The schema does not promise deduplication or define
already-absent assignment behavior. Bounds and policy combinations are validated
by the server, not preflighted by the SDK.

All methods accept per-request `RequestOptions`. Authentication, permission,
validation, missing-resource, conflict, and server failures use normal typed API
errors. Deletion requires a `deleted: true` confirmation. Mutations and assignment
changes are never automatic; retries default to disabled. Do not blindly retry an
ambiguous mutation failure. Validation uses offline fixtures, not live policy
changes or verified account entitlements.

See [endpoint coverage](../reference/endpoint-coverage.md) for all 13 operations
and [the parity plan](../../PLAN.md) for remaining cross-language field gaps.
