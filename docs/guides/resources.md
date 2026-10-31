---
type: Guide
title: Resource examples
description: Access generation metadata, discovery, files, workspaces, organization members, keys, BYOK, activity, and reranking.
tags: [resources, models, files, workspaces, organization, keys, byok, authentication, rerank]
sources:
  - resource: https://openrouter.ai/docs/use-cases/oauth-pkce
    title: OpenRouter OAuth PKCE guide
  - resource: https://openrouter.ai/openapi.json
    title: OpenRouter OpenAPI specification
---

# Resource examples

These snippets assume a [configured client](../getting-started/quick-start.md)
and an async context. Check [endpoint coverage](../reference/endpoint-coverage.md)
for aliases, supported filters, and authentication requirements.

For asynchronous provider work, see [batch processing](batches.md). The batch API
uses inline requests; it is not an uploaded-file workflow.

For management-key policy CRUD and key/member assignments, see
[guardrails](guardrails.md).

## Generation metadata

```swift
let generation = try await client.getGeneration(id: "gen_123")
let generationContent = try await client.listGenerationContent(id: "gen_123")

// Raw fallback JSON helpers.
let generationRaw = try await client.getGenerationRaw(id: "gen_123")
let generationContentRaw = try await client.listGenerationContentRaw(id: "gen_123")
```

## Discovery, credits, and activity

```swift
let models = try await client.models.list()
let userModels = try await client.models.listUser(offset: 0, limit: 25)
let credits = try await client.credits.get()
let activity = try await client.activity.get(date: "2026-08-10", groupBy: "workspace")
let rankings = try await client.datasets.rankingsDaily(period: "week", modality: "text")
let providers = try await client.providers.list()
let endpoints = try await client.endpoints.list(author: "openai", slug: "gpt-4o-mini")
let zdrEndpoints = try await client.endpoints.listZDR()
```

Credits and activity require a management API key.

