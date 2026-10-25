---
type: Guide
title: Resource examples
description: Access generation metadata, discovery, workspaces, keys, activity, and reranking.
tags: [resources, models, workspaces, keys, authentication, rerank]
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
in this response does not provide APIs to change them. Workspace mutations,
membership operations, and budget APIs remain unimplemented. These operations
surface authentication/permission failures through the normal typed API errors;
retrieving an unknown workspace can return HTTP 404.

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
