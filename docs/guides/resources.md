---
type: Guide
title: Resource examples
description: Access generation metadata, discovery, files, workspaces, organization members, keys, activity, and reranking.
tags: [resources, models, files, workspaces, organization, keys, authentication, rerank]
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
create/update/delete and bulk member add/remove are supported; workspace member
listing and budget APIs remain deferred. See [limitations](../reference/limitations.md)
for nullable request settings and destructive deletion restrictions. These operations
surface authentication/permission failures through the normal typed API errors;
retrieving an unknown workspace can return HTTP 404.

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
page; pagination is manual. `OrganizationMember` exposes `id`, optional
`firstName`/`lastName`, `email`, and an extensible `role` string (currently
`org:admin` or `org:member`). Names that are null or absent decode as nil.
Authentication and permission failures use normal typed API errors. Organization
settings and other organization endpoints remain deferred.

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