Dedicated image-model and provider-capability discovery is documented in
[Media APIs](media.md#image-model-discovery), separately from generic model discovery.

## BYOK provider credentials

Use a client configured with a **management API key**. Read operations return
masked metadata, never the provider's raw secret:

```swift
let credentials = try await client.byok.list(offset: 0, limit: 25, provider: "openai")
let totalCredentials = credentials.totalCount
if let id = credentials.data.first?.id {
  let credential = try await client.byok.get(id: id)
  let maskedLabel = credential.data.label
}
```

List also accepts `workspaceID`. Omitted workspace filters resolve to the account's
default workspace; if deleted, pass an explicit workspace UUID or the server
returns HTTP 400. List pagination is manual, with defaults 0/50 and server bounds
offset >= 0 and limit 1–100. Returned `workspaceID == nil` means a global credential,
not the default workspace. IDs/workspace inputs are strings; the server validates
UUIDs. IDs are escaped as single path segments.

Creation, updates, and deletion change provider routing or credentials. Run only
after approving the intended change. Load `providerAPIKey` securely before this
example; never commit it or print the encoded request:

```swift
let created = try await client.byok.create(
  .init(provider: "openai", key: providerAPIKey, name: "Production")
)
let updated = try await client.byok.update(
  id: created.data.id,
  .init(allowedModels: .value(["openai/gpt-4o-mini"]), name: .null)
)
// Explicitly approve secret removal before uncommenting:
// let deleted = try await client.byok.delete(id: created.data.id)
```

Flat aliases are `listBYOKKeys`, `createBYOKKey`, `getBYOKKey`, `updateBYOKKey`,
and `deleteBYOKKey`; resource and flat methods accept `RequestOptions`. Create
requires `provider` and a nonempty `key`, and optionally scopes to `workspaceID`.
PATCH may rotate `key`, but cannot change provider/workspace. Nullable settings
use `BYOKField`: `.unchanged` omits, `.null` clears, `.value(...)` assigns. Create
optionals omit nil values. Secret-bearing request descriptions and reflection
are redacted; JSON encoding intentionally contains the secret for transmission.

Policies include `allowedModels`, `allowedUserIDs`, `allowedAPIKeyHashes`,
`isRequired`, `isBYOKOnly`, `isFallback`, `disabled`, `declaredRegion`, and
`declaredZDR`. Null allowlists remove restrictions; supplied API-key hash lists
require 1–100 account-owned hashes. The server validates policy combinations:
`isBYOKOnly` cannot be combined with `isFallback`. `isRequired` removes shared
provider capacity for the credential's model scope; `isBYOKOnly` removes it for
every model on that provider. Region/ZDR declarations are self-reported, not
independent privacy guarantees; null clears the declaration/inherits policy.
OpenAI/Fireworks key rotation may re-derive the region from key material.

Deletion soft-deletes the credential and wipes its secret; success requires
`deleted: true`. No mutation happens automatically. Retries default to disabled;
do not blindly retry ambiguous creation, rotation, or deletion failures. Normal
typed API errors expose authentication, permission, validation, not-found, and
conflict failures. No live management mutation was used to validate this support.

## Workspace discovery

Use a client configured with a **management API key** to list or retrieve
workspaces. Both operations are read-only:

```swift
let workspaces = try await client.workspaces.list(offset: 0, limit: 25)
let totalWorkspaces = workspaces.totalCount
let workspace = try await client.workspaces.get(id: "production")
// `id` accepts a workspace UUID string or a slug, not a path.
let workspaceID = workspace.data.id
```

Flat aliases are `client.listWorkspaces(offset:limit:options:)` and
`client.getWorkspace(id:options:)`. Omit pagination parameters to use server
defaults (offset 0, limit 50). The API accepts a nonnegative offset and a limit
from 1 through 100. Parameters are passed through; the server validates bounds.
`totalCount` is the total available count, not the size of the current page;
pagination is manual.

`Workspace` exposes names, defaults, logging settings, timestamps, and optional
budget/tool settings. Nullable values remain optional; the presence of settings
in this response does not imply that all settings are configurable. Workspace
create/update/delete and member list/add/remove are supported; budget APIs are
supported separately below. See [limitations](../reference/limitations.md)
for nullable request settings and destructive deletion restrictions. These operations
surface authentication/permission failures through the normal typed API errors;
retrieving an unknown workspace can return HTTP 404.

## Workspace members

Use a management key to list memberships by workspace UUID or slug:

```swift
let members = try await client.workspaces.listMembers(id: "production", offset: 0, limit: 25)
for member in members.data {
  let userID = member.userID
  let role = member.role
}
let totalMembers = members.totalCount
```

The flat alias is `client.listWorkspaceMembers(id:offset:limit:options:)`.
For a single page, omitted offset/limit use server defaults 0/50; the server
validates offset >= 0 and limit 1–100. `totalCount` describes all memberships,
including when the requested page is empty. IDs and slugs are encoded as one
path segment. Default workspaces return all organization members through implicit
membership. Each `WorkspaceMembership` contains its membership ID, workspace ID,
user ID, extensible role string, and creation timestamp. Authentication,
permission, and missing-workspace failures use the normal typed API errors.
See [member pagination](#member-pagination) to iterate across pages.

## Workspace budgets

These operations require a **management API key**. `workspaceRef` accepts a UUID
or slug, encoded as a single path segment. Intervals are `.daily`, `.weekly`,
`.monthly`, and `.lifetime`:

```swift
let budgets = try await client.workspaces.listBudgets(workspaceRef: "production")
let monthly = try await client.workspaces.getBudget(
  workspaceRef: "production", interval: .monthly
)
// Changes enforcement immediately; run only after approving the limit.
let updated = try await client.workspaces.upsertBudget(
  workspaceRef: "production", interval: .monthly,
  .init(limitUSD: 100, includeBYOKInBudgets: false)
)
// Removes this interval only; uncomment after confirming the intended change.
// let deletion = try await client.workspaces.deleteBudget(
//   workspaceRef: "production", interval: .monthly
// )
```

Flat aliases are `listWorkspaceBudgets`, `getWorkspaceBudget`,
`upsertWorkspaceBudget`, and `deleteWorkspaceBudget`. All accept `RequestOptions`.
The server requires `limitUSD > 0` and strictly decreasing limits as intervals
narrow: lifetime > monthly > weekly > daily. Enforcement is immediate. Models
contain the budget ID, workspace ID, USD limit, reset interval, and creation/update
timestamps, not usage or currency fields. A null `resetInterval` means lifetime.

List/get/upsert responses may include `includeBYOKInBudgets`. Upsert accepts an
optional nonnullable boolean: omit it to leave the current setting unchanged;
`false` explicitly excludes BYOK spend. This flag is **workspace-wide**, not per
interval. Delete returns `deleted`, true even for an already absent interval;
other intervals and the workspace BYOK setting are unchanged.

Official contracts: [list](https://openrouter.ai/docs/api/api-reference/workspaces/list-workspace-budgets.md),
[get](https://openrouter.ai/docs/api/api-reference/workspaces/get-a-workspace-budget.md),
[upsert](https://openrouter.ai/docs/api/api-reference/workspaces/create-or-update-a-workspace-budget.md),
and [delete](https://openrouter.ai/docs/api/api-reference/workspaces/delete-a-workspace-budget.md).

## Organization members

Use a client configured with a **management API key**:

```swift
let members = try await client.organization.listMembers(offset: 0, limit: 25)
let totalMembers = members.totalCount
// After selecting and approving an organization member to add:
if let member = members.data.first {
  let result = try await client.workspaces.addMembers(
    id: "production", .init(userIDs: [member.id])
  )
}
```

The flat alias is `client.listOrganizationMembers(offset:limit:options:)`.
Both surfaces accept per-request options. Omit pagination for server defaults
(offset 0, limit 50); the server validates offset >= 0 and limit 1–100. No filters
are supported. `totalCount` is the total available count, including on an empty
page. For automatic iteration, see [member pagination](#member-pagination). `OrganizationMember` exposes `id`, optional
`firstName`/`lastName`, `email`, and an extensible `role` string (currently
`org:admin` or `org:member`). Names that are null or absent decode as nil.
Authentication and permission failures use normal typed API errors. Organization
settings and other organization endpoints remain deferred.

## Member pagination

Both member resources offer on-demand async sequences with management keys:

```swift
for try await member in client.workspaces.members(id: "production", limit: 25) {
  print(member.userID)
}
for try await member in client.organization.members(limit: 25) {
  print(member.email)
}
```

Both accept `offset` (default 0), `limit` (default 50), and per-request `options`.
The server validates offset >= 0 and limit 1–100. Existing `listMembers` methods
and flat aliases still return individual pages and their total counts.

`OffsetPaginatedSequence` fetches its first page on the first `next()` call and
buffers only the current page. Each iterator starts independently. No next page
is requested until the current page is consumed; breaking a loop starts no
background requests. Offsets advance by the number of members returned. A short
page continues if its total count indicates more members; an empty page or reaching
the reported total ends iteration. Errors terminate the iterator and propagate
to the caller without restarting pagination. Request-level retry policy still applies.

Cancellation is checked before requests, before yielding buffered members, and
after a request completes. In-flight requests use the existing transport's task
cancellation behavior. Offset pagination is not a snapshot: membership changes
between requests can cause duplicates or omissions. Helpers for other resources,
including cursor-based files and batches, remain deferred.

## File retrieval

Use an API key with access to the requested workspace and, when applicable, the
selected provider storage. These operations do not delete or modify files:

```swift
let filesPage = try await client.files.list(limit: 25, order: "asc")
if let fileID = filesPage.data.first?.id {
  let fileInfo = try await client.files.get(id: fileID)
  if case .openRouter(let file) = fileInfo, file.downloadable {
    let download = try await client.files.content(id: fileID)
    let bytes = download.data
    let contentType = download.contentType // May be absent.
    // Consume bytes without assuming UTF-8 text.
  }
}
if let nextCursor = filesPage.cursor {
  let nextPage = try await client.files.list(limit: 25, cursor: nextCursor, order: "asc")
  // Consume nextPage in your app; pagination is explicit.
}
```

Flat aliases are `listFiles`, `getFile`, and `downloadFileContent`. All accept
`RequestOptions`; each also accepts optional `workspaceID: UUID` and `provider`
filters. Omit `provider` for OpenRouter storage; provider-backed access uses your
configured provider credentials. This option selects storage, **not** response shape.

### Shapes and pagination

- Metadata is `FileResponse`: `.openRouter(FileMetadata)`,
  `.anthropic(FileMetadata)`, `.openAI(OpenAIFileMetadata)`, or `.unknown(JSONValue)`.
  `_shape` selects the response representation. Unknown string shapes retain raw
  JSON; malformed known shapes fail decoding rather than silently falling back.
- Untagged legacy payloads infer OpenAI from `object: "file"` or an integer
  `created_at`; otherwise they decode as native metadata. Untagged native and
  Anthropic payloads cannot be distinguished.
- `FileListResponse` retains `hasMore`, `firstID`, `lastID`, optional `cursor`,
  `shape`, `object`, and `rawPayload`. OpenRouter uses the opaque next-page cursor;
  provider shapes may instead use ID-based pagination. Do not assume `cursor`
  exists just because `hasMore` is true.
- List parameters include `limit` (1–1000), `cursor`, `after`, `afterID`,
  `beforeID`, and `order`. Parameters pass through unchanged. OpenRouter storage
  supports only ascending order and does not support `beforeID`.
- OpenAI metadata preserves integer `createdAt` and `bytes`; native metadata
  retains a timestamp string and `sizeBytes`. `purpose` and `status` are open strings.
- Raw-backed response models encode their `rawPayload`, matching existing
  `FileMetadata` behavior. Editing a typed property alone does not rewrite that
  payload. Known `FileResponse` cases emit the corresponding `_shape` on encoding.

**Content downloads buffer the entire file in memory.** The upstream contract
allows downloads only for server-created files; uploaded files return HTTP 400.
Treat `downloadable` as metadata, not a guarantee that a later request will succeed.
IDs are encoded as one path segment; the server validates the documented ID pattern
(`^[\w-]+$`, 1–256 characters). HTTP errors use normal `OpenRouterError.apiError`
handling. Existing `files.upload` still returns `FileMetadata` and does not expose
provider-backed uploads.

## File deletion

**Deletion is irreversible.** Verify the file identity, workspace, and provider,
and obtain explicit approval before calling `client.files.delete`. The SDK does
not prompt for confirmation or automatically delete files after download.

```swift
// Destructive: uncomment only after confirming the target file and storage scope.
// let deletion = try await client.files.delete(
//   id: "<confirmed-file-id>", options: .init(retries: RetryPolicy.none)
// )
```

The flat alias is `client.deleteFile(id:workspaceID:provider:options:)`.
Both forms accept optional `workspaceID: UUID`, `provider`, and `RequestOptions`,
using the same storage-scoping rules as retrieval. The `downloadable` flag limits
downloads, not deletion.

`FileDeleteResponse` distinguishes native, Anthropic, OpenAI, and unknown shapes.
Known responses require a native `type: "file_deleted"` or OpenAI
`object: "file", deleted: true` marker; malformed confirmations fail decoding.
Unknown shapes preserve raw JSON but have `isConfirmed == false`. Check the
returned `id` against the approved target before treating the response as its
confirmation. Untagged legacy native/OpenAI responses are also supported.

Retries are disabled by default. Do not automatically retry a destructive request
after a transport failure: the server may already have deleted the file even
though no confirmation reached the client. Inspect the result explicitly.

## Key management and authorization codes

Current-key metadata accepts an ordinary bearer key. Management operations and
authorization-code creation require a management key. **Creating/updating keys
changes account state. Deleting a key is permanent.**

```swift
let currentKey = try await client.keys.current()
let managedKeys = try await client.keys.list(includeDisabled: false, offset: 0)
let managedKey = try await client.keys.get(hash: "hash_example_metadata_only")
let disabledKey = try await client.keys.update(
  hash: "hash_example_metadata_only", .init(disabled: true)
)
// Destructive and permanent: only run after confirming the target key.
// let confirmation = try await client.keys.delete(hash: "hash_example_metadata_only")
let createdKey = try await client.keys.create(.init(name: "Service integration"))
// `createdKey.key` is returned once; store it securely without logging or printing it.
// Authorization codes require a management key. Prefer S256 PKCE; codes are short-lived and single-use.
let authCodeRequest = CreateAuthKeysCodeRequest(
  callbackURL: "https://example.com/openrouter/callback",
  codeChallenge: "base64url-sha256-challenge",
  codeChallengeMethod: "S256"
)
// Do not print or persist the returned authorization code.
// let authCode = try await client.auth.keys.createCode(authCodeRequest)
```

## Authorization-code exchange with PKCE

Exchange does **not** require a management key or any bearer key. Use
`OpenRouterClient()` before the user has connected their account. Exchange also
omits the Authorization header when a client API key or request-level extra
Authorization header is configured. If an injected `URLSession` has an
Authorization entry in its configuration's `httpAdditionalHeaders`, exchange
throws `OpenRouterError.unauthenticatedSessionRequired` before sending. Header
names are checked case-insensitively. Create a session without that entry for
exchange; changing the configuration after creating the session is insufficient.
Custom session delegates and protocols remain responsible for not adding credentials.

1. Generate a cryptographically random, per-attempt PKCE verifier (43–128
   URL-safe characters). Keep it private until exchange. Compute the S256
   challenge as base64url(SHA256(verifier)), without padding. The SDK does not
   generate these values or handle browser redirects.
2. Open `https://openrouter.ai/auth` with URL-encoded `callback_url`,
   `code_challenge`, `code_challenge_method=S256`, and an unpredictable `state`.
   Save the state locally and verify that the callback's state matches before
   accepting its `code`. Alternatively, a trusted backend can create a code
   using the management-key API above with the same challenge.
3. Exchange the code promptly using the **original verifier**, not the challenge:

```swift
let authClient = OpenRouterClient()
// Replace these placeholders with the validated callback code and saved verifier.
let exchanged = try await authClient.auth.keys.exchange(.init(
  code: "<code-from-callback>",
  codeVerifier: "<original-random-verifier>",
  codeChallengeMethod: "S256"
))
// Store exchanged.key securely (for example, in Keychain); never print it.
let userClient = OpenRouterClient(apiKey: exchanged.key)
```

The flat alias is `authClient.exchangeAuthCodeForAPIKey`. The response contains
`key` and optional `userID`. Codes are single-use and expire after approximately
10 minutes. Restart authorization if the code is expired or already consumed.
For codes created without PKCE, omit both optional PKCE fields; S256 is recommended.
The request/response descriptions redact codes, verifiers, and keys, but encoding
them to JSON still exposes their credentials. Do not log payloads.

Invalid parameters or challenge methods return HTTP 400; invalid/expired codes
or incorrect verifiers return HTTP 403, surfaced as `OpenRouterError.apiError`.
Exchange uses the normal request options; retries are disabled by default.
Avoid automatic retries because a code may have been consumed before a connection
failure. See [endpoint coverage](../reference/endpoint-coverage.md) for aliases.

## Reranking

```swift
let reranked = try await client.rerank.create(.init(
  model: "cohere/rerank-v3.5", query: "Swift concurrency",
  documents: [.text("Actors protect mutable state."), .object(.init(text: "Structured concurrency guide"))],
  topN: 2
))
```

For embeddings and legacy completions, see the [example CLI](../reference/example-cli.md).
